DROP DATABASE IF EXISTS kaffemaskine;
CREATE DATABASE kaffemaskine;
USE kaffemaskine;

SOURCE entities_setup.sql;
SOURCE triggers_procedures.sql;
SOURCE injection_query.sql;