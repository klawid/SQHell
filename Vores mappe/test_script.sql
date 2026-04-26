-- ================================================================================
-- Test filen
-- Brug denne fil for at sætte gang i databasen, dens entities og dens automation
-- ================================================================================
DROP DATABASE IF EXISTS kaffemaskine;
CREATE DATABASE kaffemaskine;
USE kaffemaskine;

SOURCE entities_setup.sql;
SOURCE triggers_procedures.sql;
SOURCE injecting_query.sql;