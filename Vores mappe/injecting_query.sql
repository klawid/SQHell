
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
(1, null, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2000, 2000);


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


