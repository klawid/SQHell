-- =====================================================================================
-- Update Lager After Transaktion
-- =====================================================================================

-- Trigger kode for lager 
-- Ai was used in creation of this
DELIMITER $$

CREATE TRIGGER update_lager_før_transaktion
BEFORE INSERT ON transaktion
FOR EACH ROW
BEGIN
    DECLARE kaffe_brugt INT;
    DECLARE mælk_brugt INT;
    DECLARE vand_brugt INT;

    --  ingredient usage from drink
	SELECT kaffe_forbrug_g, mælk_forbrug_ml, vand_forbrug_ml
    INTO kaffe_brugt, mælk_brugt, vand_brugt
    FROM drink
    WHERE drink_id = NEW.drink_id;

-- Tjek om der er nok kaffe på lageret
IF (SELECT mængde_kaffe FROM lager WHERE lager_id = NEW.lager_id) < kaffe_brugt THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Ikke nok kaffe på lager';
END IF;	

 -- Tjek om der er nok mælk
IF (SELECT mængde_mælk FROM lager WHERE lager_id = NEW.lager_id) < mælk_brugt THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Ikke nok mælk på lager';
END IF;

-- noget med penge 
-- if( byttepenge_burg_for) then 
-- beregn_byttepenge(1,2); do this idk 


    -- Update lager (assuming only one row with id = 1)
    UPDATE lager
    SET 
        mængde_kaffe = mængde_kaffe -  kaffe_brugt,
        mængde_mælk = mængde_mælk - mælk_brugt
    WHERE lager_id = NEW.lager_id;



END$$

DELIMITER ;
-- =====================================================================================
-- Check adgang for opfyldning
-- =====================================================================================

DELIMITER $$

CREATE PROCEDURE opfyld_lager_login (
    IN p_brugernavn VARCHAR(25),
    IN p_kodeord VARCHAR(25),
    IN p_lager_id INT,
    IN p_kaffe INT,
    IN p_mælk INT,
    IN p_200 INT,
    IN p_100 INT,
    IN p_50 INT,
    IN p_20 INT,
    IN p_10 INT,
    IN p_5 INT,
    IN p_2 INT,
    IN p_1 INT
)
BEGIN
    DECLARE v_medarbejder_id INT;
    DECLARE v_kodeord VARCHAR(25);
    DECLARE v_adgang BOOL;
    DECLARE v_next_id INT;

    -- NEW variables for lager
    DECLARE v_kaffe INT;
    DECLARE v_mælk INT;
    DECLARE v_maks_kaffe INT;
    DECLARE v_maks_mælk INT;

    -- 1. Find bruger
    SELECT medarbejder_id, kodeord, adgangstilladelse
    INTO v_medarbejder_id, v_kodeord, v_adgang
    FROM ansat
    WHERE brugernavn = p_brugernavn;

    IF v_medarbejder_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bruger findes ikke';
    END IF;

    IF v_kodeord != p_kodeord THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Forkert kodeord';
    END IF;

    IF v_adgang = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ingen adgang til opfyldning';
    END IF;

    -- 2. Get current lager values
    SELECT mængde_kaffe, mængde_mælk, maks_kaffe, maks_mælk
    INTO v_kaffe, v_mælk, v_maks_kaffe, v_maks_mælk
    FROM lager
    WHERE lager_id = p_lager_id;
    
    IF v_kaffe + p_kaffe > v_maks_kaffe THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'For meget kaffe - overstiger lagerkapacitet';
    END IF;

    IF v_mælk + p_mælk > v_maks_mælk THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'For meget mælk - overstiger lagerkapacitet';
    END IF;

    -- 4. Generate ID
    SELECT IFNULL(MAX(opfyldning_id),0)+1 INTO v_next_id
    FROM opfyldning;

    -- 5. Insert opfyldning
    INSERT INTO opfyldning VALUES (
        v_next_id,
        v_medarbejder_id,
        p_lager_id,
        p_kaffe,
        p_mælk,
        CURRENT_DATE,
        CURRENT_TIME,
        p_200, p_100, p_50, p_20,
        p_10, p_5, p_2, p_1
    );

