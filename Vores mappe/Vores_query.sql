-- Laver lige drinks alter

CREATE TABLE drink(
drink_id int not null, 
navn char(25) not null,
mælk_forbrug int not null, 
vand_forbrug int not null, 
primary key(drink_id)
);

CREATE TABLE ansat(
medarbejder_id int not null,
navn		char(25) not null,
efternavn	char(25) not null,
stilling 	char(25) not null,	
brugernavn 	char(25) not null,
kodeord 	char(25) not null,
adgangstilladelse bool not null,
primary key(medarbejder_id)
);


CREATE TABLE ansat(
medarbejder_id int not null,
navn		char(25) not null,
efternavn	char(25) not null,
stilling 	char(25) not null,	
brugernavn 	char(25) not null,
kodeord 	char(25) not null,
adgangstilladelse bool not null,
primary key(medarbejder_id)
);


CREATE TABLE rengøring(
rengøring_id 		int not null,
medarbejder_id		char(25) not null,
dato	 			date not null,
primary key(medarbejder_id)
);


CREATE TABLE lager(
    lager_id        int not null,
    opfyldning_id   int not null,
    antal_200kr     int not null,
    antal_100kr     int not null,
    antal_50kr      int not null,
    antal_20kr      int not null,
    antal_10kr      int not null,
    antal_5kr       int not null,
    antal_2kr       int not null,
    antal_1kr       int not null,
    antal_50ører    int not null,
    mængde_kaffe    int not null,
    mængde_mælk     int not null,
    maks_kaffe      int not null,
    maks_mælk       int not null,
    primary key(lager_id)
);




