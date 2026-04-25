

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