
-- ---------------------------------------------------------------------
-- QUERY 1: Transaktioner — filtrer efter tidsrum, drink og betalingstype
-- ---------------------------------------------------------------------
-- Brug NULL i en filter-variabel for "alle". Sæt en værdi for at filtrere.
-- Eksemplerne nedenfor demonstrerer forskellige kombinationer.
-- ---------------------------------------------------------------------

-- EKSEMPEL 1a: ALLE transaktioner (general test)
SET @fra_dato       = NULL, 
@til_dato       = NULL, 
@drink_id       = NULL, 
@betalingstype  = NULL;

SELECT t.transakion_id,
       t.dato,
       t.tidspunkt,
       a.navn 			AS fornavn,
	   a.efternavn 		AS efternavn,
       d.navn 			AS drink,
       d.drink_pris     AS pris,
       CASE t.betalingstype WHEN 0 THEN 'Kort' ELSE 'Kontant' END AS betaling,
       t.kontant_indbetaling,
       t.byttepenge
  FROM transaktion t
  JOIN ansat a ON t.medarbejder_id = a.medarbejder_id
  JOIN drink d ON t.drink_id       = d.drink_id
 WHERE (@fra_dato      IS NULL OR t.dato          >= @fra_dato)
   AND (@til_dato      IS NULL OR t.dato          <= @til_dato)
   AND (@drink_id      IS NULL OR t.drink_id       = @drink_id)
   AND (@betalingstype IS NULL OR t.betalingstype  = @betalingstype)
 ORDER BY t.dato, t.tidspunkt;


-- EKSEMPEL 1b: Kun transaktioner i fra februar 1 til feb 15 (2026)
SET @fra_dato       = '2026-02-01' ,
	@til_dato       = '2026-02-15',
	@drink_id       = NULL,
	@betalingstype  = NULL;
	
SELECT t.transakion_id, t.dato, t.tidspunkt,
       CONCAT(a.navn, ' ', a.efternavn) AS medarbejder,
       d.navn AS drink, d.drink_pris,
       CASE t.betalingstype WHEN 0 THEN 'Kort' ELSE 'Kontant' END AS betaling
  FROM transaktion t
  JOIN ansat a ON t.medarbejder_id = a.medarbejder_id
  JOIN drink d ON t.drink_id       = d.drink_id
 WHERE (@fra_dato      IS NULL OR t.dato          >= @fra_dato)
   AND (@til_dato      IS NULL OR t.dato          <= @til_dato)
   AND (@drink_id      IS NULL OR t.drink_id       = @drink_id)
   AND (@betalingstype IS NULL OR t.betalingstype  = @betalingstype)
 ORDER BY t.dato, t.tidspunkt;


-- EKSEMPEL 1c: Kun kontante espresso-køb (drink_id = 3, betalingstype = 1)
SET @fra_dato       = NULL,
@til_dato       = NULL,
@drink_id       = 3,
@betalingstype  = 1;

SELECT t.transakion_id, t.dato, t.tidspunkt,
       CONCAT(a.navn, ' ', a.efternavn) AS medarbejder,
       d.navn AS drink, t.kontant_indbetaling, t.byttepenge
  FROM transaktion t
  JOIN ansat a ON t.medarbejder_id = a.medarbejder_id
  JOIN drink d ON t.drink_id       = d.drink_id
 WHERE (@fra_dato      IS NULL OR t.dato          >= @fra_dato)
   AND (@til_dato      IS NULL OR t.dato          <= @til_dato)
   AND (@drink_id      IS NULL OR t.drink_id       = @drink_id)
   AND (@betalingstype IS NULL OR t.betalingstype  = @betalingstype)
 ORDER BY t.dato, t.tidspunkt;



-- ---------------------------------------------------------------------
--  QUERY 2: Lagerstatus 
--  Forksellige test/check af lagerstatus 
-- ---------------------------------------------------------------------

