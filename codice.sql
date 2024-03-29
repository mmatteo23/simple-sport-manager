/* ---------------------------- */
/* --------- BUILD DB --------- */
/* ---------------------------- */

drop table if exists associazione CASCADE;
drop table if exists campo CASCADE;
drop table if exists citta CASCADE;
drop table if exists contratti CASCADE;
drop table if exists dipendente CASCADE;
drop table if exists esborsi CASCADE;
drop table if exists fatture CASCADE;
drop table if exists fornitore CASCADE;
drop table if exists grado_dipendenti CASCADE;
drop table if exists pagamento CASCADE;
drop table if exists prenotazioni CASCADE;
drop table if exists sede CASCADE;
drop table if exists stipendi CASCADE;
drop table if exists tesserato CASCADE;
drop table if exists tipologia_campo CASCADE;

DROP TYPE IF EXISTS sessi, operazioni;
CREATE TYPE sessi 		AS ENUM ('M', 'F');
CREATE TYPE operazioni 	AS ENUM ('F', 'S', 'E');

CREATE TABLE Associazione (
	codice 		varchar(20),
	ragsoc 		varchar(80) NOT NULL,
	sito		varchar(150) NOT NULL,
	email		varchar(80) NOT NULL check (email like '%_@__%.__%'),
	password 	varchar(50) NOT NULL,
	PRIMARY KEY(codice)
);

CREATE TABLE Tesserato (
	codass					varchar(20),
	cf						char(16),
	nome					varchar(80) NOT NULL,
	cognome					varchar(80) NOT NULL,
	data_nascita			date NOT NULL,
	email					varchar(80) NOT NULL check (email like '%_@__%.__%'),
	password				varchar(50) NOT NULL,
	telefono				varchar(12), /* con 12 caratteri prendiamo quasi la totalità dei numeri */
	arbitro					bool DEFAULT false,
	data_iscrizione			date NOT NULL,
	scadenza_iscrizione		date NOT NULL,
	sesso 					sessi NOT NULL,
	PRIMARY KEY(codass, cf),
	FOREIGN KEY (codass) REFERENCES Associazione(codice)
);

CREATE TABLE Citta (
	istat			char(6),
	cap				char(5) NOT NULL,
	nome			varchar(100) NOT NULL,
	provincia		char(2) NOT NULL,
	regione			char(3) NOT NULL,
	PRIMARY KEY (istat)
);

CREATE TABLE Sede (
	codass			varchar(20),
	codice			int,
	via				varchar(150) NOT NULL,
	cod_civico 		int NOT NULL,
	cod_citta		char(6) NOT NULL,
	nome			varchar(150) NOT NULL,
	telefono		varchar(12),
	PRIMARY KEY (codass, codice),
	FOREIGN KEY (codass) 		REFERENCES Associazione(codice),
	FOREIGN KEY (cod_citta)		REFERENCES Citta(istat)
);

CREATE TABLE Fornitore (
	piva				char(11),
	ragione_soc			varchar(150) NOT NULL,
	email				varchar(80) NOT NULL check (email like '%_@__%.__%'),
	telefono			varchar(12),
	PRIMARY KEY (piva)
);

CREATE TABLE contratti (
	codass				varchar(20),
	cod_fornitore		char(11),
	data_inizio			date NOT NULL,
	data_fine			date, /* NULL fino alla chiusura del contratto => senza un rinnovo */
	PRIMARY KEY (codass, cod_fornitore),
	FOREIGN KEY (codass) REFERENCES Associazione(codice),
	FOREIGN KEY (cod_fornitore) REFERENCES Fornitore(piva)
);

CREATE TABLE tipologia_campo (
	codass			varchar(20),
	id				int,
	sport			varchar(50), /* NULL = campo generico */
	terreno			varchar(50) NOT NULL,
	larghezza		smallint NOT NULL check (larghezza > 0), /* misure espresse in metri */
	lunghezza		smallint NOT NULL check (lunghezza > 0),
	PRIMARY KEY (codass, id),
	FOREIGN KEY (codass)	REFERENCES Associazione(codice)
);

CREATE TABLE Campo (
	codass			varchar(20),
	id				int,
	cod_sede		int,
	tipologia		int NOT NULL,
	attrezzatura	bool DEFAULT false,
	PRIMARY KEY (codass, id, cod_sede),
	FOREIGN KEY (codass, cod_sede) REFERENCES Sede(codass, codice),
	FOREIGN KEY (codass, tipologia)	REFERENCES tipologia_campo(codass, id)
);

CREATE TABLE prenotazioni (
	codass			varchar(20),
	id_campo		int,
	sede			int,
	id_tesserato	char(16) NOT NULL,
	data			timestamp NOT NULL,
	ore				decimal(2,1) NOT NULL, /* Si possono prenotare solo ore o mezz'ore (mezz'ora = 0.5) */
	arbitro			bool DEFAULT false,
	PRIMARY KEY (codass, id_campo, sede, data),
	FOREIGN KEY (codass, id_campo, sede) REFERENCES Campo(codass, id, cod_sede)
);

