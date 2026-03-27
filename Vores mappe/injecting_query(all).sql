
-- Drinks -- Ai was used in creation of the drinks - for finding avrage values of used coffe and such 
INSERT INTO drink VALUES 
(1,'Americano',0,30,8, 30) , (2,'Cappuccino',100,30,8, 30) , ();


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
(3, 2, 0, 0, '2026-02-03', '00:41:10', -10, 0, 0, 0, 0, 0, 0, 0,),
(4, 2, 0, 0, '2026-02-03', '10:06:51', 15, 0, 0, 0, 0, 0, 0, 0,);

-- transaktion	- Regl: Når kort anvendes, sættes "indbetaling" = 0 fordi det kan gøres på en bedre måde, vi ikke har tid til


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