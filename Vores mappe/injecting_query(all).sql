
-- Drinks 
INSERT INTO drink VALUES 
(1,'Americano',30 , 0,330 , 30) , (2,'Cappuccino',30,150,150, 30) , (3,'Espresso', 100 , 0, 50, 99);


-- Ansatte
INSERT INTO ansat VALUES
(1, 'Jens','Git','Arbejdsdreng', 'JeGi', 'kodeord123', FALSE),
(2, 'Klawid', 'Dasa', 'Cheese Wizard', 'KlDa', 'JegErSej1', TRUE),
(3, 'Donald', 'Trump', 'President', 'The_trumping_man', 'xxBuild_great_wall_xd_xd', FALSE);


-- Lager  : Det her starter den bare. Senere skal vi opdatere dette lager med id 1, og så kommer opfyldning id til at gå op
INSERT INTO lager VALUES
(1, 0, 0, 0,0,0,0,0,0, 0 , 0, 2000,2000); 

-- Daglig forbrug - samme som lager. 
INSERT INTO daglig_forbrug VALUES
(0, 0,'2000-01-01', 0,0,0); 



-- Opfyldning
INSERT INTO opfyldning VALUES 
(1, 2, 2000, 500, '2026-02-01', '14:36:00', 5, 10, 10, 30, 30, 50, 100, 100),
(2, 2, 500, 1000, '2026-02-02', '13:15:16', 0, 1, 0, 5, 2, 10, 20, 20),
(3, 2, 0, 0, '2026-02-03', '00:41:10', -10, 0, 0, 0, 0, 0, 0, 0),
(4, 2, 0, 0, '2026-02-03', '10:06:51', 15, 0, 0, 0, 0, 0, 0, 0);

-- transaktion	- Regl: Når kort anvendes, sættes "indbetaling" = 0 


INSERT INTO transaktion VALUES 
-- Jens git - mange drinks få dage 
(1,1,2,1,0,'26-01-01','5:06:51'), (2,1,1,1,0,'26-01-01','5:15:00'), (3,1,3,1,0,'26-01-01','5:15:50'),(4,1,1,1,0,'26-01-01','5:16:00'),
(5,1,3,1,0,'25-12-24','23:50:51'), (6,1,3,1,0,'25-12-24','23:55:00'), (7,1,3,1,0,'25-12-24','23:56:50'),(8,1,3,1,0,'25-12-24','23:59:00'),
-- Klawid Dasa 
(9,2,1,1,0,'25-12-22','10:00:00') , (10,2,1,1,0,'25-12-26','10:00:00') , (11,2,1,1,0,'25-12-28','10:00:00') ,(12,2,1,1,0,'26-01-01','10:00:00') ,
-- Donald Trump
(9,2,1,1,0,'25-12-22','10:00:00') ;


-- Rengøring
INSERT INTO rengøring VALUES 
(1, 1, '2026-02-02'),
(1, 1, '2026-02-09'),
(1, 3, '2026-02-16'),
(1, 1, '2026-02-23'),
(1, 1, '2026-03-02'),

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