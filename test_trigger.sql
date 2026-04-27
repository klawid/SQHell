

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



-- ---------------------------------------------------------------------
-- Test af: TRIGGER Transaktion og PROCEDURE køb_drink — filtrerbar
-- ---------------------------------------------------------------------
-- Anvendelse af test1: 
	-- 1: Update lager til en bestemt/vilkårig værdi 
    -- 2: Prøv at insert en test værdi. Med givet værdier, vil error "ikke nok kaffe på lager" vises. Dette sker pga. TRIGGER. 
		-- Brug select 
    -- 3: UPDATE lager med givet værdier.  
    -- 4: Select der visser før og efter lager værdi. Vil ikke virke hvis forrige select ikke blev kørt 
    -- 5: Udfør test inserten igen, der denne gang vil virke.
    -- 6: Compile af denne select vil visse "efter_kaffe" med nye værdier pga. TRIGGER, der automatisk har opdateret lager. Her vil ny værdi og kaffe- samt mælk kosten for drunk 2 kunne ses 


-- Anvendelse af test1:     
-- ---------------------------------------------------------------------


-- 			test 1
UPDATE lager						-- 1: Update lager til en vilkårig værdi
SET 
    mængde_kaffe = 0,
    mængde_mælk = 0
WHERE lager_id = 1;

INSERT INTO transaktion VALUES		-- 2: Prøv at insert en test værdi.
(99,  1, 2, 1,  0,  0, 0, '2026-02-05', '05:06:51');

SELECT 											-- Brug select 
    mængde_kaffe, 
    mængde_mælk
INTO @for_kaffe, @for_melk			-- Lige denne kode kan ikke tage æ og ø
FROM lager
WHERE lager_id = 1;


UPDATE lager						-- 3: UPDATE lager med givet værdier.  
SET 
    mængde_kaffe = 1000,
    mængde_mælk = 200
WHERE lager_id = 1;


SELECT								-- 4: Vis før og efter lager værdi med denne select. Vil ikke virke hvis forrige select ikke blev kørt  								
    @for_kaffe	 AS kaffe_før_update,
    mængde_kaffe AS efter_kaffe,
    @for_melk AS mælk_før_update,
    mængde_mælk AS efter_mælk
FROM lager
WHERE lager_id = 1;

INSERT INTO transaktion VALUES    -- 5: Udfør test inserten igen, der denne gang vil virke.				
(99,  1, 2, 1,  0,  0, 0, '2026-02-05', '05:06:51');


SELECT								-- 6: Compile af denne select vil visse "efter_kaffe" med nye værdier pga. TRIGGER, der automatisk har opdateret lager. Her vil ny værdi og kaffe- samt mælk kosten for drunk 2 kunne ses 								
    @for_kaffe	 AS kaffe_før_update,
    mængde_kaffe AS efter_kaffe,
    @for_melk AS mælk_før_update,
    mængde_mælk AS efter_mælk,
	kaffe_forbrug_g,
	mælk_forbrug_ml
FROM lager
 JOIN drink ON drink_id = 2
WHERE lager_id = 1;