CREATE TABLE grado_dipendenti (
	id				int,
	descrizione		varchar(50) NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE Dipendente (
	codass				varchar(20),
	cf					char(16),
	nome				varchar(80) NOT NULL,
	cognome				varchar(80) NOT NULL,
	sesso				sessi NOT NULL,
	data_nascita		date NOT NULL,
	email				varchar(80) NOT NULL check (email like '%_@__%.__%'),
	password			varchar(50) NOT NULL,
	telefono			varchar(12),
	grado				int NOT NULL,
	data_assunzione 	date NOT NULL,
	data_fine			date, /* if IS NOT NULL => licenziato/pensione */
	cod_sede			int NOT NULL,
	PRIMARY KEY (codass, cf),
	FOREIGN KEY (codass)			REFERENCES Associazione(codice),
	FOREIGN KEY (codass, cod_sede)	REFERENCES Sede(codass, codice),
	FOREIGN KEY (grado)				REFERENCES grado_dipendenti(id)
);

CREATE TABLE Pagamento (
	codass        		varchar(20),
	data        		timestamp,
	id_dipendente    	char(16),
	importo        		money NOT NULL,
	tipo_operazione    	operazioni NOT NULL,
	check (((tipo_operazione='S' or tipo_operazione='E') and importo::numeric < 0) or (tipo_operazione = 'F' and importo::numeric <> 0)),
	PRIMARY KEY (codass, data, id_dipendente), /* codass in chiave per via del licenziamento */
	FOREIGN KEY (codass, id_dipendente) REFERENCES Dipendente(codass, cf)
);
/*
	tipo_operazione:
		F => Fattura
		S => Stipendio
		E => Esborso
*/

CREATE TABLE stipendi (
	codass				varchar(20),
	data				timestamp,
	id_dipendente		char(16),
	soggetto			char(16),		
	PRIMARY KEY (codass, data, id_dipendente, soggetto),
	FOREIGN KEY (codass, data, id_dipendente) REFERENCES Pagamento(codass, data, id_dipendente),
	FOREIGN KEY (codass, soggetto) REFERENCES Dipendente(codass, cf)
);

CREATE TABLE fatture (
	codass				varchar(20),
	data				timestamp,
	id_dipendente		char(16),
	tesserato			char(16) NOT NULL, /* Arbitro o Atleta */
	descrizione			varchar(255),
	progressivo			int check(progressivo > 0),
	PRIMARY KEY (codass, data, id_dipendente, progressivo),
	FOREIGN KEY (codass, data, id_dipendente) REFERENCES Pagamento(codass, data, id_dipendente),
	FOREIGN KEY (codass, tesserato) REFERENCES Tesserato(codass, cf)
);

CREATE TABLE esborsi (
	codass				varchar(20),
	data				timestamp,
	id_dipendente		char(16),
	id_fornitore		char(16) NOT NULL,
	descrizione			varchar(255),
	PRIMARY KEY (codass, data, id_dipendente, id_fornitore),
	FOREIGN KEY (codass, data, id_dipendente) REFERENCES Pagamento(codass, data, id_dipendente),
	FOREIGN KEY (id_fornitore) REFERENCES Fornitore(piva)
);

/* ------------------------------- */
/* --------- INSERT DATA --------- */
/* ------------------------------- */

/* Popolamento associazioni */
INSERT INTO associazione (codice, ragsoc, sito,	email, password)
VALUES
('POLRM', 'Polisportiva Romana', 'polisportivaromana.it', 'info@polisportivaromana.it', 'polisportiva01'),
('JSDB', 'Jesolo San Donà Basket', 'jesolosandonabasket.it', 'info@jsdb.it', 'basket01'),
('CAME', 'Calciatori Mestrini', 'calciomestre.it', 'info@calciomestre.it', 'calcio01'),
('TCPG', 'Tennis Club Portogruaro', 'portogruarotc.it', 'info@pgtc.it', 'tennis01');

/* Popolamento Tesserati */
INSERT INTO tesserato(
codass, cognome, nome, sesso, data_nascita, cf, telefono, email, password, arbitro, data_iscrizione, scadenza_iscrizione)
VALUES 
('JSDB', 'Bonanno', 'Vanda','F','2005-12-31','BNNVND05T71H975W','095/311606','vanda.bonanno@gmail.com','FW93lafaR73G', true, '15/04/2020', '15/04/2022'),
('CAME', 'Biamonte', 'Ondina', 'F', '1969-11-02', 'BMNNDN69S42E423C', '0471/233174', 'ondina.biamonte@gmail.com','XP30mbswL17D', false, '13/10/2019', '13/10/2021'),
('CAME', 'Lattes', 'Cirillo', 'M', '2009-06-20', 'LTTCLL09H20I721H', '0437/888443', 'ciri.latt@libero.it', 'OU57rxvfW86S', false, '14/05/2016', '14/05/2020'),
('CAME', 'Barbon', 'Edvige' , 'F', '1969-11-07', 'BRBDVG69S47B332F', '0932/537114', 'edvi.barb@gmail.com', 'DA84zmrjJ02D', false, '25/03/2018', '25/03/2022'),
('POLRM', 'Lilli', 'Manfredo', 'M', '2013-09-28', 'LLLMFR13P28E390F', '0425/681360', 'm.lilli@teletu.it', 'SV10sodsW95S', false, '13/12/2020', '13/12/2022'),
('POLRM', 'Farronato', 'Zaira', 'F', '1972-05-02', 'FRRZRA72E42E530Z', '0984/236359', 'zaira.farronato@gmail.it', 'EU26buhuR22S', false, '13/12/2020', '13/12/2022'),
('JSDB', 'Tosin','Adelaide','F','1999-05-14','TSNDLD99E54C998K','051/1039499','adelaide.tosin@katamail.it','TJ50rpzrS28Q', false, '03/03/2021', '03/03/2021'),
('JSDB','De Fuschi','Lelia','F','1973-06-03','DFSLLE73H43G184K','0861/185764','lelia.defuschi@gmail.com','EI36vfqfX77R', true, '14/08/2005', '14/08/2008'),
('POLRM','Tessaroli','Giosuè','M','1973-06-28','TSSGSI73H28G190O','030/877912','giosu.tessaroli@tiscali.it','CA19sxssG11N', false, '25/03/2007', '25/03/2021'),
('CAME','Lubatti','Lucia','F','1956-06-13','LBTLCU56H53C659Q','0783/597945','lucia.lubatti@hotmail.com','RX43nuljK66O', false, '26/11/2016', '26/11/2021'),
('JSDB','Berisso','Sveva','F','2013-10-19','BRSSVV13R59C631F','0823/453009','sveva.berisso@gmail.it','UT20qvhkF22K', false, '15/07/2021', '15/07/2022'),
('JSDB','Terenzi','Pierluigi','M','2000-03-21','TRNPLG00C21B166C','0984/550396','pierluigi.terenzi@virgilio.it','TO37zfmkK45H', false, '15/07/2021', '15/07/2022'),
('CAME','Bernasconi','Omero','M','1973-09-22','BRNMRO73P22G619O','0733/104205','omero.bernasconi@teletu.it','XT61tpyuH60X', false, '15/07/2021', '15/07/2022'),
('JSDB','Bertolli','Bruto','M','2009-01-23','BRTBRT09A23A261M','02/1048133','bruto.bertolli@teletu.it','EI01lvzhA06G', true, '15/07/2021', '15/07/2022'),
('POLRM','Peppe','Celso','M','1973-12-25','PPPCLS73T25L810W','011/1090772','celso.peppe@katamail.it','KD13itfqD85J', false, '03/03/2021', '03/03/2023'),
('CAME','Minelli','Filomena','F','1975-05-25','MNLFMN75E65E976M','045/247375','filo.mine@yahoo.it','PX47maioZ32M', false, '03/03/2021', '03/03/2023'),
('JSDB','Gaucci','Siro','M','1985-05-24','GCCSRI85E24A067U','0376/1048271','siro.gaucci@tiscali.it','SY97zcwyQ86X', false, '03/03/2021', '03/03/2023'),
('JSDB','Massarenti','Renata','F','1992-12-19','MSSRNT92T59H534R','0761/311992','renata.massarenti@libero.it','DM89rzfkY86M', false, '15/01/2009', '15/01/2021'),
('CAME','Boero','Sibilla','F','1987-03-19','BROSLL87C59A562M','0161/399955','sibilla.boero@gmail.it','LT57bbgcT60S', true, '14/01/2003', '14/01/2021'),
('JSDB','Morocutti','Vilma','F','2017-07-06','MRCVLM17L46B131H','0432/656364','vilma.morocutti@teletu.it','FJ53stjuH42L', false, '25/02/2018', '25/02/2019'),
('JSDB','Retusi','Ezechiele','M','2002-03-15','RTSZHL02C15B984X','0775/154789','ezechiele.retusi@virgilio.it','GR69vdxqX31R', false, '13/01/2019', '13/04/2019'),
('CAME','Moncada','Brando','M','2012-02-06','MNCBND12B06A227X','0522/605708','bran.monc@tin.it','AG76yqnqH97Z', false, '20/04/2021', '20/04/2022'),
('JSDB','Camosso','Demetrio','M','1983-10-11','CMSDTR83R11H743Z','0161/871364','deme.camo@gmail.com','SX26qbfcB27Q', false, '20/04/2021', '20/08/2021'),
('CAME','Gabriel','Amilcare','M','1953-10-06','GBRMCR53R06D703U','0161/849694','amil.gabr@katamail.it','DK67bsvcT88U', true, '05/05/2017', '05/05/2018'),
('POLRM','Antonicello','Annagrazia','F','1956-04-15','NTNNGR56D55D668J','035/906471','a.antonicello@tin.it','PP61pxxdV09N', false, '07/12/2021', '07/12/2023'),
('JSDB','Berard','Eros','M','1983-05-17','BRRRSE83E17E630A','0461/706585','eros.berard@katamail.it','TL06glbwE09A', false, '12/9/2012', '12/9/2013'),
('JSDB','Galiani','Norina','F','1943-03-25','GLNNRN43C65D398Y','0783/410414','norina.galiani@tin.it','GI52fyhnH18W', true, '03/03/1999', '03/03/2005'),
('POLRM','Barone','Noemi','F','2012-08-31','BRNNMO12M71E893S','06/833110','noem.baro@aruba.it','MU06xljzJ94G', false, '03/03/2021', '03/03/2022'),
('CAME','Lange','Emanuele','M','1980-07-13','LNGMNL80L13C387K','0524/865784','emanuele.lange@yahoo.com','GA28euvzV87I', false, '03/03/2021', '03/03/2023'),
('POLRM', 'Raimondo', 'Pantelli', 'M','1984-04-30','PNTRND84D30H108A','0824/1009494','raimondo.pantelli@yahoo.com','JN83lxzdV76Z', false, '12/06/2018', '12/06/2020'),

('TCPG','Sabbatelli','Mirko','M','2000-11-19','SBBMRK17S19F961M','035/539737','mirko.sabbatelli@virgilio.it','UA90vjatO35R',false,' 31/12/2020',' 11/05/2022'),
('TCPG','Mazzolini','Ulrico','M','1995-01-26','MZZLRC35A26A038K','0372/213476','ulrico.mazzolini@hotmail.com','GK40okdlP09V',true,' 22/10/2019',' 08/07/2022'),
('TCPG','Vargiu','Daniele','M','1990-08-19','VRGDNL10M19E727A','02/1067185','daniele.vargiu@tele2.it','ZE21ovjuU79O',false,' 29/06/2020',' 08/07/2022'),
('TCPG','Maragnano','Decimo','M','1982-02-01','MRGDCM12B01H242P','02/793234','deci.mara@yahoo.it','BL18lbfiE35Q',true,' 23/09/2019',' 11/05/2022'),
('TCPG','Cavioni','Marinella','F','1981-08-23','CVNMNL81M63L817G','035/258064','marinella.cavioni@tele2.it','WQ64hhbeQ06E',false,' 14/08/2020',' 29/08/2023'),
('TCPG','Guglielmetti','Mosè','M','1996-06-24','GGLMSO96H24A444K','089/948950','mos.guglielmetti@teletu.it','PN40iozpL49Z',false,' 31/12/2020',' 07/12/2022'),
('TCPG','Fioravanzi','Loris','M','1981-10-12','FRVLRS81R12I482L','0372/1039860','lori.fior@tiscali.it','BN74tlzaR29W',false,' 15/12/2020',' 21/02/2022'),
('TCPG','Iaconelli','Tamara','F','1971-04-11','CNLTMR61D51L238M','055/753391','tama.iaco@hotmail.com','ZO24zppuM66V',true,'01/01/2019','14/01/2022'),
('TCPG','Gattinara','Orsola','F','1992-10-03','GTTRSL02R43H939G','085/861691','orsola.gattinara@gmail.com','LJ35bocpF51T',false,' 28/10/2019',' 23/11/2023'),
('TCPG','Altinier','Pia','F','1996-08-22','LTNPIA36M62H414P','080/644749','pia.altinier@tiscali.it','HU72tpcdE75N',true,' 17/09/2019',' 06/07/2022');


/* Popolamento Sedi */
INSERT INTO sede (codass, codice, via, cod_civico, cod_citta, nome, telefono)
VALUES
('CAME', 1, 'Via E.Ponti', 28, '27042', 'Sede Pulcini Calcio Mestre', '045/570483'),
('CAME', 2, 'Via Antonio Vallisneri', 43, '27042', 'Sede Calcio Mestre', '0141/1004036'),
('JSDB', 1, 'Via Iseo', 2, '27033', 'Jesolo San Donà Basket', '0421/5567423'),
('JSDB', 2, 'Via Tredici Martiri', 15, '27027', 'Jesolo San Donà Basket (Noventa)', '0421/5564472'),
('POLRM', 1, 'Viale Tevere', 96, '58104', 'Polisportiva Roma (Tivoli)', '0564/803071');

INSERT INTO sede (codass, codice, via, cod_civico, cod_citta, nome, telefono)
VALUES
('TCPG', 1, 'Via Alberti', 72, '27029', 'Tennis Club Portogruaro', '0564/803071'),
('TCPG', 2, 'Via Verdi', 43, '27029', 'Tennis Club Portogruaro (Portovecchio)', '0564/378254'),
('CAME', 3, 'Via Arnaldo Giacomini', 17, '27042', 'Sede Calcio Mestre (Nuova)', '0141/1554736');

/* Popolamento fornitori */
INSERT INTO fornitore (piva, ragione_soc, email, telefono)
VALUES
('06500120016', 'Molten Italia', 'd.carta@advanced-distribution.com', '0118005901'),
('05126523875', 'Wilson Italia', 'info@wilson.com', '3345879854'),
('07762523875', 'Adidas', 'd.prod@adidas.com', '3645479884'),
('04512794513', 'Nike', 'd.prod@nike.com', '0645446914'),
('06456486415', 'Babolat Italia', 'support@babolat.it', '3347541878'),
('08794512358', 'ATP', 'info@atp.com', '3985623145');

/* Registrazioni contratti */
INSERT INTO contratti (codass, cod_fornitore, data_inizio)
VALUES
('JSDB', '06500120016', '23/03/2005'),
('JSDB', '05126523875', '12/09/2009'),
('CAME', '06500120016', '5/06/2009'),
('CAME', '04512794513', '5/06/2007'),
('POLRM', '05126523875', '25/10/2015'),
('POLRM', '06500120016', '5/08/2015'),
('POLRM', '04512794513', '13/06/2015'),
('TCPG', '05126523875', '13/06/2020'),
('TCPG', '06456486415', '3/02/2017'),
('TCPG', '08794512358', '22/09/2016');

/* Specifiche sulla gerarchia dei dipendenti */
INSERT INTO grado_dipendenti
VALUES
(10, 'Segreteria'),
(20, 'Responsabile'),
(30, 'Amministrazione');

/* Popolamento dipendenti */ 
INSERT INTO dipendente (codass, cognome, nome, sesso, data_nascita, cf, telefono, email, password, grado, data_assunzione, data_fine, cod_sede)
VALUES
('JSDB', 'Bertugli','Giovanna','F','1998-09-05','BRTGNN98P45C524P','0376/270098','giovanna.bertugli@gmail.com','BQ88vibxC77P', 10, '2012-12-15', NULL, 1),
('POLRM', 'Musumeci','Aristotele','M','1997-10-11','MSMRTT97R11C661I','0131/640624','amusumeci@gmail.com','RR90vaugW52R', 20, '2013-11-16', NULL, 1),
('CAME', 'Sacchino','Tancredi','M','1993-08-24','SCCTCR93M24L183J','0721/319561','tancredi.sacchino@gmail.com','HK49hsubV04U', 10, '2014-9-25', NULL, 1),
('JSDB', 'Trapattoni','Emilio','M','1988-06-02','TRPMLE88H02L696X','0437/824923','etrapattoni@gmail.com','YM40btbiT75H', 30, '2015-5-14', NULL, 2),
('JSDB', 'Gabriele','Clelia','F','1996-05-25','GBRCLL96E65F726F','011/664877','clel.gabr@gmail.com','KR96xwrdB91C', 10, '2016-6-23', NULL, 2),
('JSDB', 'Coloso','Enrica','F','1993-11-29','CLSNRC93S69H949L','031/966744','enri.colo@gmail.com','DD81pfgbS30N', 20, '2017-7-9', NULL, 2),
('POLRM', 'Folletti','Angela','F','1991-10-17','FLLNGL91R57E148Q','0141/641067','angela.folletti@gmail.com','JL25jtouC34I', 30, '2018-2-14', NULL, 1),
('CAME', 'Baracco','Gastone','M','1993-01-23','BRCGTN93A23A193B','0131/963721','gastone.baracco@gmail.com','ID41kcaeC65C', 10, '2019-3-8', NULL, 2),
('JSDB', 'Fineschi','Antonio','M','1986-10-26','FNSNTN86R26I968A','0932/830244','antonio.fineschi@gmail.com','ZB86fbwvD06V', 20, '2013-4-28', NULL, 2),
('CAME', 'Piccinino','Camilla','F','1998-09-01','PCCCLL98P41G276S','0934/811002','camilla.piccinino@gmail.com','CU87lwgoC12Q', 30, '2014-5-29', NULL, 1),
('JSDB', 'Ansalone','Sandra','F','1989-10-10','NSLSDR89R50L319K','011/953432','sand.ansa@gmail.com','MK91ihgtJ67O', 10, '2015-1-15', NULL, 1),
('JSDB', 'Antacido','Lea','F','2000-04-12','NTCLEA00D52F486P','0382/1020624','lea.antacido@gmail.com','QN08wsarN16A', 20, '2016-8-1', NULL, 2),
('CAME', 'Demattio','Giuda','M','1994-11-09','DMTGDI94S09E669C','0934/589832','giuda.demattio@gmail.com','NO89cobaY12S', 30, '2017-9-17', NULL, 1),
('POLRM', 'Albricci','Emiliana','F','1988-02-12','LBRMLN88B52A690A','035/964080','emil.albr@gmail.com','NY96oseyG00J', 10, '2018-6-18', NULL, 1),
('JSDB', 'Taiani','Giacomo','M','1987-08-26','TNAGCM87M26M030Z','0743/750731','giacomo.taiani@gmail.com','WF35rodwW27H', 20, '2013-4-5', NULL, 1),
('CAME', 'Molignani','Giovanna','F','1987-09-21','MLGGNN87P61D688H','091/942269','giovanna.molignani@gmail.com','JJ00dqveM82K', 30, '2014-7-6', NULL, 2),
('JSDB', 'Rezzoagli','Lea','F','1993-03-04','RZZLEA93C44F385V','0444/641397','lea.rezz@gmail.com','HJ65anksF11C', 10, '2015-4-7', NULL, 1),
('POLRM', 'Bascio','Ercole','M','1988-06-09','BSCRCL88H09G520N','0861/731265','ercole.bascio@gmail.com','QJ69kstgO17I', 20, '2014-4-8', NULL, 1),
('JSDB', 'Bebbo','Alfredo','M','1994-05-18','BBBLRD94E18F315Z','0871/887969','alfredo.bebbo@gmail.com','VX19xxkqW61V', 30, '2014-3-9', NULL, 1),
('CAME', 'Luzardi','Cornelio','M','1985-06-01','LZRCNL85H01B595R','0881/893745','corn.luza@gmail.com','UE41vppaU07O', 10, '2013-11-10', '2020-08-12', 2),
('JSDB', 'Garzelli','Ancilla','F','1985-10-20','GRZNLL85R60C685E','0382/567014','a.garzelli@gmail.com','IW32qazgV86A', 20, '2017-12-11', NULL, 1),
('JSDB', 'Ponzoni','Caino','M','1987-01-24','PNZCNA87A24M060P','045/351924','caino.ponzoni@gmail.com','CP30chieO96O', 30, '2016-4-12', NULL, 2),
('POLRM', 'Andideri','Maddalena','F','1999-12-22','NDDMDL99T62F762S','0831/921349','m.andideri@gmail.com','ED83rksfM45Y', 10, '2015-3-13', NULL, 1),
('JSDB', 'Solero','Modesto','M','2000-01-07','SLRMST00A07F769M','0161/811356','modesto.solero@gmail.com','KZ92gqqfA39L', 20, '2013-11-14', NULL, 2),
('CAME', 'Gangi','Nereo','M','1995-12-21','GNGNRE95T21G382G','0372/448135','nereo.gangi@gmail.com','UP17rhehD68F', 30, '2020-10-15', NULL, 1),
('POLRM', 'Polucci','Fabiola','F','1997-09-11','PLCFBL97P51F651S','0165/534849','f.polucci@gmail.com','EZ51smbtO20O', 10, '2021-10-16', NULL, 1),
('JSDB', 'Grispo','Marta','F','1989-05-13','GRSMRT89E53G048G','0784/341544','marta.grispo@gmail.com','ON95gsugX20Y', 20, '2020-7-17', NULL, 1),
('CAME', 'Laviano','Alba','F','1986-07-18','LVNLBA86L58F216F','0372/350332','alba.laviano@gmail.com','GT63rocrF92R', 30, '2019-8-18', NULL, 2),
('POLRM', 'Poli','Tolomeo','M','1995-09-23','PLOTLM95P23F717I','011/651116','tolomeo.poli@gmail.com','ZQ93svkiD41L', 10, '2018-9-19', NULL, 1),
('CAME', 'Fanellagia','Raffaele','M','2000-07-20','FNLRFL00L58F216F','346/2536454','rafanellagia@gmail.com','bmwfanelz00', 20, '2019-7-20', NULL, 2),

('TCPG','Carobbio','Baldassarre','M','1985-08-15','CRBBDS85M15E507I','0736/659335','bald.caro@hotmail.com','UL62fzqlR36O',10,' 28/12/2015',' 12/10/2022',1),
('TCPG','Fugazzi','Arnaldo','M','2000-10-30','FGZRLD00R30H395L','0543/193304','arnaldo.fugazzi@gmail.com','UD65smjwZ09G',20,' 02/08/2012',' 23/08/2017',2),
('TCPG','Onofrio','Adriana','F','1989-10-19','NFRDRN89R59L535D','049/721393','adriana.onofrio@gmail.com','JX23zfdtI23O',30,' 24/11/2016',' 18/07/2019',1),
('TCPG','Petrazzuolo','Dante','M','1994-07-06','PTRDNT94L06G428W','0382/1051382','d.petrazzuolo@gmail.com','AI29ycsnN64G',10,' 28/12/2015',' 14/11/2017',2),
('TCPG','Amedei','Minerva','F','1991-02-26','MDAMRV91B66C187D','0984/286769','minerva.amedei@libero.it','WU47thmgX16C',20,' 29/06/2015',' 22/09/2017',1),
('TCPG','Quintarelli','Gerardo','M','1998-03-08','QNTGRD98C08F655L','049/971795','g.quintarelli@tele2.it','UK26cmfsN62K',30,' 29/06/2015',' 22/09/2017',2),
('TCPG','Minozzi','Omero','M','1997-11-22','MNZMRO97S22M119N','0523/214353','omero.minozzi@tiscali.it','EL04hebjP68A',10,' 21/03/2014',' 22/09/2017',1),
('TCPG','Meloncelli','Margherita','F','1983-08-26','MLNMGH83M66B204D','011/558535','margherita.meloncelli@yahoo.com','QO60mdehP30Z',20,' 07/05/2014',' 24/08/2022',2),
('TCPG','Arbizzani','Ferdinando','M','2001-07-23','RBZFDN01L23F918O','035/812848','ferdinando.arbizzani@lycos.it','UY60kdlrQ49Q',30,' 07/10/2015',' 28/01/2021',1),
('TCPG','Tagliafierro','Romolo','M','1991-05-23','TGLRML91E23D578W','035/125471','romolo.tagliafierro@gmail.com','HE87dnjnA83N',10,' 07/02/2013',' 22/09/2017',2);

INSERT INTO tipologia_campo (codass, id, sport, terreno, larghezza, lunghezza)
VALUES
('JSDB', 1, 'Basket', 'parquet', 15, 28),
('JSDB', 2, 'Basket', 'parquet', 14, 27),
('CAME', 1, 'Calcio', 'erba', 90, 120),
('CAME', 2, 'Calcio', 'erba', 65, 105),
('CAME', 3, 'Calcio', 'erba', 60, 100),
('POLRM', 1, 'Calcio', 'erba', 65, 105),
('POLRM', 2, 'Calcio 5', 'gomma', 15, 25),
('POLRM', 3, 'Calcio 5', 'erba sintetica', 22, 42),
('POLRM', 4, 'Calcio 7', 'erba sintetica', 30, 50),
('POLRM', 5, 'Calcio 8', 'erba', 40, 60),
('POLRM', 6, 'Basket', 'parquet', 15, 28),
('POLRM', 7, 'Basket 3', 'gomma', 15, 11),
('TCPG', 1, 'Tennis', 'terra battuta', 11, 24),
('TCPG', 2, 'Tennis', 'erba', 11, 24),
('TCPG', 3, 'Tennis', 'erba sintetica', 11, 24),
('TCPG', 4, 'Tennis', 'cemento', 11, 24);

/*
	Calcio:
		- 65 x 105 (misure minime)
		- 60 x 100 (casi eccezionali)
	Calcio 5:
		- 15 x 25
		- 22 x 42
	Calcio 7:
		- 44-65 delta lunghezza
		- 25-40 delta larghezza
	Calcio 8:
		- 35-45 delta larghezza
		- 55-70 delta lunghezza
		
	Basket 5vs5:
		- 15 x 28
	Basket 3vs3:
		- 15 x 11
		
	Tennis:
		-  8,23 x 23,77 (SINGOLO)
		- 10,97 x 23,77 (DOPPIO)
		
		- superfici:
			terra battuta, terra verde, erba, erba sintetica, cemento, sintetico
			
	Pallavolo:
		- 9 x 18
		
		- terreno:
			parquet, pvc, gomma, sabbia, cemento
*/

INSERT INTO campo (codass, id, cod_sede, tipologia, attrezzatura)
VALUES
('JSDB', 1, 1, 1, true),
('JSDB', 2, 1, 2, true),
('JSDB', 1, 2, 1, true),
('CAME', 1, 1, 2, true),
('CAME', 2, 1, 2, true),
('CAME', 1, 2, 3, true),
('POLRM', 1, 1, 1, true),
('POLRM', 2, 1, 2, true),
('POLRM', 3, 1, 3, true),
('POLRM', 4, 1, 4, true),
('POLRM', 5, 1, 5, true),
('POLRM', 6, 1, 6, true),
('POLRM', 7, 1, 5, true),
('POLRM', 8, 1, 6, true),
('TCPG', 1, 1, 1, true),
('TCPG', 2, 1, 2, true),
('TCPG', 3, 1, 3, true),
('TCPG', 4, 1, 4, true),
('TCPG', 1, 2, 1, true),
('TCPG', 2, 2, 3, true);


INSERT INTO prenotazioni (codass, id_campo, sede, id_tesserato, data, ore, arbitro)
VALUES

('POLRM', 1, 1, 'PPPCLS73T25L810W', '17-05-2020 18:00', 2,true),
('POLRM', 3, 1, 'TSSGSI73H28G190O', '17-05-2020 16:30', 2,false),
('POLRM', 4, 1, 'BRNNMO12M71E893S', '17-05-2020 15:30', 1.5,false),
('POLRM', 4, 1, 'NTNNGR56D55D668J', '17-05-2020 17:30', 2,false),
('POLRM', 3, 1, 'PNTRND84D30H108A', '17-05-2020 18:30', 1,false),
('POLRM', 4, 1, 'FRRZRA72E42E530Z', '17-05-2020 14:30', 2,false),

('POLRM', 1, 1, 'PPPCLS73T25L810W', '20-05-2020 18:00', 2, true),
('POLRM', 3, 1, 'TSSGSI73H28G190O', '20-05-2020 16:30', 2, false),
('POLRM', 4, 1, 'BRNNMO12M71E893S', '20-05-2020 16:30', 1.5, false),
('POLRM', 4, 1, 'NTNNGR56D55D668J', '20-05-2020 18:30', 2, false),
('POLRM', 3, 1, 'PNTRND84D30H108A', '20-05-2020 18:30', 1, false),
('POLRM', 4, 1, 'FRRZRA72E42E530Z', '20-05-2020 14:30', 2, false),

('POLRM', 1, 1, 'PPPCLS73T25L810W', '25-05-2020 18:00', 2, true),
('POLRM', 3, 1, 'TSSGSI73H28G190O', '25-05-2020 16:30', 2, false),
('POLRM', 4, 1, 'BRNNMO12M71E893S', '25-05-2020 15:30', 1.5, false),
('POLRM', 4, 1, 'NTNNGR56D55D668J', '25-05-2020 17:30', 2, false),
('POLRM', 3, 1, 'PNTRND84D30H108A', '25-05-2020 18:30', 1, false),
('POLRM', 4, 1, 'FRRZRA72E42E530Z', '25-05-2020 14:30', 2, false),

('POLRM', 1, 1, 'PPPCLS73T25L810W', '30-05-2020 18:00', 2, true),
('POLRM', 3, 1, 'TSSGSI73H28G190O', '30-05-2020 16:30', 2, false),
('POLRM', 4, 1, 'BRNNMO12M71E893S', '30-05-2020 15:30', 1.5, false),
('POLRM', 4, 1, 'NTNNGR56D55D668J', '30-05-2020 17:30', 2, false),
('POLRM', 3, 1, 'PNTRND84D30H108A', '30-05-2020 18:30', 1, false),
('POLRM', 4, 1, 'FRRZRA72E42E530Z', '30-05-2020 14:30', 2, false),

('POLRM', 1, 1, 'PPPCLS73T25L810W', '10-07-2020 18:00', 2, true),
('POLRM', 3, 1, 'TSSGSI73H28G190O', '10-7-2020 16:30', 2, false),
('POLRM', 4, 1, 'BRNNMO12M71E893S', '10-7-2020 15:30', 1.5, false),
('POLRM', 4, 1, 'NTNNGR56D55D668J', '10-7-2020 17:30', 2, false),
('POLRM', 3, 1, 'PNTRND84D30H108A', '10-7-2020 18:30', 1, false),
('POLRM', 4, 1, 'FRRZRA72E42E530Z', '10-7-2020 14:30', 2, false),

('POLRM', 1, 1, 'PPPCLS73T25L810W', '15-07-2020 18:00', 2, true),
('POLRM', 3, 1, 'TSSGSI73H28G190O', '15-7-2020 16:30', 2, false),
('POLRM', 4, 1, 'BRNNMO12M71E893S', '15-7-2020 15:30', 1.5, false),
('POLRM', 4, 1, 'NTNNGR56D55D668J', '15-7-2020 17:30', 2, false),
('POLRM', 3, 1, 'PNTRND84D30H108A', '15-7-2020 18:30', 1, false),
('POLRM', 4, 1, 'FRRZRA72E42E530Z', '15-7-2020 14:30', 2, false),

('POLRM', 1, 1, 'PPPCLS73T25L810W', '18-07-2020 18:00', 2, true),
('POLRM', 3, 1, 'TSSGSI73H28G190O', '18-7-2020 16:30', 2, false),
('POLRM', 4, 1, 'BRNNMO12M71E893S', '18-7-2020 15:30', 1.5, false),
('POLRM', 4, 1, 'NTNNGR56D55D668J', '18-7-2020 17:30', 2, false),
('POLRM', 3, 1, 'PNTRND84D30H108A', '18-7-2020 18:30', 1, false),
('POLRM', 4, 1, 'FRRZRA72E42E530Z', '18-7-2020 14:30', 2, false),

('POLRM', 1, 1, 'PPPCLS73T25L810W', '22-07-2020 18:00', 2, true),
('POLRM', 3, 1, 'TSSGSI73H28G190O', '22-7-2020 16:30', 2, false),
('POLRM', 4, 1, 'BRNNMO12M71E893S', '22-7-2020 15:30', 1.5, false),
('POLRM', 4, 1, 'NTNNGR56D55D668J', '22-7-2020 17:30', 2, false),
('POLRM', 3, 1, 'PNTRND84D30H108A', '22-7-2020 18:30', 1, false),
('POLRM', 4, 1, 'FRRZRA72E42E530Z', '22-7-2020 14:30', 2, false),

('POLRM', 1, 1, 'PPPCLS73T25L810W', '28-07-2020 18:00', 2, true),
('POLRM', 3, 1, 'TSSGSI73H28G190O', '28-7-2020 16:30', 2, false),
('POLRM', 4, 1, 'BRNNMO12M71E893S', '28-7-2020 15:30', 1.5, false),
('POLRM', 4, 1, 'NTNNGR56D55D668J', '28-7-2020 17:30', 2, false),
('POLRM', 3, 1, 'PNTRND84D30H108A', '28-7-2020 18:30', 1, false),
('POLRM', 4, 1, 'FRRZRA72E42E530Z', '28-7-2020 14:30', 2, false),


('POLRM', 5, 1, 'PPPCLS73T25L810W', '18-07-2020 18:00', 2, true),
('POLRM', 6, 1, 'TSSGSI73H28G190O', '18-7-2020 16:30', 2, false),
('POLRM', 5, 1, 'BRNNMO12M71E893S', '18-7-2020 15:30', 1.5, false),
('POLRM', 6, 1, 'NTNNGR56D55D668J', '18-7-2020 17:30', 2, false),
('POLRM', 5, 1, 'PNTRND84D30H108A', '18-7-2020 18:30', 1, false),
('POLRM', 6, 1, 'FRRZRA72E42E530Z', '18-7-2020 14:30', 2, false),

('POLRM', 5, 1, 'PPPCLS73T25L810W', '20-07-2020 18:00', 2, true),
('POLRM', 6, 1, 'TSSGSI73H28G190O', '20-7-2020 16:30', 2, false),
('POLRM', 5, 1, 'BRNNMO12M71E893S', '20-7-2020 15:30', 1.5, false),
('POLRM', 6, 1, 'NTNNGR56D55D668J', '20-7-2020 17:30', 2, false),
('POLRM', 5, 1, 'PNTRND84D30H108A', '20-7-2020 18:30', 1, false),
('POLRM', 6, 1, 'FRRZRA72E42E530Z', '20-7-2020 14:30', 2, false),

('POLRM', 5, 1, 'PPPCLS73T25L810W', '12-07-2020 18:00', 2, true),
('POLRM', 6, 1, 'TSSGSI73H28G190O', '12-7-2020 16:30', 2, false),
('POLRM', 5, 1, 'BRNNMO12M71E893S', '12-7-2020 15:30', 1.5, false),
('POLRM', 6, 1, 'NTNNGR56D55D668J', '12-7-2020 17:30', 2, false),
('POLRM', 5, 1, 'PNTRND84D30H108A', '12-7-2020 18:30', 1, false),
('POLRM', 6, 1, 'FRRZRA72E42E530Z', '12-7-2020 14:30', 2, false),
('POLRM', 5, 1, 'BRNNMO12M71E893S', '12-7-2020 10:30', 2, false),

('POLRM', 1, 1, 'LLLMFR13P28E390F', '15-05-2020 16:30', 1, false),

('POLRM', 1, 1, 'PPPCLS73T25L810W', '15-05-2020 18:00', 2, true),
('POLRM', 3, 1, 'TSSGSI73H28G190O', '15-05-2020 16:30', 2, false),
('POLRM', 4, 1, 'BRNNMO12M71E893S', '15-05-2020 15:30', 1.5, false),
('POLRM', 4, 1, 'NTNNGR56D55D668J', '15-05-2020 17:30', 2, false),
('POLRM', 3, 1, 'PNTRND84D30H108A', '15-05-2020 18:30', 1, false),
('POLRM', 4, 1, 'FRRZRA72E42E530Z', '15-05-2020 14:30', 2, false);


INSERT INTO prenotazioni (codass, id_campo, sede, id_tesserato, data, ore, arbitro)
VALUES
('TCPG', 1, 1, 'CVNMNL81M63L817G', '05/09/2020 10:00:00', 1.5, true),
('TCPG', 2, 2, 'CNLTMR61D51L238M', '22/11/2020 15:30:00', 1, false),
('TCPG', 4, 1, 'SBBMRK17S19F961M', '10/01/2021 11:00:00', 2, false),
('TCPG', 1, 2, 'GTTRSL02R43H939G', '04/01/2021 17:30:00', 1.5, true),
('TCPG', 1, 1, 'VRGDNL10M19E727A', '07/09/2020 18:00:00', 1, false),
('TCPG', 1, 2, 'FRVLRS81R12I482L', '22/11/2020 20:00:00', 1, false),
('TCPG', 1, 1, 'CVNMNL81M63L817G', '13/02/2020 14:30:00', 2, true),
('TCPG', 1, 1, 'CNLTMR61D51L238M', '17/02/2020 09:30:00', 1, false),
('TCPG', 1, 2, 'FRVLRS81R12I482L', '27/02/2020 10:30:00', 1.5, false),
('TCPG', 2, 2, 'LTNPIA36M62H414P', '26/06/2020 12:00:00', 1, false),
('TCPG', 3, 1, 'FRVLRS81R12I482L', '07/10/2020 17:00:00', 1, true),
('TCPG', 4, 1, 'VRGDNL10M19E727A', '07/07/2020 18:30:00', 1.5, false),
('TCPG', 2, 1, 'MZZLRC35A26A038K', '17/11/2020 15:00:00', 1, true),
('TCPG', 2, 2, 'CVNMNL81M63L817G', '05/09/2020 11:00:00', 2, true),
('TCPG', 1, 2, 'GTTRSL02R43H939G', '14/12/2020 08:30:00', 1, false),
('TCPG', 1, 2, 'GGLMSO96H24A444K', '23/12/2020 16:00:00', 1.5, true),

('JSDB', 1, 1, 'BNNVND05T71H975W', '06/01/2020 16:00:00', 1, false),
('JSDB', 1, 1, 'BRSSVV13R59C631F', '31/01/2020 11:30:00', 2, true),
('JSDB', 2, 1, 'GCCSRI85E24A067U', '26/02/2020 16:00:00', 1, false),
('JSDB', 1, 2, 'GLNNRN43C65D398Y', '03/06/2020 14:30:00', 1.5, true),
('JSDB', 1, 1, 'BRTBRT09A23A261M', '04/06/2020 19:00:00', 2, true),
('JSDB', 1, 1, 'MSSRNT92T59H534R', '19/08/2020 21:00:00', 1, false),
('JSDB', 1, 2, 'BRRRSE83E17E630A', '31/08/2020 15:30:00', 2, true),
('JSDB', 1, 2, 'TSNDLD99E54C998K', '09/09/2020 07:30:00', 1.5, false),
('JSDB', 2, 1, 'RTSZHL02C15B984X', '22/09/2020 14:30:00', 1, false),
('JSDB', 2, 1, 'BRSSVV13R59C631F', '12/10/2020 18:00:00', 1, false),
('JSDB', 1, 1, 'BRRRSE83E17E630A', '09/11/2020 16:00:00', 1, true),
('JSDB', 2, 1, 'BRSSVV13R59C631F', '13/11/2020 14:30:00', 1.5, true),
('JSDB', 1, 1, 'DFSLLE73H43G184K', '22/12/2020 19:00:00', 2, true),
('JSDB', 1, 1, 'BRRRSE83E17E630A', '06/01/2021 12:00:00', 1.5, true),
('JSDB', 2, 1, 'TRNPLG00C21B166C', '19/01/2021 12:30:00', 1, false),
('JSDB', 1, 1, 'DFSLLE73H43G184K', '27/01/2021 16:00:00', 1.5, true),

('CAME', 2, 1, 'BMNNDN69S42E423C', '03/01/2020 10:00:00', 1, true),
('CAME', 1, 1, 'BROSLL87C59A562M', '07/01/2020 16:30:00', 1.5, true),
('CAME', 1, 1, 'LNGMNL80L13C387K', '15/01/2020 11:00:00', 2, false),
('CAME', 1, 2, 'LBTLCU56H53C659Q', '19/02/2020 18:30:00', 1, false),
('CAME', 2, 1, 'BRNMRO73P22G619O', '15/05/2020 21:00:00', 1, false),
('CAME', 1, 1, 'LTTCLL09H20I721H', '14/07/2020 20:00:00', 1.5, true),
('CAME', 1, 2, 'BMNNDN69S42E423C', '15/07/2020 17:30:00', 1, true),
('CAME', 2, 1, 'MNCBND12B06A227X', '22/07/2020 09:30:00', 1, true),
('CAME', 1, 1, 'GBRMCR53R06D703U', '31/08/2020 10:30:00', 1, true),
('CAME', 1, 1, 'BMNNDN69S42E423C', '03/09/2020 14:00:00', 2, false),
('CAME', 1, 2, 'BMNNDN69S42E423C', '04/09/2020 16:00:00', 2, true),
('CAME', 2, 1, 'BRNMRO73P22G619O', '13/10/2020 15:30:00', 1.5, false),
('CAME', 2, 1, 'LBTLCU56H53C659Q', '19/10/2020 11:00:00', 1, false),
('CAME', 1, 1, 'LNGMNL80L13C387K', '27/11/2020 19:00:00', 1, true),
('CAME', 1, 1, 'BRNMRO73P22G619O', '04/01/2021 18:30:00', 1.5, false),
('CAME', 1, 1, 'BROSLL87C59A562M', '11/01/2021 20:00:00', 1, true),

('POLRM', 2, 1, 'LLLMFR13P28E390F', '09/01/2020 14:00:00', 1, true),
('POLRM', 1, 1, 'TSSGSI73H28G190O', '16/01/2020 11:30:00', 1.5, true),
('POLRM', 3, 1, 'NTNNGR56D55D668J', '29/01/2020 10:00:00', 2, false),
('POLRM', 1, 1, 'BRNNMO12M71E893S', '03/02/2020 09:30:00', 1, true),
('POLRM', 2, 1, 'PPPCLS73T25L810W', '21/02/2020 20:00:00', 1, false),
('POLRM', 1, 1, 'LLLMFR13P28E390F', '24/02/2020 22:00:00', 1.5, true),
('POLRM', 4, 1, 'FRRZRA72E42E530Z', '09/04/2020 08:30:00', 1, false),
('POLRM', 2, 1, 'PNTRND84D30H108A', '11/06/2020 10:30:00', 2, true),
('POLRM', 1, 1, 'TSSGSI73H28G190O', '03/07/2020 16:30:00', 1.5, false),
('POLRM', 3, 1, 'PPPCLS73T25L810W', '06/07/2020 10:00:00', 1, true),
('POLRM', 1, 1, 'TSSGSI73H28G190O', '21/07/2020 18:00:00', 1, true),
('POLRM', 2, 1, 'FRRZRA72E42E530Z', '29/07/2020 19:30:00', 1.5, false),
('POLRM', 4, 1, 'PNTRND84D30H108A', '09/09/2020 14:00:00', 1, false),
('POLRM', 1, 1, 'BRNNMO12M71E893S', '02/10/2020 15:00:00', 2, true),
('POLRM', 2, 1, 'LLLMFR13P28E390F', '19/10/2020 21:30:00', 1.5, true),
('POLRM', 1, 1, 'NTNNGR56D55D668J', '04/01/2021 09:00:00', 1, false);

INSERT INTO pagamento (codass, data, id_dipendente, importo, tipo_operazione)
VALUES
('TCPG', '05/09/2020 10:00:00', 'CRBBDS85M15E507I', '50', 'F'),
('TCPG', '22/11/2020 15:30:00', 'PTRDNT94L06G428W', '40', 'F'),
('TCPG', '10/01/2021 11:00:00', 'CRBBDS85M15E507I', '25', 'F'),
('TCPG', '04/01/2021 17:30:00', 'MNZMRO97S22M119N', '30', 'F'),
('TCPG', '07/09/2020 18:00:00', 'CRBBDS85M15E507I', '20', 'F'),
('TCPG', '22/11/2020 20:00:00', 'CRBBDS85M15E507I', '50', 'F'),
('TCPG', '13/02/2020 14:30:00', 'MNZMRO97S22M119N', '30', 'F'),
('TCPG', '17/02/2020 09:30:00', 'CRBBDS85M15E507I', '20', 'F'),
('TCPG', '27/02/2020 10:30:00', 'MNZMRO97S22M119N', '35', 'F'),
('TCPG', '26/06/2020 12:00:00', 'MNZMRO97S22M119N', '55', 'F'),
('TCPG', '07/10/2020 17:00:00', 'PTRDNT94L06G428W', '25', 'F'),
('TCPG', '07/07/2020 18:30:00', 'CRBBDS85M15E507I', '35', 'F'),
('TCPG', '17/11/2020 15:00:00', 'MNZMRO97S22M119N', '30', 'F'),
('TCPG', '05/09/2020 11:00:00', 'PTRDNT94L06G428W', '20', 'F'),
('TCPG', '14/12/2020 08:30:00', 'PTRDNT94L06G428W', '35', 'F'),
('TCPG', '23/12/2020 16:00:00', 'MNZMRO97S22M119N', '60', 'F'),

('JSDB', '06/01/2020 16:00:00', 'BRTGNN98P45C524P', '50', 'F'),
('JSDB', '31/01/2020 11:30:00', 'RZZLEA93C44F385V', '50', 'F'),
('JSDB', '26/02/2020 16:00:00', 'GBRCLL96E65F726F', '60', 'F'),
('JSDB', '03/06/2020 14:30:00', 'NSLSDR89R50L319K', '25', 'F'),
('JSDB', '04/06/2020 19:00:00', 'NSLSDR89R50L319K', '30', 'F'),
('JSDB', '19/08/2020 21:00:00', 'BRTGNN98P45C524P', '45', 'F'),
('JSDB', '31/08/2020 15:30:00', 'BRTGNN98P45C524P', '55', 'F'),
('JSDB', '09/09/2020 07:30:00', 'RZZLEA93C44F385V', '25', 'F'),
('JSDB', '22/09/2020 14:30:00', 'GBRCLL96E65F726F', '30', 'F'),
('JSDB', '12/10/2020 18:00:00', 'NSLSDR89R50L319K', '35', 'F'),
('JSDB', '09/11/2020 16:00:00', 'RZZLEA93C44F385V', '20', 'F'),
('JSDB', '13/11/2020 14:30:00', 'GBRCLL96E65F726F', '35', 'F'),
('JSDB', '22/12/2020 19:00:00', 'NSLSDR89R50L319K', '45', 'F'),
('JSDB', '06/01/2021 12:00:00', 'BRTGNN98P45C524P', '40', 'F'),
('JSDB', '19/01/2021 12:30:00', 'GBRCLL96E65F726F', '30', 'F'),
('JSDB', '27/01/2021 16:00:00', 'RZZLEA93C44F385V', '50', 'F'),

('CAME', '03/01/2020 10:00:00', 'SCCTCR93M24L183J', '20', 'F'),
('CAME', '07/01/2020 16:30:00', 'BRCGTN93A23A193B', '30', 'F'),
('CAME', '15/01/2020 11:00:00', 'SCCTCR93M24L183J', '25', 'F'),
('CAME', '19/02/2020 18:30:00', 'BRCGTN93A23A193B', '35', 'F'),
('CAME', '15/05/2020 21:00:00', 'SCCTCR93M24L183J', '50', 'F'),
('CAME', '14/07/2020 20:00:00', 'SCCTCR93M24L183J', '40', 'F'),
('CAME', '15/07/2020 17:30:00', 'SCCTCR93M24L183J', '45', 'F'),
('CAME', '22/07/2020 09:30:00', 'BRCGTN93A23A193B', '25', 'F'),
('CAME', '31/08/2020 10:30:00', 'BRCGTN93A23A193B', '30', 'F'),
('CAME', '03/09/2020 14:00:00', 'BRCGTN93A23A193B', '35', 'F'),
('CAME', '04/09/2020 16:00:00', 'SCCTCR93M24L183J', '25', 'F'),
('CAME', '13/10/2020 15:30:00', 'SCCTCR93M24L183J', '30', 'F'),
('CAME', '19/10/2020 11:00:00', 'BRCGTN93A23A193B', '40', 'F'),
('CAME', '27/11/2020 19:00:00', 'SCCTCR93M24L183J', '50', 'F'),
('CAME', '04/01/2021 18:30:00', 'BRCGTN93A23A193B', '55', 'F'),
('CAME', '11/01/2021 20:00:00', 'SCCTCR93M24L183J', '35', 'F'),

('POLRM', '09/01/2020 14:00:00', 'LBRMLN88B52A690A', '65', 'F'),
('POLRM', '16/01/2020 11:30:00', 'NDDMDL99T62F762S', '40', 'F'),
('POLRM', '29/01/2020 10:00:00', 'PLCFBL97P51F651S', '50', 'F'),
('POLRM', '03/02/2020 09:30:00', 'PLOTLM95P23F717I', '45', 'F'),
('POLRM', '21/02/2020 20:00:00', 'NDDMDL99T62F762S', '25', 'F'),
('POLRM', '24/02/2020 22:00:00', 'PLCFBL97P51F651S', '25', 'F'),
('POLRM', '09/04/2020 08:30:00', 'PLOTLM95P23F717I', '50', 'F'),
('POLRM', '11/06/2020 10:30:00', 'LBRMLN88B52A690A', '55', 'F'),
('POLRM', '03/07/2020 16:30:00', 'NDDMDL99T62F762S', '35', 'F'),
('POLRM', '06/07/2020 10:00:00', 'LBRMLN88B52A690A', '50', 'F'),
('POLRM', '21/07/2020 18:00:00', 'PLOTLM95P23F717I', '20', 'F'),
('POLRM', '29/07/2020 19:30:00', 'PLCFBL97P51F651S', '25', 'F'),
('POLRM', '09/09/2020 14:00:00', 'NDDMDL99T62F762S', '35', 'F'),
('POLRM', '02/10/2020 15:00:00', 'PLOTLM95P23F717I', '45', 'F'),
('POLRM', '19/10/2020 21:30:00', 'LBRMLN88B52A690A', '25', 'F'),
('POLRM', '04/01/2021 09:00:00', 'NDDMDL99T62F762S', '30', 'F');

INSERT INTO fatture (codass, data, id_dipendente, tesserato, descrizione, progressivo)
VALUES
('TCPG', '22/11/2020 15:30:00', 'PTRDNT94L06G428W', 'CNLTMR61D51L238M', 'Pagamento prenotazione', '1'),
('TCPG', '10/01/2021 11:00:00', 'CRBBDS85M15E507I', 'SBBMRK17S19F961M', 'Pagamento prenotazione', '2'),
('TCPG', '04/01/2021 17:30:00', 'MNZMRO97S22M119N', 'GTTRSL02R43H939G', 'Pagamento prenotazione', '3'),
('TCPG', '07/09/2020 18:00:00', 'CRBBDS85M15E507I', 'VRGDNL10M19E727A', 'Pagamento prenotazione', '4'),
('TCPG', '22/11/2020 20:00:00', 'CRBBDS85M15E507I', 'FRVLRS81R12I482L', 'Pagamento prenotazione', '5'),
('TCPG', '13/02/2020 14:30:00', 'MNZMRO97S22M119N', 'CVNMNL81M63L817G', 'Pagamento prenotazione', '6'),
('TCPG', '17/02/2020 09:30:00', 'CRBBDS85M15E507I', 'CNLTMR61D51L238M', 'Pagamento prenotazione', '7'),
('TCPG', '27/02/2020 10:30:00', 'MNZMRO97S22M119N', 'FRVLRS81R12I482L', 'Pagamento prenotazione', '8'),
('TCPG', '26/06/2020 12:00:00', 'MNZMRO97S22M119N', 'LTNPIA36M62H414P', 'Pagamento prenotazione', '9'),
('TCPG', '07/10/2020 17:00:00', 'PTRDNT94L06G428W', 'FRVLRS81R12I482L', 'Pagamento prenotazione', '10'),
('TCPG', '07/07/2020 18:30:00', 'CRBBDS85M15E507I', 'VRGDNL10M19E727A', 'Pagamento prenotazione', '11'),
('TCPG', '17/11/2020 15:00:00', 'MNZMRO97S22M119N', 'MZZLRC35A26A038K', 'Pagamento prenotazione', '12'),
('TCPG', '05/09/2020 11:00:00', 'PTRDNT94L06G428W', 'CVNMNL81M63L817G', 'Pagamento prenotazione', '13'),
('TCPG', '14/12/2020 08:30:00', 'PTRDNT94L06G428W', 'GTTRSL02R43H939G', 'Pagamento prenotazione', '14'),
('TCPG', '23/12/2020 16:00:00', 'MNZMRO97S22M119N', 'GGLMSO96H24A444K', 'Pagamento prenotazione', '15'),
('TCPG', '05/09/2020 10:00:00', 'CRBBDS85M15E507I', 'CVNMNL81M63L817G', 'Pagamento prenotazione', '16'),

('JSDB', '31/01/2020 11:30:00', 'RZZLEA93C44F385V', 'BRSSVV13R59C631F', 'Pagamento prenotazione', '1'),
('JSDB', '26/02/2020 16:00:00', 'GBRCLL96E65F726F', 'GCCSRI85E24A067U', 'Pagamento prenotazione', '2'),
('JSDB', '03/06/2020 14:30:00', 'NSLSDR89R50L319K', 'GLNNRN43C65D398Y', 'Pagamento prenotazione', '3'),
('JSDB', '04/06/2020 19:00:00', 'NSLSDR89R50L319K', 'BRTBRT09A23A261M', 'Pagamento prenotazione', '4'),
('JSDB', '19/08/2020 21:00:00', 'BRTGNN98P45C524P', 'MSSRNT92T59H534R', 'Pagamento prenotazione', '5'),
('JSDB', '31/08/2020 15:30:00', 'BRTGNN98P45C524P', 'BRRRSE83E17E630A', 'Pagamento prenotazione', '6'),
('JSDB', '09/09/2020 07:30:00', 'RZZLEA93C44F385V', 'TSNDLD99E54C998K', 'Pagamento prenotazione', '7'),
('JSDB', '22/09/2020 14:30:00', 'GBRCLL96E65F726F', 'RTSZHL02C15B984X', 'Pagamento prenotazione', '8'),
('JSDB', '12/10/2020 18:00:00', 'NSLSDR89R50L319K', 'BRSSVV13R59C631F', 'Pagamento prenotazione', '9'),
('JSDB', '09/11/2020 16:00:00', 'RZZLEA93C44F385V', 'BRRRSE83E17E630A', 'Pagamento prenotazione', '10'),
('JSDB', '13/11/2020 14:30:00', 'GBRCLL96E65F726F', 'BRSSVV13R59C631F', 'Pagamento prenotazione', '11'),
('JSDB', '22/12/2020 19:00:00', 'NSLSDR89R50L319K', 'DFSLLE73H43G184K', 'Pagamento prenotazione', '12'),
('JSDB', '06/01/2021 12:00:00', 'BRTGNN98P45C524P', 'BRRRSE83E17E630A', 'Pagamento prenotazione', '13'),
('JSDB', '19/01/2021 12:30:00', 'GBRCLL96E65F726F', 'TRNPLG00C21B166C', 'Pagamento prenotazione', '14'),
('JSDB', '27/01/2021 16:00:00', 'RZZLEA93C44F385V', 'DFSLLE73H43G184K', 'Pagamento prenotazione', '15'),
('JSDB', '06/01/2020 16:00:00', 'BRTGNN98P45C524P', 'BNNVND05T71H975W', 'Pagamento prenotazione', '16'),

('CAME', '07/01/2020 16:30:00', 'BRCGTN93A23A193B', 'BROSLL87C59A562M', 'Pagamento prenotazione', '1'),
('CAME', '15/01/2020 11:00:00', 'SCCTCR93M24L183J', 'LNGMNL80L13C387K', 'Pagamento prenotazione', '2'),
('CAME', '19/02/2020 18:30:00', 'BRCGTN93A23A193B', 'LBTLCU56H53C659Q', 'Pagamento prenotazione', '3'),
('CAME', '15/05/2020 21:00:00', 'SCCTCR93M24L183J', 'BRNMRO73P22G619O', 'Pagamento prenotazione', '4'),
('CAME', '14/07/2020 20:00:00', 'SCCTCR93M24L183J', 'LTTCLL09H20I721H', 'Pagamento prenotazione', '5'),
('CAME', '15/07/2020 17:30:00', 'SCCTCR93M24L183J', 'BMNNDN69S42E423C', 'Pagamento prenotazione', '6'),
('CAME', '22/07/2020 09:30:00', 'BRCGTN93A23A193B', 'MNCBND12B06A227X', 'Pagamento prenotazione', '7'),
('CAME', '31/08/2020 10:30:00', 'BRCGTN93A23A193B', 'GBRMCR53R06D703U', 'Pagamento prenotazione', '8'),
('CAME', '03/09/2020 14:00:00', 'BRCGTN93A23A193B', 'BMNNDN69S42E423C', 'Pagamento prenotazione', '9'),
('CAME', '04/09/2020 16:00:00', 'SCCTCR93M24L183J', 'BMNNDN69S42E423C', 'Pagamento prenotazione', '10'),
('CAME', '13/10/2020 15:30:00', 'SCCTCR93M24L183J', 'BRNMRO73P22G619O', 'Pagamento prenotazione', '11'),
('CAME', '19/10/2020 11:00:00', 'BRCGTN93A23A193B', 'LBTLCU56H53C659Q', 'Pagamento prenotazione', '12'),
('CAME', '27/11/2020 19:00:00', 'SCCTCR93M24L183J', 'LNGMNL80L13C387K', 'Pagamento prenotazione', '13'),
('CAME', '04/01/2021 18:30:00', 'BRCGTN93A23A193B', 'BRNMRO73P22G619O', 'Pagamento prenotazione', '14'),
('CAME', '11/01/2021 20:00:00', 'SCCTCR93M24L183J', 'BROSLL87C59A562M', 'Pagamento prenotazione', '15'),
('CAME', '03/01/2020 10:00:00', 'SCCTCR93M24L183J', 'BMNNDN69S42E423C', 'Pagamento prenotazione', '16'),

('POLRM', '16/01/2020 11:30:00', 'NDDMDL99T62F762S', 'TSSGSI73H28G190O', 'Pagamento prenotazione', '1'),
('POLRM', '29/01/2020 10:00:00', 'PLCFBL97P51F651S', 'NTNNGR56D55D668J', 'Pagamento prenotazione', '2'),
('POLRM', '03/02/2020 09:30:00', 'PLOTLM95P23F717I', 'BRNNMO12M71E893S', 'Pagamento prenotazione', '3'),
('POLRM', '21/02/2020 20:00:00', 'NDDMDL99T62F762S', 'PPPCLS73T25L810W', 'Pagamento prenotazione', '4'),
('POLRM', '24/02/2020 22:00:00', 'PLCFBL97P51F651S', 'LLLMFR13P28E390F', 'Pagamento prenotazione', '5'),
('POLRM', '09/04/2020 08:30:00', 'PLOTLM95P23F717I', 'FRRZRA72E42E530Z', 'Pagamento prenotazione', '6'),
('POLRM', '11/06/2020 10:30:00', 'LBRMLN88B52A690A', 'PNTRND84D30H108A', 'Pagamento prenotazione', '7'),
('POLRM', '03/07/2020 16:30:00', 'NDDMDL99T62F762S', 'TSSGSI73H28G190O', 'Pagamento prenotazione', '8'),
('POLRM', '06/07/2020 10:00:00', 'LBRMLN88B52A690A', 'PPPCLS73T25L810W', 'Pagamento prenotazione', '9'),
('POLRM', '21/07/2020 18:00:00', 'PLOTLM95P23F717I', 'TSSGSI73H28G190O', 'Pagamento prenotazione', '10'),
('POLRM', '29/07/2020 19:30:00', 'PLCFBL97P51F651S', 'FRRZRA72E42E530Z', 'Pagamento prenotazione', '11'),
('POLRM', '09/09/2020 14:00:00', 'NDDMDL99T62F762S', 'PNTRND84D30H108A', 'Pagamento prenotazione', '12'),
('POLRM', '02/10/2020 15:00:00', 'PLOTLM95P23F717I', 'BRNNMO12M71E893S', 'Pagamento prenotazione', '13'),
('POLRM', '19/10/2020 21:30:00', 'LBRMLN88B52A690A', 'LLLMFR13P28E390F', 'Pagamento prenotazione', '14'),
('POLRM', '04/01/2021 09:00:00', 'NDDMDL99T62F762S', 'NTNNGR56D55D668J', 'Pagamento prenotazione', '15'),
('POLRM', '09/01/2020 14:00:00', 'LBRMLN88B52A690A', 'LLLMFR13P28E390F', 'Pagamento prenotazione', '16');

INSERT INTO pagamento (codass, data, id_dipendente, importo, tipo_operazione)
VALUES
('JSDB', '12/04/2021', 'BBBLRD94E18F315Z', '-1000,65', 'S'),
('TCPG', '22/02/2021', 'NFRDRN89R59L535D', '-1500,65', 'S'),
('TCPG', '18/08/2020', 'NFRDRN89R59L535D', '-1750,80', 'S'),
('TCPG', '29/05/2019', 'QNTGRD98C08F655L', '-1880,05', 'S'),
('TCPG', '04/01/2020', 'QNTGRD98C08F655L', '-1220,20', 'S');

INSERT INTO stipendi (codass, data, id_dipendente, soggetto)
VALUES
('JSDB', '12/04/2021', 'BBBLRD94E18F315Z', 'BRTGNN98P45C524P'),
('TCPG', '22/02/2021', 'NFRDRN89R59L535D', 'QNTGRD98C08F655L'),
('TCPG', '18/08/2020', 'NFRDRN89R59L535D', 'MDAMRV91B66C187D'),
('TCPG', '29/05/2019', 'QNTGRD98C08F655L', 'TGLRML91E23D578W'),
('TCPG', '04/01/2020', 'QNTGRD98C08F655L', 'PTRDNT94L06G428W');

INSERT INTO pagamento (codass, data, id_dipendente, importo, tipo_operazione)
VALUES
('TCPG', '14/02/2020 11:00:00', 'FGZRLD00R30H395L', '-500', 'E'),
('TCPG', '04/05/2020 15:00:00', 'MDAMRV91B66C187D', '-200', 'E'),
('JSDB', '23/07/2020 17:30:00', 'CLSNRC93S69H949L', '-250', 'E'),
('JSDB', '27/08/2020 15:00:00', 'GRZNLL85R60C685E', '-150', 'E'),
('CAME', '07/09/2020 18:00:00', 'FNLRFL00L58F216F', '-100', 'E'),
('POLRM', '23/09/2020 20:30:00', 'MSMRTT97R11C661I', '-200', 'E'),
('POLRM', '07/01/2021 08:00:00', 'BSCRCL88H09G520N', '-200', 'E');

INSERT INTO esborsi (codass, data, id_dipendente, id_fornitore, descrizione)
VALUES
('TCPG', '14/02/2020 11:00:00', 'FGZRLD00R30H395L', '05126523875', 'Racchette Wilson'),
('TCPG', '04/05/2020 15:00:00', 'MDAMRV91B66C187D', '06456486415', 'Palline Babolat'),
('JSDB', '23/07/2020 17:30:00', 'CLSNRC93S69H949L', '06500120016', 'Palloni da basket Molten'),
('JSDB', '27/08/2020 15:00:00', 'GRZNLL85R60C685E', '04512794513', 'Casacche della Nike'),
('CAME', '07/09/2020 18:00:00', 'FNLRFL00L58F216F', '07762523875', 'Palloni da calcio Adidas'),
('POLRM', '23/09/2020 20:30:00', 'MSMRTT97R11C661I', '06500120016', 'Palloni da basket Molten'),
('POLRM', '07/01/2021 08:00:00', 'BSCRCL88H09G520N', '08794512358', 'Palline da Tennis ATP');

INSERT INTO prenotazioni (codass, id_campo, sede, id_tesserato, data, ore, arbitro)
VALUES
('CAME', 2, 1, 'BMNNDN69S42E423C', '03/01/2019 10:00:00', 1, true),
('CAME', 1, 1, 'BROSLL87C59A562M', '07/01/2019 16:30:00', 1.5, true),
('CAME', 1, 1, 'LNGMNL80L13C387K', '15/01/2019 11:00:00', 2, false),
('CAME', 1, 2, 'LBTLCU56H53C659Q', '19/02/2019 18:30:00', 1, false),
('CAME', 2, 1, 'BRNMRO73P22G619O', '15/05/2019 21:00:00', 1, false),
('CAME', 1, 1, 'LTTCLL09H20I721H', '14/07/2019 20:00:00', 1.5, true),
('CAME', 1, 2, 'BMNNDN69S42E423C', '15/07/2019 17:30:00', 1, true),
('CAME', 2, 1, 'MNCBND12B06A227X', '22/07/2019 09:30:00', 1, true),
('CAME', 1, 1, 'GBRMCR53R06D703U', '31/08/2019 10:30:00', 1, true),
('CAME', 1, 1, 'BMNNDN69S42E423C', '03/09/2019 14:00:00', 2, false),

('POLRM', 2, 1, 'LLLMFR13P28E390F', '09/01/2019 14:00:00', 1, true),
('POLRM', 1, 1, 'TSSGSI73H28G190O', '16/01/2019 11:30:00', 1.5, true),
('POLRM', 3, 1, 'NTNNGR56D55D668J', '29/01/2019 10:00:00', 2, false),
('POLRM', 1, 1, 'BRNNMO12M71E893S', '03/02/2019 09:30:00', 1, true),
('POLRM', 2, 1, 'PPPCLS73T25L810W', '21/02/2019 20:00:00', 1, false),
('POLRM', 1, 1, 'LLLMFR13P28E390F', '24/02/2019 22:00:00', 1.5, true),
('POLRM', 4, 1, 'FRRZRA72E42E530Z', '09/04/2019 08:30:00', 1, false),
('POLRM', 2, 1, 'PNTRND84D30H108A', '11/06/2019 10:30:00', 2, true),
('POLRM', 1, 1, 'TSSGSI73H28G190O', '03/07/2019 16:30:00', 1.5, false),
('POLRM', 3, 1, 'PPPCLS73T25L810W', '06/07/2019 10:00:00', 1, true);

INSERT INTO pagamento (codass, data, id_dipendente, importo, tipo_operazione)
VALUES
('CAME', '03/01/2019 10:00:00', 'SCCTCR93M24L183J', '20', 'F'),
('CAME', '07/01/2019 16:30:00', 'BRCGTN93A23A193B', '30', 'F'),
('CAME', '15/01/2019 11:00:00', 'SCCTCR93M24L183J', '25', 'F'),
('CAME', '19/02/2019 18:30:00', 'BRCGTN93A23A193B', '35', 'F'),
('CAME', '15/05/2019 21:00:00', 'SCCTCR93M24L183J', '50', 'F'),
('CAME', '14/07/2019 20:00:00', 'SCCTCR93M24L183J', '40', 'F'),
('CAME', '15/07/2019 17:30:00', 'SCCTCR93M24L183J', '45', 'F'),
('CAME', '22/07/2019 09:30:00', 'BRCGTN93A23A193B', '25', 'F'),
('CAME', '31/08/2019 10:30:00', 'BRCGTN93A23A193B', '30', 'F'),
('CAME', '03/09/2019 14:00:00', 'BRCGTN93A23A193B', '35', 'F'),

('POLRM', '09/01/2019 14:00:00', 'LBRMLN88B52A690A', '65', 'F'),
('POLRM', '16/01/2019 11:30:00', 'NDDMDL99T62F762S', '40', 'F'),
('POLRM', '29/01/2019 10:00:00', 'PLCFBL97P51F651S', '50', 'F'),
('POLRM', '03/02/2019 09:30:00', 'PLOTLM95P23F717I', '45', 'F'),
('POLRM', '21/02/2019 20:00:00', 'NDDMDL99T62F762S', '25', 'F'),
('POLRM', '24/02/2019 22:00:00', 'PLCFBL97P51F651S', '25', 'F'),
('POLRM', '09/04/2019 08:30:00', 'PLOTLM95P23F717I', '50', 'F'),
('POLRM', '11/06/2019 10:30:00', 'LBRMLN88B52A690A', '55', 'F'),
('POLRM', '03/07/2019 16:30:00', 'NDDMDL99T62F762S', '35', 'F'),
('POLRM', '06/07/2019 10:00:00', 'LBRMLN88B52A690A', '50', 'F');

INSERT INTO fatture (codass, data, id_dipendente, tesserato, descrizione, progressivo)
VALUES
('CAME', '03/01/2020 10:00:00', 'SCCTCR93M24L183J', 'BMNNDN69S42E423C', 'Pagamento prenotazione', '1'),
('CAME', '07/01/2019 16:30:00', 'BRCGTN93A23A193B', 'BROSLL87C59A562M', 'Pagamento prenotazione', '2'),
('CAME', '15/01/2019 11:00:00', 'SCCTCR93M24L183J', 'LNGMNL80L13C387K', 'Pagamento prenotazione', '3'),
('CAME', '19/02/2019 18:30:00', 'BRCGTN93A23A193B', 'LBTLCU56H53C659Q', 'Pagamento prenotazione', '4'),
('CAME', '15/05/2019 21:00:00', 'SCCTCR93M24L183J', 'BRNMRO73P22G619O', 'Pagamento prenotazione', '5'),
('CAME', '14/07/2019 20:00:00', 'SCCTCR93M24L183J', 'LTTCLL09H20I721H', 'Pagamento prenotazione', '6'),
('CAME', '15/07/2019 17:30:00', 'SCCTCR93M24L183J', 'BMNNDN69S42E423C', 'Pagamento prenotazione', '7'),
('CAME', '22/07/2019 09:30:00', 'BRCGTN93A23A193B', 'MNCBND12B06A227X', 'Pagamento prenotazione', '8'),
('CAME', '31/08/2019 10:30:00', 'BRCGTN93A23A193B', 'GBRMCR53R06D703U', 'Pagamento prenotazione', '9'),
('CAME', '03/09/2019 14:00:00', 'BRCGTN93A23A193B', 'BMNNDN69S42E423C', 'Pagamento prenotazione', '10'),

('POLRM', '09/01/2020 14:00:00', 'LBRMLN88B52A690A', 'LLLMFR13P28E390F', 'Pagamento prenotazione', '1'),
('POLRM', '16/01/2019 11:30:00', 'NDDMDL99T62F762S', 'TSSGSI73H28G190O', 'Pagamento prenotazione', '2'),
('POLRM', '29/01/2019 10:00:00', 'PLCFBL97P51F651S', 'NTNNGR56D55D668J', 'Pagamento prenotazione', '3'),
('POLRM', '03/02/2019 09:30:00', 'PLOTLM95P23F717I', 'BRNNMO12M71E893S', 'Pagamento prenotazione', '4'),
('POLRM', '21/02/2019 20:00:00', 'NDDMDL99T62F762S', 'PPPCLS73T25L810W', 'Pagamento prenotazione', '5'),
('POLRM', '24/02/2019 22:00:00', 'PLCFBL97P51F651S', 'LLLMFR13P28E390F', 'Pagamento prenotazione', '6'),
('POLRM', '09/04/2019 08:30:00', 'PLOTLM95P23F717I', 'FRRZRA72E42E530Z', 'Pagamento prenotazione', '7'),
('POLRM', '11/06/2019 10:30:00', 'LBRMLN88B52A690A', 'PNTRND84D30H108A', 'Pagamento prenotazione', '8'),
('POLRM', '03/07/2019 16:30:00', 'NDDMDL99T62F762S', 'TSSGSI73H28G190O', 'Pagamento prenotazione', '9'),
('POLRM', '06/07/2019 10:00:00', 'LBRMLN88B52A690A', 'PPPCLS73T25L810W', 'Pagamento prenotazione', '10');

/* --------------------------- */
/* --------- QUERIES --------- */
/* --------------------------- */

/* 
	Query estratto conto annuale con differenza rispetto all'anno precedente di TUTTE le associazioni 
*/
DROP VIEW IF EXISTS saldo_annuale;
CREATE VIEW saldo_annuale AS
	SELECT codass, sum(importo) as saldo
	FROM pagamento P
	WHERE extract(year from P.data) = (extract(year from CURRENT_DATE)-1)
	GROUP BY codass;

DROP VIEW IF EXISTS saldo_anno_prec;
CREATE VIEW saldo_anno_prec AS
	SELECT codass, sum(importo) as saldo
	FROM pagamento P
	WHERE extract(year from P.data) = (extract(year from CURRENT_DATE)-2)
	GROUP BY codass;

SELECT A.codice, A.ragsoc, SA.saldo as "Saldo Anno Corrente", SP.saldo as "Saldo Anno Precedente",
CASE
    WHEN SA.saldo > SP.saldo THEN 'POSITIVO'
	WHEN SA.saldo = SP.saldo THEN 'PARI'
	WHEN SA.saldo IS NULL OR SP.saldo IS NULL THEN 'non disponibile'
    ELSE 'NEGATIVO'
END AS Stato,
CASE
	WHEN SA.saldo > SP.saldo AND SP.saldo > 0::money THEN CONCAT('+',ROUND((((SA.saldo-SP.saldo)/SP.saldo)*100)::numeric, 2))
	WHEN SA.saldo > SP.saldo AND SP.saldo < 0::money THEN CONCAT('+',ROUND((((SA.saldo-SP.saldo)/SP.saldo)*100)::numeric, 2)*-1)
	WHEN SP.saldo > SA.saldo AND SA.saldo > 0::money THEN CONCAT('',ROUND((((SA.saldo-SP.saldo)/SP.saldo)*100)::numeric, 2))
	WHEN SA.saldo IS NULL OR SP.saldo IS NULL THEN 'non calcolabile'
	ELSE CONCAT('-',ROUND((((SA.saldo-SP.saldo)/SP.saldo)*100)::numeric, 2))
END AS Percentuale
FROM associazione A 
LEFT JOIN saldo_annuale as SA ON SA.codass = A.codice
LEFT JOIN saldo_anno_prec as SP ON SP.codass = A.codice
GROUP BY A.codice, A.ragsoc, SA.saldo, SP.saldo

/* 
	Indicare per ogni associazione, le sedi che hanno registrato il maggior numero di prenotazioni lo scorso anno e
	indicare la media delle prenotazioni mensili
*/
DROP VIEW IF EXISTS prenotazioni_per_sede;
CREATE VIEW prenotazioni_per_sede AS
	SELECT P.codass, P.sede as cod_sede, count(P.sede) as num, ROUND(count(P.sede)/12.0,2) as prenotazioni_mensili
	FROM prenotazioni P
	JOIN Sede S ON P.sede = S.codice AND P.codass = S.codass
	JOIN Associazione A ON A.codice = S.codass
	JOIN Citta C 		ON C.istat = S.cod_citta
	WHERE extract(year from P.data) = (extract(year from CURRENT_DATE)-1)
	GROUP BY P.codass, P.sede;

SELECT A.ragsoc as associazione, S.nome as nome_sede, C.nome as citta, S.via, M.max as prenotazioni_totali, prenotazioni_mensili
FROM prenotazioni_per_sede P
JOIN (SELECT codass, max(num) as max
		FROM prenotazioni_per_sede
		group by codass) M 		ON P.codass = M.codass AND num = max
JOIN Associazione A				ON A.codice = P.codass
JOIN Sede S 					ON S.codass = P.codass AND S.codice = cod_sede
JOIN Citta C 					ON C.istat = S.cod_citta;


/*
	La Polisportiva Romana (codice POLRM) vuole organizzare un evento calcistico per i suoi tesserati. Deve decidere in quale sede, quale campo e
	quale fascia oraria siano i più adatti per organizzare l'evento. Nella query si indica il nome della sede, il numero del campo, il relativo
	terreno e il numero di prenotazioni totali in cui compare nelle due fasce orarie mattino (dalle 8 alle 12) e pomeriggio (dalle 13 alle 21).
*/
DROP VIEW IF EXISTS utilizzo_campi_pomeriggio;
CREATE VIEW utilizzo_campi_pomeriggio AS
	SELECT p.codass, p.sede, p.id_campo, count(*) as tot_p_pomeriggio
	FROM prenotazioni p
	JOIN campo c ON c.codass = p.codass AND c.id = p.id_campo
	WHERE date_part('hour', p.data) between 13 AND 21
	GROUP BY p.codass, p.id_campo, p.sede
	ORDER BY p.codass, p.sede;

DROP VIEW IF EXISTS utilizzo_campi_mattino;
CREATE VIEW utilizzo_campi_mattino AS
	SELECT p.codass, p.sede, p.id_campo, count(*) as tot_p_mattino
	FROM prenotazioni p
	JOIN campo c ON c.codass = p.codass AND c.id = p.id_campo
	WHERE date_part('hour', p.data) between 8 AND 12
	GROUP BY p.codass, p.id_campo, p.sede
	ORDER BY p.codass, p.sede;

SELECT s.nome as nome_sede, c.id as num_campo, t.sport, t.terreno, tot_p_mattino, tot_p_pomeriggio
FROM campo c
LEFT JOIN tipologia_campo t 
	ON t.codass = c.codass AND t.id = c.tipologia
LEFT JOIN sede s 
	ON s.codass = c.codass AND s.codice = c.cod_sede
LEFT JOIN utilizzo_campi_pomeriggio ucp 
	ON ucp.codass = c.codass AND ucp.sede = c.cod_sede AND ucp.id_campo = c.id
LEFT JOIN utilizzo_campi_mattino ucm 
	ON ucm.codass = c.codass AND ucm.sede = c.cod_sede AND ucm.id_campo = c.id
WHERE c.codass = 'POLRM' AND c.attrezzatura AND t.sport like '_alcio%' 
AND (tot_p_mattino IS NOT NULL OR tot_p_pomeriggio IS NOT NULL)


/* 
	Saldo sedi associazione Calciatori Mestrini (codice CAME), dipendenti attualmente attivi e totale prenotazioni relative a quella sede nell'anno precendente
*/
SELECT s.nome as nome_sede, sum(importo) as saldo, attivi as dipendenti_attivi, prenotazioni_anno
FROM sede s
LEFT JOIN dipendente d ON d.codass = s.codass AND d.cod_sede = s.codice
LEFT JOIN pagamento p ON p.codass = s.codass AND p.id_dipendente = d.cf
LEFT JOIN (SELECT codass, cod_sede, count(*) as attivi
			FROM dipendente d
			WHERE data_fine IS NULL
			GROUP BY codass, cod_sede
			ORDER BY codass, cod_sede) as ta ON ta.codass = s.codass AND ta.cod_sede = s.codice
LEFT JOIN (SELECT codass, sede, count(*) as prenotazioni_anno
			FROM prenotazioni
			WHERE extract(year from data) = extract(year from CURRENT_DATE)-1
			GROUP BY codass, sede) as pr ON pr.codass = s.codass AND pr.sede = s.codice
WHERE 
s.codass = 'CAME' AND 
(extract(year from p.data) = extract(year from CURRENT_DATE)-1 or importo is null)
GROUP BY s.codice, s.nome, s.codass, attivi, prenotazioni_anno

/* 
	Mostrare i campi disponibili presso tutte le sedi della Polisportiva Romana (codice POLRM) in data 20/05/2020 
	filtrato per la fascia oraria dalle 13:30 alle 21:30 e nel caso ci fossero prenotazioni pendenti su quel campo
	indicare quando è occupato.
*/ 
SELECT s.nome as nome_sede, s.via, s.cod_civico, up.id as num_campo, t.sport, t.terreno, 
	CASE
		WHEN up.da IS NULL THEN 'DISPONIBILE'
		ELSE 'OCCUPATO'
	END as stato,
	to_char(up.da, 'HH24:MI:SS') as da, to_char(up.a, 'HH24:MI:SS') as a
FROM sede s
JOIN associazione a 
	ON a.codice = s.codass
JOIN ((SELECT c.codass, c.cod_sede , c.id, c.tipologia, NULL as da, NULL as a
		FROM campo c
		LEFT JOIN prenotazioni p ON p.codass = c.codass AND p.id_campo = c.id AND p.sede = c.cod_sede
		WHERE (c.codass, c.id) NOT IN (
			SELECT DISTINCT c.codass, id
			FROM campo c
			LEFT JOIN prenotazioni p ON p.codass = c.codass AND p.sede = c.cod_sede AND p.id_campo = c.id
			WHERE data between '2020-5-20 13:30' AND '2020-05-20 21:30'
		)
		GROUP BY c.cod_sede , c.id, c.codass, c.tipologia)
		union
		(SELECT c.codass, c.cod_sede, c.id, c.tipologia, data as da, data + (ore * INTERVAL '1 hour') as a
		FROM campo c
		JOIN prenotazioni p ON p.codass = c.codass AND p.sede = c.cod_sede AND p.id_campo = c.id
		WHERE data between '2020-5-20 13:30' AND '2020-05-20 21:30'
		GROUP BY c.codass, c.id, c.cod_sede, c.tipologia, data, ore)) as up
	ON up.codass = s.codass AND up.cod_sede = s.codice
JOIN tipologia_campo t
	ON t.codass = a.codice AND t.id = up.tipologia
WHERE a.codice = 'POLRM'
ORDER BY a.codice, s.codice, s.nome, up.id, up.da

/* 
	Tesserati della Polisportiva Romana che hanno fatto almeno 2 prenotazioni nel 2020 e indicare il campo più prenotato 
	e il relativo numero di prenotazioni fatte su quel campo 
*/
DROP VIEW IF EXISTS prenotazioni_tesserato_1campo;
CREATE VIEW prenotazioni_tesserato_1campo AS
	SELECT codass, id_tesserato, max(num) as max
	FROM (
		SELECT codass, id_tesserato, id_campo, count(*) as num
		FROM prenotazioni
		WHERE extract(YEAR from data) = extract(year from CURRENT_DATE)-1
		GROUP BY codass, id_tesserato, id_campo
	) as conteggio
	GROUP BY codass, id_tesserato;
	
SELECT p.id_tesserato as "Codice Fiscale", T.cognome, T.nome, s.nome as "Nome della sede", p.id_campo as "Numero Campo Preferito", tc.sport, pmax.max as "N° Prenotazioni"
FROM prenotazioni p
JOIN prenotazioni_tesserato_1campo pmax ON pmax.codass = p.codass AND pmax.id_tesserato = p.id_tesserato
JOIN tesserato T ON p.codass = T.codass AND p.id_tesserato = T.cf
JOIN campo c ON c.codass = p.codass AND p.id_campo = c.id
JOIN tipologia_campo tc ON tc.codass = p.codass AND tc.id = c.tipologia
JOIN sede s ON s.codass = p.codass AND s.codice = p.sede
WHERE p.codass = 'POLRM' AND extract(YEAR from P.data) = extract(year from CURRENT_DATE)-1
GROUP BY p.id_tesserato, p.id_campo, pmax.max, T.cognome, T.nome, p.sede, s.nome, tc.sport
HAVING count(*) = pmax.max AND count(*) > 2
ORDER BY pmax.max DESC, cognome, nome;


/* --------------------------- */
/* --------- INDEXES --------- */
/* --------------------------- */

DROP INDEX IF EXISTS idx_istat_citta;
CREATE INDEX idx_istat_citta ON citta ( istat );

DROP INDEX IF EXISTS idx_dipendenti;
CREATE INDEX idx_dipendenti ON dipendente ( codass , cf );