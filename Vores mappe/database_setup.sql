-- ================================================================================
-- Database filen
-- Brug denne fil for at sætte gang i databasen, dens entities og dens automation
-- ================================================================================
DROP DATABASE IF EXISTS kaffemaskine;
CREATE DATABASE kaffemaskine;
USE kaffemaskine;

-- ================================================================================
-- Entities
-- ================================================================================

CREATE TABLE drink(
drink_id int not null, 
navn char(25) not null,
kaffe_forbrug_g int not null,
mælk_forbrug_ml int not null, 
vand_forbrug_ml int not null, 
drink_pris int not null, 
primary key(drink_id)
);


CREATE TABLE ansat(
medarbejder_id int not null,
navn		char(25) not null,
efternavn	char(25) not null,
stilling 	char(25) not null,
brugernavn 	char(25) not null,
kodeord 	char(25) not null,
adgangstilladelse bool not null,
primary key(medarbejder_id)
);


CREATE TABLE rengøring(
rengøring_id 		int not null,
medarbejder_id		int not null,
dato	 			date not null,
primary key(rengøring_id),
foreign key (medarbejder_id) references ansat(medarbejder_id)
);


CREATE TABLE opfyldning(
opfyldning_id 			int not null,
medarbejder_id			int not null,
opfyldning_kaffe_g		int not null,
opfyldning_mælk_ml		int not null,
dato					date not null,	
tidspunkt				TIME not null,
opfyldning_200kr        int not null,
opfyldning_100kr        int not null,
opfyldning_50kr         int not null,
opfyldning_20kr         int not null,
opfyldning_10kr         int not null,
opfyldning_5kr          int not null,
opfyldning_2kr          int not null,
opfyldning_1kr          int not null,
primary key(opfyldning_id ),
foreign key (medarbejder_id) references ansat(medarbejder_id)
);


CREATE TABLE lager(
    lager_id        int not null,
    opfyldning_id   int,				-- vi kan prøve at beholde den og se hvad der sker. 	
    antal_200kr     int not null,
    antal_100kr     int not null,
    antal_50kr      int not null,
    antal_20kr      int not null,
    antal_10kr      int not null,
    antal_5kr       int not null,
    antal_2kr       int not null,
    antal_1kr       int not null,
    mængde_kaffe    int not null,
    mængde_mælk     int not null,
    maks_kaffe      int not null,
    maks_mælk       int not null,
    primary key(lager_id),
    foreign key (opfyldning_id) references opfyldning(opfyldning_id)
);

CREATE TABLE transaktion(
transakion_id			int not null,
medarbejder_id			int not null,
drink_id				int not null,
lager_id  				int not null,
kontant_indbetaling     int not null,
betalingstype			bool not null, -- FALSE er kort, TRUE er kontant
byttepenge				int not null, -- Hvis vi kun har hele kroner der kan betales med, og hele priser på drinks, så kan denne vel godt være en int (Var float)
dato 					date not null,	
tidspunkt 				time not null,
primary key(transakion_id),
foreign key (medarbejder_id) references ansat(medarbejder_id),
foreign key (drink_id) references drink(drink_id),
foreign key (lager_id) references lager(lager_id)
);

CREATE TABLE daglig_forbrug(
forbrug_id			int not null,
transakion_id		int not null,
dato				date not null,
sum_kaffe			int not null,
sum_mælk			int not null,
sum_vand			int not null,
primary key(forbrug_id),
foreign key (transakion_id) references transaktion(transakion_id)
);




-- ================================================================================
-- Automation (Triggers og Procedures)
-- ================================================================================


-- Update Lager After Transaktion
-- DROP PROCEDURE IF EXISTS update_lager_after_transaktion; -- Udkommenter denne her når vi er færdige med at teste alting

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



-- Update Lager After Opfyldning
-- DROP PROCEDURE IF EXISTS update_lager_after_opfyldning; -- Udkommenter denne her når vi er færdige med at teste alting

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


-- Beregn Byttepenge Funktion
-- DROP PROCEDURE IF EXISTS beregn_byttepenge; -- Udkommenter denne her når vi er færdige med at teste alting

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



-- Køb Drink Funktion
-- DROP PROCEDURE IF EXISTS køb_drink; -- Udkommenter denne her når vi er færdige med at teste alting

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
    SELECT IFNULL(MAX(transakion_id), 0) + 1 INTO v_next_id
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


-- ================================================================================
-- Injections
-- ================================================================================

