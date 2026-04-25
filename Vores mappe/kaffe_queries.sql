


-- 		NEMME/TRÆNINGS OPGVAER 

-- Vis navn på medarbejdere 

SELECT medarbejder_id, navn,efternavn 
FROM ansat; 

-- Find lager historik 
	-- Code

-- Get lager status (hvad er der på nuværende tidspunkt?) 
	-- Code
    



-- MUST/MERE KOMPLICEREDE OPGAVER

-- Liste af alle transaktioner: Alle transaktioner med en bestemt drink

SELECT transakion_id, ansat. navn, dato, tidspunkt, drink 

-- Liste af alle transaktioner: Alle transaktioner indenfor et bestemt tidsrum (samme dag? Over flere dage) 

-- Daglig forbrug 
		-- Code
        
-- (ikke helt denne, men god at have med) Liste af alle transaktioner: Alle transaktioner indenfor af en bestemt person 


-- =====================================================================
-- 04_queries.sql
-- Demonstrationsqueries for kaffemaskine-databasen.
-- Opfylder de tre påkrævede queries fra opgavebeskrivelsen.
-- =====================================================================

USE kaffemaskine;


-- ---------------------------------------------------------------------
-- QUERY 1: Transaktioner — filtrerbar efter tidsrum, drink, betalingstype
-- ---------------------------------------------------------------------
-- Brug NULL i en filter-variabel for "alle". Sæt en værdi for at filtrere.
-- Eksemplerne nedenfor demonstrerer forskellige kombinationer.
-- ---------------------------------------------------------------------

-- EKSEMPEL 1a: ALLE transaktioner (ingen filtre)
SET @fra_dato       = NULL;
SET @til_dato       = NULL;
SET @drink_id       = NULL;
SET @betalingstype  = NULL;

SELECT t.transakion_id,
       t.dato,
       t.tidspunkt,
       CONCAT(a.navn, ' ', a.efternavn)              AS medarbejder,
       d.navn                                        AS drink,
       d.pris                                        AS pris,
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


-- EKSEMPEL 1b: Kun transaktioner i februar 2026
SET @fra_dato       = '2026-02-01';
SET @til_dato       = '2026-02-28';
SET @drink_id       = NULL;
SET @betalingstype  = NULL;

SELECT t.transakion_id, t.dato, t.tidspunkt,
       CONCAT(a.navn, ' ', a.efternavn) AS medarbejder,
       d.navn AS drink, d.pris,
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
SET @fra_dato       = NULL;
SET @til_dato       = NULL;
SET @drink_id       = 3;
SET @betalingstype  = 1;

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

-- 2a: Ingredienser (kaffe, mælk) med fyldningsgrad i procent
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


-- ---------------------------------------------------------------------
-- QUERY 3: Rengøringshistorik
-- ---------------------------------------------------------------------

SELECT r.rengøring_id,
       r.dato,
       CONCAT(a.navn, ' ', a.efternavn) AS udført_af,
       a.stilling
  FROM rengøring r
  JOIN ansat a ON r.medarbejder_id = a.medarbejder_id
 ORDER BY r.dato;



