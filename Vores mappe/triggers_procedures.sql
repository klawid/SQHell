

-- Trigger kode for lager 
-- Ai was used in creation of this
DELIMITER $$

CREATE TRIGGER update_lager_after_transaktion
AFTER INSERT ON transaktion
FOR EACH ROW
BEGIN
    DECLARE kaffe_used INT;
    DECLARE mælk_used INT;
    DECLARE vand_used INT;

    -- Get ingredient usage from drink
	SELECT kaffe_forbrug_g, mælk_forbrug_ml, vand_forbrug_ml
    INTO kaffe_used, mælk_used, vand_used
    FROM drink
    WHERE drink_id = NEW.drink_id;

-- Tjek om der er nok kaffe på lageret
IF (SELECT mængde_kaffe FROM lager WHERE lager_id = NEW.lager_id) < kaffe_used THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Ikke nok kaffe på lager';
END IF;	

 -- Tjek om der er nok mælk
IF (SELECT mængde_mælk FROM lager WHERE lager_id = NEW.lager_id) < mælk_used THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Ikke nok mælk på lager';
END IF;

    -- Update lager (assuming only one row with id = 1)
    UPDATE lager
    SET 
        mængde_kaffe = mængde_kaffe - kaffe_used,
        mængde_mælk = mængde_mælk - mælk_used
    WHERE lager_id = NEW.lager_id;



END$$

DELIMITER ;


DELIMITER //

CREATE PROCEDURE køb_drink (
    IN p_medarbejder_id INT,
    IN p_drink_id INT,
    IN p_lager_id INT,
    IN p_indbetaling INT,
    IN p_betalingstype BOOL -- 0 = kort, 1 = kontant
)
BEGIN
    DECLARE v_pris INT;
    DECLARE v_byttepenge INT;

    -- hent pris
    SELECT pris INTO v_pris
    FROM drink
    WHERE drink_id = p_drink_id;

    -- 💳 KORT
    IF p_betalingstype = 0 THEN
        SET v_byttepenge = 0;
        SET p_indbetaling = 0;

    -- 💰 KONTANT
    ELSE
        IF p_indbetaling < v_pris THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ikke nok penge indbetalt';
        END IF;

        SET v_byttepenge = p_indbetaling - v_pris;

        -- 💡 HER kan du kalde din mønt-funktion
        CALL beregn_byttepenge(v_byttepenge, p_lager_id);
    END IF;

    -- indsæt transaktion
    INSERT INTO transaktion (
        transakion_id,
        medarbejder_id,
        drink_id,
        lager_id,
        kontant_indbetaling,
        betalingstype,
        byttepenge,
        dato,
        tidspunkt
    )
    VALUES (
        (SELECT IFNULL(MAX(transaktion_id)+1,1) FROM transaktion),
        p_medarbejder_id,
        p_drink_id,
        p_lager_id,
        p_indbetaling,
        p_betalingstype,
        v_byttepenge,
        CURRENT_DATE,
        CURRENT_TIME
    );

END //

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE beregn_byttepenge (
    IN  p_lager_id   INT,
    IN  p_byttepenge INT
)
BEGIN
    DECLARE rest INT DEFAULT p_byttepenge;
    DECLARE brug_200 INT DEFAULT 0;
    DECLARE brug_100 INT DEFAULT 0;
    DECLARE brug_50  INT DEFAULT 0;
    DECLARE brug_20  INT DEFAULT 0;
    DECLARE brug_10  INT DEFAULT 0;
    DECLARE brug_5   INT DEFAULT 0;
    DECLARE brug_2   INT DEFAULT 0;
    DECLARE brug_1   INT DEFAULT 0;

    DECLARE beh_200 INT;
    DECLARE beh_100 INT;
    DECLARE beh_50  INT;
    DECLARE beh_20  INT;
    DECLARE beh_10  INT;
    DECLARE beh_5   INT;
    DECLARE beh_2   INT;
    DECLARE beh_1   INT;

    -- Hent nuværende beholdning
    SELECT antal_200kr, antal_100kr, antal_50kr, antal_20kr,
           antal_10kr,  antal_5kr,   antal_2kr,  antal_1kr
      INTO beh_200, beh_100, beh_50, beh_20,
           beh_10,  beh_5,   beh_2,  beh_1
      FROM lager
     WHERE lager_id = p_lager_id;

    -- Greedy: tag så mange store mønter som muligt, så længe der er nok på lager
    SET brug_200 = LEAST(FLOOR(rest / 200), beh_200);  SET rest = rest - brug_200 * 200;
    SET brug_100 = LEAST(FLOOR(rest / 100), beh_100);  SET rest = rest - brug_100 * 100;
    SET brug_50  = LEAST(FLOOR(rest /  50), beh_50);   SET rest = rest - brug_50  *  50;
    SET brug_20  = LEAST(FLOOR(rest /  20), beh_20);   SET rest = rest - brug_20  *  20;
    SET brug_10  = LEAST(FLOOR(rest /  10), beh_10);   SET rest = rest - brug_10  *  10;
    SET brug_5   = LEAST(FLOOR(rest /   5), beh_5);    SET rest = rest - brug_5   *   5;
    SET brug_2   = LEAST(FLOOR(rest /   2), beh_2);    SET rest = rest - brug_2   *   2;
    SET brug_1   = LEAST(rest,              beh_1);    SET rest = rest - brug_1;

    -- Hvis vi ikke kunne gøre det helt op: afvis
    IF rest > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ikke nok mønter på lageret til at give byttepenge';
    END IF;

    -- Træk de brugte mønter fra lageret
    UPDATE lager
       SET antal_200kr = antal_200kr - brug_200,
           antal_100kr = antal_100kr - brug_100,
           antal_50kr  = antal_50kr  - brug_50,
           antal_20kr  = antal_20kr  - brug_20,
           antal_10kr  = antal_10kr  - brug_10,
           antal_5kr   = antal_5kr   - brug_5,
           antal_2kr   = antal_2kr   - brug_2,
           antal_1kr   = antal_1kr   - brug_1
     WHERE lager_id = p_lager_id;
END$$

DELIMITER ;