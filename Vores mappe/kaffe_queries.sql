
-- ---------------------------------------------------------------------
-- QUERY 1: Transaktioner — filtrerbar efter tidsrum, drink, betalingstype
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
-- QUERY 2: Lagerstatus — nuværende beholdning
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



