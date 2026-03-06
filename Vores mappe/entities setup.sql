-- Laver lige drinks alter

CREATE TABLE drink(
drink_id int not null, 
navn char(25) not null,
kaffe_forbrug_kg int not null,
mælk_forbrug_ml int not null, 
vand_forbrug_ml int not null, 
pris int not null, 
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


CREATE TABLE rengøring(
rengøring_id 		int not null,
medarbejder_id		int not null,
dato	 			date not null,
primary key(rengøring_id),
foreign key (medarbejder_id) references ansat(medarbejder_id)
);


CREATE TABLE opfyldning(
opfyldning_id 			int not null,
medarbejder_id			int not null,
opfyldning_kaffe		int not null,
opfyldning_mælk			int not null,
opfyldning_kontanter	int not null,
dato					date not null,	
tidspunkt				TIME not null,
primary key(opfyldning_id ),
foreign key (medarbejder_id) references ansat(medarbejder_id)
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
    primary key(lager_id),
    foreign key (opfyldning_id) references opfyldning(opfyldning_id)
);

CREATE TABLE transaktion(
transakion_id			int not null,
medarbejder_id			int not null,
drink_id				int not null,
lager_id  				int not null,
indbetaling 			int not null,
betalingstype			char(25) not null,
byttepenge				float not null,
dato 					date not null,	
tidspunkt 				time not null,
primary key(transakion_id),
foreign key (medarbejder_id) references ansat(medarbejder_id),
foreign key (drink_id) references drink(drink_id),
foreign key (lager_id) references lager(lager_id)
);

CREATE TABLE daglig_forbrug(
forbrug_id			int not null,
transakion_id		int not null,
sum_kaffe			int not null,
sum_mælk			int not null,
sum_vand			int not null,
primary key(forbrug_id),
foreign key (transakion_id) references transaktion(transakion_id)
);





-- Lille ændring

