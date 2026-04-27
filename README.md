Formålet med denne fil er at forklare, hvordan vi gerne vil have databasen vist.

Hvis du vil opsætte vores database, så kan du blot copy-paste hele database_setup.sql ind i workbench og lægge den op på din server.
BEMÆRK! De første linjer dropper allerede tilstedeværende "kaffemaskine" database(r), så hvis du har en database i gang selv, eller én database fra de andre grupper, så vær opmærksom hvis du vil undgå at miste data.

database_setup.sql laver tables, opsætter vores automation og indsætter noget historie i kaffemaskinen, så du har nogle transaktioner og værdier at kigge på.

Ude i main repositoriet, finder du nogle forskellige test filer, som er vores forslag til hvordan du kan teste koden, hvis du har lyst til det. 
Disse inkluderer de af opgaven udspecificerede 3 tests, men også andre tests.

Arbejds mappen er mappen vi har arbejdet i. Her findes de individuelle filer til dannelsen af entities, triggers og procedurer, samt injection data. Det er disse filer der er samlet i database_setup, men vi har beholdt de gamle filer, fordi de er nemmere at kigge igennem når man vil zoome ind, fremfor at have det store billede.


Vi håber du nyder at teste databasen, mere end vi har nydt at lave den