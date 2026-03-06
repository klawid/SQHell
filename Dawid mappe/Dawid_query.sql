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


CREATE TABLE transaktion(
indbetaling int not null,
betalingstype		char(25) not null,
byttepenge	float not null,
dato 	date not null,	
tidspunkt 	time not null,
primary key(medarbejder_id)
foreign key (medarbejder_id) references ansat(medarbejder_id)
foreign key (drink_id) references drink(drink_id)
foreign key (lager_id) references lager(lager_id)
);