END$$

DELIMITER ;

-- =====================================================================================
-- Update Lager After Opfyldning
-- =====================================================================================

DELIMITER $$

CREATE TRIGGER update_lager_after_opfyldning
AFTER INSERT ON opfyldning
FOR EACH ROW
BEGIN
    UPDATE lager
       SET mængde_kaffe  = mængde_kaffe  + NEW.opfyldning_kaffe_g,
           mængde_mælk   = mængde_mælk   + NEW.opfyldning_mælk_ml,
           antal_200kr   = antal_200kr   + NEW.opfyldning_200kr,
           antal_100kr   = antal_100kr   + NEW.opfyldning_100kr,
           antal_50kr    = antal_50kr    + NEW.opfyldning_50kr,
           antal_20kr    = antal_20kr    + NEW.opfyldning_20kr,
           antal_10kr    = antal_10kr    + NEW.opfyldning_10kr,
           antal_5kr     = antal_5kr     + NEW.opfyldning_5kr,
           antal_2kr     = antal_2kr     + NEW.opfyldning_2kr,
           antal_1kr     = antal_1kr     + NEW.opfyldning_1kr,
           opfyldning_id = NEW.opfyldning_id
     WHERE lager_id = 1;
END$$

DELIMITER ;


-- =====================================================================================
-- Beregn Byttepenge Funktion
-- =====================================================================================

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



-- =====================================================================================
-- Køb Drink Funktion
-- =====================================================================================

DELIMITER $$

CREATE PROCEDURE køb_drink (
    IN p_medarbejder_id INT,
    IN p_drink_id       INT,
    IN p_lager_id       INT,
    IN p_betalingstype  BOOL,   -- 0 = kort, 1 = kontant
    IN p_ind_200        INT,
    IN p_ind_100        INT,
    IN p_ind_50         INT,
    IN p_ind_20         INT,
    IN p_ind_10         INT,
    IN p_ind_5          INT,
    IN p_ind_2          INT,
    IN p_ind_1          INT
)
BEGIN
    DECLARE v_pris       INT;
    DECLARE v_indbetalt  INT;
    DECLARE v_byttepenge INT;
    DECLARE v_next_id    INT;

    -- Hent pris
    SELECT drink_pris INTO v_pris
      FROM drink
     WHERE drink_id = p_drink_id;

    IF v_pris IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ukendt drink';
    END IF;

    IF p_betalingstype = 0 THEN
        -- KORT: ingen kontanthåndtering
        SET v_indbetalt  = 0;
        SET v_byttepenge = 0;
    ELSE
        -- KONTANT: regn ud hvad kunden gav
        SET v_indbetalt =
              p_ind_200 * 200 + p_ind_100 * 100
            + p_ind_50  *  50 + p_ind_20  *  20
            + p_ind_10  *  10 + p_ind_5   *   5
            + p_ind_2   *   2 + p_ind_1;

        IF v_indbetalt < v_pris THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ikke nok penge indbetalt';
        END IF;

        SET v_byttepenge = v_indbetalt - v_pris;

        -- Læg kundens mønter i lageret
        UPDATE lager
           SET antal_200kr = antal_200kr + p_ind_200,
               antal_100kr = antal_100kr + p_ind_100,
               antal_50kr  = antal_50kr  + p_ind_50,
               antal_20kr  = antal_20kr  + p_ind_20,
               antal_10kr  = antal_10kr  + p_ind_10,
               antal_5kr   = antal_5kr   + p_ind_5,
               antal_2kr   = antal_2kr   + p_ind_2,
               antal_1kr   = antal_1kr   + p_ind_1
         WHERE lager_id = p_lager_id;

        -- Dispensér byttepenge (procedure giver fejl hvis ikke muligt)
        IF v_byttepenge > 0 THEN
            CALL beregn_byttepenge(p_lager_id, v_byttepenge);
        END IF;
    END IF;

    -- Find næste transaktions-ID
    
     SELECT IFNULL(MAX(transaktion_id), 0) + 1 INTO v_next_id
      FROM transaktion;

    -- Indsæt transaktionen (trigger trækker ingredienser fra lager)
    INSERT INTO transaktion VALUES (
        v_next_id,
        p_medarbejder_id,
        p_drink_id,
        p_lager_id,
        v_indbetalt,
        p_betalingstype,
        v_byttepenge,
        CURRENT_DATE,
        CURRENT_TIME
    );