-- 2a: Ingredienser (kaffe, mælk) med fyldningsgrad i procent		// er fyldnignsgrad i % vejen frem? Hvorfor gør vi det således.
SELECT lager_id,
       mængde_kaffe,
       maks_kaffe,
       ROUND(100 * mængde_kaffe / maks_kaffe, 1) AS kaffe_pct,
       mængde_mælk,
       maks_mælk,
       ROUND(100 * mængde_mælk / maks_mælk, 1)   AS mælk_pct
  FROM lager
 WHERE lager_id = 1;

-- 2b: Mønter — beholdning per type og samlet kontantsum
SELECT antal_200kr, antal_100kr, antal_50kr, antal_20kr,
       antal_10kr,  antal_5kr,   antal_2kr,  antal_1kr,
       (antal_200kr*200 + antal_100kr*100 + antal_50kr*50 + antal_20kr*20
      + antal_10kr*10  + antal_5kr*5     + antal_2kr*2   + antal_1kr) AS kontant_sum_kr
  FROM lager
 WHERE lager_id = 1;


-- 2c: lagerhistorik: Forbruget på en dag + opfyldning

SET @dato = '2026-02-05';

SELECT
    t.dato,
    t.tidspunkt,
    'Transaktion' AS hændelse,
    t.transakion_id AS id,
    d.mælk_forbrug_ml AS brugt_mælk,
    d.kaffe_forbrug_g AS brugt_kaffe,
    d.vand_forbrug_ml AS brugt_vand,
    0 AS indsat_mælk,
    0 AS indsat_kaffe
FROM transaktion t
JOIN drink d ON t.drink_id = d.drink_id
WHERE t.dato = @dato

UNION ALL

SELECT
    o.dato,
    o.tidspunkt,
    'Opfyldning' AS hændelse,
    o.opfyldning_id AS id,
    0 AS brugt_mælk,
    0 AS brugt_kaffe,
    0 AS brugt_vand,
    o.opfyldning_mælk_ml AS indsat_mælk,
    o.opfyldning_kaffe_g AS indsat_kaffe
FROM opfyldning o
WHERE o.dato = @dato

ORDER BY tidspunkt;




-- ---------------------------------------------------------------------
-- QUERY 3: Rengøringshistorik
-- ---------------------------------------------------------------------

-- 3a: Alle rengøringer med dato og medarbejder
SELECT r.rengøring_id,
       r.dato,
       a.navn AS fornavn,
       a.efternavn AS efternavn, 
       a.stilling	
  FROM rengøring r
  JOIN ansat a ON r.medarbejder_id = a.medarbejder_id
 ORDER BY r.dato;

-- 3b: Indsæt en rengøring korrekt
CALL rengør_maskine('KlDa', 'JegErSej1');

-- 3c: Ingen adgang til at rengøre
CALL rengør_maskine('JeGi', 'kodeord123');

-- 3d: Forkert kodeord
CALL rengør_maskine('KlDa', 'forkert');

-- 3e: Forkert brugernavn
CALL rengør_maskine('unknown', '123');

-- ---------------------------------------------------------------------
-- QUERY 4: Opfyldningshistorik
-- ---------------------------------------------------------------------

-- 4a: Alle opfyldninger
SELECT o.opfyldning_id,
        o.dato,
        o.tidspunkt,
        CONCAT(a.navn, ' ', a.efternavn) AS medarbejder,
        o.opfyldning_kaffe_g,
        o.opfyldning_mælk_ml,
        o.opfyldning_200kr, o.opfyldning_100kr, o.opfyldning_50kr, o.opfyldning_20kr,
        o.opfyldning_10kr,  o.opfyldning_5kr,   o.opfyldning_2kr,  o.opfyldning_1kr
    FROM opfyldning o
    JOIN ansat a ON o.medarbejder_id = a.medarbejder_id
  ORDER BY o.dato, o.tidspunkt;

-- 4b: Indsæt en opfyldning korrekt
-- Kolonner: brugernavn, kodeord, lager_id, opfyldning_kaffe_g, opfyldning_mælk_ml, opfyldning_xkr ... opfyldning_ykr
CALL opfyld_lager_login('KlDa', 'JegErSej1', 1, 500, 200, 1,0,0,0,0,0,0,0);

