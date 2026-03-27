
-- Drinks 
INSERT INTO drink VALUES 
(1,'Americano',30 , 0, 330, 30) , 
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



-- Opfyldning
INSERT INTO opfyldning VALUES 
(1, 2, 2000, 500, '2026-02-01', '14:36:00', 5, 10, 10, 30, 30, 50, 100, 100),
(2, 2, 500, 1000, '2026-02-02', '13:15:16', 0, 1, 0, 5, 2, 10, 20, 20),
(3, 2, 0, 0, '2026-02-03', '00:41:10', -10, 0, 0, 0, 0, 0, 0, 0),
(4, 2, 0, 0, '2026-02-03', '10:06:51', 15, 0, 0, 0, 0, 0, 0, 0);



-- Lager (starttilstand – ingen opfyldning endnu, så opfyldning_id sættes til NULL)
-- Bemærk: opfyldning_id skal være NULL her, så fjern NOT NULL på den kolonne i CREATE TABLE
INSERT INTO lager VALUES
(1, null, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2000, 2000);

-- transaktion	- Regl: Når kort anvendes, sættes "indbetaling" = FALSE 
-- Kolonner: id, medarbejder_id, drink_id, lager_id, indbetaling, betalingstype, byttepenge, dato, tidspunkt
-- betalingstype: 0 = kort, 1 = kontant
INSERT INTO transaktion VALUES
-- Jens Git – tidlige morgenvagter i januar
(1,  1, 2, 1,  0,  0, 0, '2026-01-05', '05:06:51'),
(2,  1, 1, 1,  0,  0, 0, '2026-01-05', '05:15:00'),
(3,  1, 3, 1,  0,  0, 0, '2026-01-05', '05:17:00'),
(4,  1, 1, 1,  0,  0, 0, '2026-01-05', '05:19:00'),
(5,  1, 3, 1,  30, 1, 5, '2026-01-12', '06:00:00'),
(6,  1, 3, 1,  30, 1, 5, '2026-01-19', '06:05:00'),
(7,  1, 2, 1,  0,  0, 0, '2026-01-26', '05:55:00'),
(8,  1, 1, 1,  20, 1, 0, '2026-02-02', '06:10:00'),
-- Klawid Dasa – regelmæssige køb
(9,  2, 1, 1,  0,  0, 0, '2026-02-03', '10:00:00'),
(10, 2, 1, 1,  0,  0, 0, '2026-02-10', '10:00:00'),
(11, 2, 2, 1,  30, 1, 0, '2026-02-17', '10:00:00'),
(12, 2, 2, 1,  30, 1, 0, '2026-02-24', '10:00:00'),
(13, 2, 3, 1,  0,  0, 0, '2026-03-03', '10:00:00'),
(14, 2, 1, 1,  0,  0, 0, '2026-03-10', '10:00:00'),
-- Donald Trump – lejlighedsvise køb
(15, 3, 2, 1,  0,  0, 0, '2026-02-05', '08:30:00'),
(16, 3, 3, 1,  25, 1, 0, '2026-02-19', '09:00:00'),
(17, 3, 1, 1,  0,  0, 0, '2026-03-01', '11:00:00');




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
    INTO kaffe_used, mælk_used, kakao_used
    FROM drink
    WHERE id = NEW.drink_id;

IF (SELECT mængde_kaffe FROM lager WHERE lager_id = NEW.lager_id) < kaffe_used THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Not enough coffee in stock';
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

CREATE PROCEDURE beregn_byttepenge (
    IN p_beloeb INT,
    IN p_lager_id INT
)
BEGIN
    DECLARE rest INT;

    DECLARE beholdning100 INT;
    DECLARE beholdning50 INT;
    DECLARE beholdning20 INT;
    DECLARE beholdning10 INT;
    DECLARE beholdning5 INT;
    DECLARE beholdning2 INT;
    DECLARE beholdning1 INT;

    DECLARE byttepenge100 INT DEFAULT 0;
    DECLARE byttepenge50 INT DEFAULT 0;
    DECLARE byttepenge20 INT DEFAULT 0;
    DECLARE byttepenge10 INT DEFAULT 0;	 	
    DECLARE byttepenge5 INT DEFAULT 0;
    DECLARE byttepenge2 INT DEFAULT 0;
    DECLARE byttepenge1 INT DEFAULT 0;

    -- hent lager
    SELECT antal_100kr, antal_50kr, antal_20kr, antal_10kr,
           antal_5kr, antal_2kr, antal_1kr
    INTO beholdning100, beholdning50, beholdning20, beholdning10, beholdning5, beholdning2, beholdning1
    FROM lager
    WHERE lager_id = p_lager_id;

    SET rest = p_beloeb;

    -- 100 kr
    SET byttepenge100 = LEAST(rest DIV 100, beholdning100);
    SET rest = rest - byttepenge100 * 100;

    -- 50 kr
    SET byttepenge50 = LEAST(rest DIV 50, beholdning50);
    SET rest = rest - byttepenge50 * 50;

    -- 20 kr
    SET byttepenge20 = LEAST(rest DIV 20, beholdning20);
    SET rest = rest - byttepenge20 * 20;

    -- 10 kr
    SET byttepenge10 = LEAST(rest DIV 10, beholdning10);
    SET rest = rest - byttepenge10 * 10;

    -- 5 kr
    SET byttepenge5 = LEAST(rest DIV 5, beholdning5);
    SET rest = rest - byttepenge5 * 5;

    -- 2 kr
    SET byttepenge2 = LEAST(rest DIV 2, beholdning2);
    SET rest = rest - byttepenge2 * 2;

    -- 1 kr
    SET byttepenge1 = LEAST(rest, beholdning1);
    SET rest = rest - byttepenge1;

    -- resultat
    SELECT 
        byttepenge100 AS '100kr',
        byttepenge50  AS '50kr',
        byttepenge20  AS '20kr',
        byttepenge10  AS '10kr',
        byttepenge5   AS '5kr',
        byttepenge2   AS '2kr',
        byttepenge1   AS '1kr',
        rest AS 'mangler';
END //

DELIMITER ;