-- Drinks 
INSERT INTO drink VALUES 
(1,'Americano',30 , 0, 330, 25) , 
(2,'Cappuccino', 30, 150, 150, 30) , 
(3,'Espresso', 100, 0, 50, 35);


-- Ansatte
INSERT INTO ansat VALUES
(1, 'Jens','Git','Arbejdsdreng', 'JeGi', 'kodeord123', FALSE),
(2, 'Klawid', 'Dasa', 'Cheese Wizard', 'KlDa', 'JegErSej1', TRUE),
(3, 'Donald', 'Trump', 'President', 'The_trumping_man', 'xxBuild_great_wall_xd_xd', FALSE);


-- Rengøring
INSERT INTO rengøring VALUES 
(1, 1, '2026-02-02'),
(2, 1, '2026-02-09'),
(3, 3, '2026-02-16'),
(4, 1, '2026-02-23'),
(5, 1, '2026-03-02');



-- Daglig forbrug - samme som lager.
-- Denne kode funger ikke: Det er noget der skal DANNES I KAFFEDDL 
-- INSERT INTO daglig_forbrug VALUES
-- (1, 0,'2000-01-01', 0,0,0); 

-- Lager (starttilstand – ingen opfyldning endnu, så opfyldning_id sættes til NULL)
-- Bemærk: opfyldning_id skal være NULL her, så fjern NOT NULL på den kolonne i CREATE TABLE
INSERT INTO lager VALUES
(1, null, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4000, 4000);


-- Opfyldning
INSERT INTO opfyldning VALUES 
(1, 2, 2000, 500, '2026-02-01', '14:36:00', 20, 10, 10, 30, 30, 50, 100, 100),
(2, 2, 500, 1000, '2026-02-02', '13:15:16', 0, 1, 0, 5, 2, 10, 20, 20),
(3, 2, 0, 0, '2026-02-03', '00:41:10', -10, -5, -5, -3, 0, 0, 0, 0),
(4, 2, 0, 0, '2026-02-03', '10:06:51', 12, 7, 7, 5, 0, 0, 0, 0);



-- transaktion	- Regl: Når kort anvendes, sættes "indbetaling" = FALSE 
-- Kolonner: id, medarbejder_id, drink_id, lager_id, indbetaling, betalingstype, byttepenge, dato, tidspunkt

-- transaktion	- Regl: Når kort anvendes, sættes "kontant_indbetaling" = 0 
-- Kolonner: id, medarbejder_id, drink_id, lager_id, kontant_indbetaling, betalingstype, byttepenge, dato, tidspunkt

-- betalingstype: 0 = kort, 1 = kontant
INSERT INTO transaktion VALUES
-- Jens Git – tidlige morgenvagter i Februar
(1,  1, 2, 1,  0,  0, 0, '2026-02-05', '05:06:51'),
(2,  1, 1, 1,  0,  0, 0, '2026-02-05', '05:15:00'),
(3,  1, 3, 1,  0,  0, 0, '2026-02-05', '05:17:00'),
(4,  1, 1, 1,  0,  0, 0, '2026-02-05', '05:19:00'),
(5,  1, 3, 1,  40, 1, 5, '2026-02-12', '06:00:00'),
(6,  1, 3, 1,  40, 1, 5, '2026-02-19', '06:05:00'),
(7,  1, 2, 1,  0,  0, 0, '2026-02-26', '05:55:00'),
(8,  1, 1, 1,  40, 1, 15, '2026-03-02', '06:10:00'),
-- Klawid Dasa – regelmæssige køb
(9,  2, 1, 1,  0,  0, 0, '2026-02-03', '10:00:00'),
(10, 2, 1, 1,  0,  0, 0, '2026-02-10', '10:00:00'),
(11, 2, 2, 1,  35, 1, 0, '2026-02-17', '10:00:00'),
(12, 2, 2, 1,  35, 1, 0, '2026-02-24', '10:00:00'),
(13, 2, 3, 1,  0,  0, 0, '2026-03-03', '10:00:00'),
(14, 2, 1, 1,  0,  0, 0, '2026-03-10', '10:00:00'),
-- Donald Trump – lejlighedsvise køb
(15, 3, 2, 1,  0,  0, 0, '2026-02-05', '08:30:00'),
(16, 3, 3, 1,  200, 1, 165, '2026-02-19', '09:00:00'),
(17, 3, 1, 1,  0,  0, 0, '2026-03-01', '11:00:00');

-- Når du er nået hertil, så skulle databasen gerne være korrekt sat op.