-- 4c: Ingen adgang til at opfylde lageret
CALL opfyld_lager_login('JeGi', 'kodeord123', 1, 500, 200, 0,0,0,0,0,0,0,0);

-- 4d: Forkert kodeord
CALL opfyld_lager_login('KlDa', 'forkert', 1, 500, 200, 0,0,0,0,0,0,0,0);

-- 4e: Forkert brugernavn
CALL opfyld_lager_login('unknown', '123', 1, 500, 200, 0,0,0,0,0,0,0,0);

-- =====================================================================
-- Test Koder
-- Brug disse til at prøve at teste databasen med - Hvis du altså synes det er en sjov ting at bruge sit liv på
-- =====================================================================


-- Beregn Byttepenge test
-- Du kan taste denne ind for at prøve at se om beregn_byttepenge virker.
-- Det første tal er lager_id, og for nu er der kun ét ID, så den skal bare være 1.
-- Det andet tal er til mængden af byttepenge du skal have tilbage. 
-- Der er to selects, så du kan se antallet af hver denomination af kronerne, både før og efter.
SELECT antal_200kr, antal_100kr, antal_50kr, antal_20kr, antal_10kr, antal_5kr, antal_2kr, antal_1kr FROM lager WHERE lager_id = 1;
CALL beregn_byttepenge(1, 165);
SELECT antal_200kr, antal_100kr, antal_50kr, antal_20kr, antal_10kr, antal_5kr, antal_2kr, antal_1kr FROM lager WHERE lager_id = 1;



-- =====================================================================
-- Test af: 	TRIGGER Transaktion
-- Funktion: 	Updater lager (kaffe og mælk indhold) 
-- =====================================================================

-- Anvendelse af testen:  
	-- 1: Update lager til en bestemt/vilkårig værdi 
    -- 2: Prøv at insert en test værdi. Med givet værdier, vil error "ikke nok kaffe på lager" vises. Dette sker pga. TRIGGER. 
		-- Brug select 
    -- 3: UPDATE lager med givet værdier.  
    -- 4: Select der visser før og efter lager værdi. Vil ikke virke hvis forrige select ikke blev kørt 
    -- 5: Udfør test inserten igen, der denne gang vil virke.
    -- 6: Compile af denne select vil visse "efter_kaffe" med nye værdier pga. TRIGGER, der automatisk har opdateret lager. Her vil ny værdi og kaffe- samt mælk kosten for drunk 2 kunne ses 

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


SELECT							  -- 6: Compile af denne select vil visse "efter_kaffe" med nye værdier pga. TRIGGER, der automatisk har opdateret lager. Her vil ny værdi og kaffe- samt mælk kosten for drunk 2 kunne ses 								
    @for_kaffe	 AS kaffe_før_update,
    mængde_kaffe AS efter_kaffe,
    @for_melk AS mælk_før_update,
    mængde_mælk AS efter_mælk,
	kaffe_forbrug_g,
	mælk_forbrug_ml
FROM lager
 JOIN drink ON drink_id = 2
WHERE lager_id = 1;



-- =====================================================================
-- Test af: 	PROCEDURE køb_drink
-- Funktion: 	Danner/adder en ny transaktion 
-- =====================================================================
-- Anvendelse af testen:  
	-- 1: Tjek antal transaktioner (højeste id) med nedestående SELECT (burde være 17)
    -- 2: CALL nedestående PROCEDURE med korrekte test værdier. Disse vil danne en transaktion med irl dato og tidspunkt fra brugers pc
    -- 3: Tjek igen antal transaktioner (højeste id) med nedestående SELECT. Denne gang vil der være +1 (burde være 18), med  nuværnde dato og tidspunkt

SELECT transakion_id,dato,tidspunkt 			-- 1: 	
FROM transaktion
ORDER BY transakion_id;

CALL køb_drink(1,3,1,0,0,0,0,0,0,0,0,0); 		-- 2:

SELECT transakion_id,dato,tidspunkt 			-- 3:
FROM transaktion
ORDER BY transakion_id; 

