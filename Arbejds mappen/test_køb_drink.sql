

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



DELIMITER $$

CREATE PROCEDURE køb_drink (
    IN ny_medarbejder_id INT,
    IN ny_drink_id       INT,
    IN ny_lager_id       INT,
    IN ny_betalingstype  BOOL,   -- 0 = kort, 1 = kontant
    IN ny_200        INT,
    IN ny_100        INT,
    IN ny_50         INT,
    IN ny_20         INT,
    IN ny_10         INT,
    IN ny_5          INT,
    IN ny_2          INT,
    IN ny_1          INT
)
BEGIN
    DECLARE v_pris       INT;
    DECLARE v_indbetalt  INT;
    DECLARE v_byttepenge INT;
    DECLARE v_next_id    INT;

    -- Hent pris
    SELECT drink_pris INTO v_pris
      FROM drink
     WHERE drink_id = ny_drink_id;

-- ---------------------------------------------------------------------
-- 		Håntering af byttepenge
-- ---------------------------------------------------------------------

    IF ny_betalingstype = 0 THEN	-- KORT: ingen kontanthåndtering
        SET v_indbetalt  = 0;
        SET v_byttepenge = 0;
    ELSE
        -- KONTANT: regn ud hvad kunden gav
        SET v_indbetalt =
              ny_200*200 + ny_100*100  + ny_50*50 + ny_20*20  + ny_10*10 + ny_5*5 + ny_2*2 + ny_1;

        IF v_indbetalt < v_pris THEN	
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ikke nok penge indbetalt';
        END IF;

        SET v_byttepenge = v_indbetalt - v_pris;

-- ---------------------------------------------------------------------
-- 		Håntering af lager 
-- ---------------------------------------------------------------------

        -- Læg kundens mønter i lageret	
        UPDATE lager
           SET antal_200kr = antal_200kr + ny_200,
               antal_100kr = antal_100kr + ny_100,
               antal_50kr  = antal_50kr  + ny_50,
               antal_20kr  = antal_20kr  + ny_20,
               antal_10kr  = antal_10kr  + ny_10,
               antal_5kr   = antal_5kr   + ind_5,
               antal_2kr   = antal_2kr   + ny_2,
               antal_1kr   = antal_1kr   + ny_1
         WHERE lager_id = ny_lager_id;

        -- Dispensér byttepenge (procedure giver fejl hvis ikke muligt)	
        IF v_byttepenge > 0 THEN
            CALL beregn_byttepenge(ny_lager_id, v_byttepenge);
        END IF;
    END IF;

	
    -- update af mælk + kaffe sker gennem en trigger før en transaktion dannes

-- ---------------------------------------------------------------------
-- 		Dannelse af ny transaktion 
-- ---------------------------------------------------------------------

    -- Find næste transaktions-ID
    SELECT MAX(transakion_id) + 1 INTO v_next_id		
      FROM transaktion;

    -- Indsæt transaktionen (trigger trækker ingredienser fra lager)
    INSERT INTO transaktion VALUES (
        v_next_id,
        ny_medarbejder_id,
        ny_drink_id,
        ny_lager_id,
        v_indbetalt,
        ny_betalingstype,
        v_byttepenge,
        CURRENT_DATE,
        CURRENT_TIME
    );
END$$

DELIMITER ;


SELECT transakion_id,dato,tidspunkt 		-- Få fist alle transaktioner? 
FROM transaktion
ORDER BY transakion_id;

-- brug funktionen 
CALL køb_drink(1,3,1,0,0,0,0,0,0,0,0,0); 

SELECT transakion_id,dato,tidspunkt 		-- Få fist alle transaktioner? 
FROM transaktion
ORDER BY dato; 

-- Ny transaktion på plads. 
-- Har transaktionen alle sine dele med? 