END$$

DELIMITER ;


-- =====================================================================================
-- Opdater Daglig Forbrug Funktion
-- =====================================================================================

DELIMITER $$

CREATE TRIGGER update_daglig_forbrug
AFTER INSERT ON transaktion
FOR EACH ROW
BEGIN
    DECLARE kaffe_used INT;
    DECLARE mælk_used INT;
    DECLARE vand_used INT;
    DECLARE v_exists INT;
    DECLARE v_next_id INT;  

    -- Get usage from drink
    SELECT kaffe_forbrug_g, mælk_forbrug_ml, vand_forbrug_ml
    INTO kaffe_used, mælk_used, vand_used
    FROM drink
    WHERE drink_id = NEW.drink_id;

    -- Check if a row for this date already exists
    SELECT COUNT(*) INTO v_exists
    FROM daglig_forbrug
    WHERE dato = NEW.dato;

    IF v_exists = 0 THEN

    
        SELECT IFNULL(MAX(forbrug_id),0)+1
        INTO v_next_id
        FROM daglig_forbrug;

        
        INSERT INTO daglig_forbrug (
            forbrug_id,
            dato,
            sum_kaffe,
            sum_mælk,
            sum_vand
        )
        VALUES (
            v_next_id,
            NEW.dato,
            kaffe_used,
            mælk_used,
            vand_used
        );

    ELSE
        UPDATE daglig_forbrug
        SET 
            sum_kaffe = sum_kaffe + kaffe_used,
            sum_mælk  = sum_mælk  + mælk_used,
            sum_vand  = sum_vand  + vand_used
        WHERE dato = NEW.dato;
    END IF;

END$$

DELIMITER ;

-- =====================================================================================
-- Check adgang og logføring af rengøring
-- =====================================================================================

DELIMITER $$

CREATE PROCEDURE rengør_maskine (
    IN p_brugernavn VARCHAR(25),
    IN p_kodeord VARCHAR(25)
)
BEGIN
    DECLARE v_medarbejder_id INT;
    DECLARE v_kodeord VARCHAR(25);
    DECLARE v_adgang BOOL;
    DECLARE v_next_id INT;

    -- 1. Find user
    SELECT medarbejder_id, kodeord, adgangstilladelse
    INTO v_medarbejder_id, v_kodeord, v_adgang
    FROM ansat
    WHERE brugernavn = p_brugernavn;

    -- 2. Check user exists
    IF v_medarbejder_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bruger findes ikke';
    END IF;

    -- 3. Check password
    IF v_kodeord != p_kodeord THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Forkert kodeord';
    END IF;

    -- 4. Check permission
    IF v_adgang = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ingen adgang til rengøring';
    END IF;

    -- 5. Insert cleaning log
    SELECT IFNULL(MAX(rengøring_id),0)+1 INTO v_next_id
    FROM rengøring;

    INSERT INTO rengøring (
        rengøring_id,
        medarbejder_id,
        dato
    )
    VALUES (
        v_next_id,
        v_medarbejder_id,
        CURRENT_DATE
    );

END$$

DELIMITER ;
