DROP TABLE Zaznam CASCADE CONSTRAINTS;
DROP TABLE Kus CASCADE CONSTRAINTS;
DROP TABLE Doplnky CASCADE CONSTRAINTS;
DROP TABLE Zamestnanec CASCADE CONSTRAINTS;
DROP TABLE Kostym CASCADE CONSTRAINTS;
DROP TABLE Kategoria_kostymu CASCADE CONSTRAINTS;
DROP TABLE Vyrobca CASCADE CONSTRAINTS;
DROP TABLE Klient CASCADE CONSTRAINTS;
DROP TABLE Sukromna_osoba CASCADE CONSTRAINTS;
DROP TABLE Firma CASCADE CONSTRAINTS;

DROP MATERIALIZED VIEW vyr_view;


DROP TABLE Spravuje CASCADE CONSTRAINTS;
DROP TABLE Vyrobil CASCADE CONSTRAINTS;
DROP TABLE Patri CASCADE CONSTRAINTS;

CREATE TABLE Zaznam (
id INTEGER,
Datum_vypozicania DATE,
Datum_vratenia DATE,
Celkova_cena INTEGER 
);

CREATE TABLE Kus (
id INTEGER,
Farba VARCHAR(20),
Velkost INTEGER 
);

CREATE TABLE Doplnky (
id INTEGER ,
Nazov VARCHAR(20),
Datum_vyroby DATE,
Popis_vyuzitia VARCHAR(50),
Pocet_pouziti INTEGER, 
Cislo_zamestnanca INTEGER
);

CREATE TABLE Zamestnanec (
Cislo_zamestnanca INTEGER,
Meno VARCHAR(20),
Priezvisko VARCHAR(20),
Adresa VARCHAR(20),
Kontakt VARCHAR(20)
);

CREATE TABLE Kostym (
id INTEGER,
Nazov VARCHAR(20),
Datum_vyroby DATE,
Pocet_pouziti INTEGER,
id2 INTEGER,--id vyrobcu
id3 INTEGER --id kategorie koatymu
);

CREATE TABLE Kategoria_kostymu (
id INTEGER,
Nazov VARCHAR(20),
Osoba_vyuzitia VARCHAR(20),
Prilezitost VARCHAR(20)
);

CREATE TABLE Vyrobca (
id INTEGER,
Meno VARCHAR(20),
Obdobie_posobenia VARCHAR(23),
Kontakt INTEGER,
id2 INTEGER,
id22 INTEGER
);

CREATE TABLE Klient (
id INTEGER,
Meno VARCHAR(20),
Adresa VARCHAR(20),
Kontakt INTEGER
);

CREATE TABLE Sukromna_osoba (
id INTEGER,
Rodne_cislo NUMERIC(10,0),
Datum_narodenia DATE 
);

CREATE TABLE Firma (
id INTEGER,
ICO INTEGER,
DIC VARCHAR(12)
);



CREATE TABLE Spravuje(
id INTEGER,
Cislo_zamestnanca INTEGER
);

CREATE TABLE Vyrobil (
id INTEGER,
id2 INTEGER
);

CREATE TABLE Patri(
id INTEGER,
id3 INTEGER
);


ALTER session SET nls_date_format='dd.mm.yy';
SET serveroutput ON;
CREATE TRIGGER tr_rodne_cislo
    BEFORE INSERT OR UPDATE OF Rodne_cislo ON Sukromna_osoba
    FOR EACH ROW
DECLARE
    rc Sukromna_osoba.Rodne_cislo%TYPE;
    den NUMBER(2);
    mesiac NUMBER(2);
    rok NUMBER(2);
    datum DATE;
BEGIN
    rc:= :NEW.Rodne_cislo;
    mesiac:= MOD ((rc/1000000),100);
    den:= MOD ((rc/10000),100);
    rok:= rc/100000000;
    
    IF(MOD(rc,11)<>0) THEN
        Raise_Application_Error (-20203,'Neplatne rodne cislo: nie je delitelne 11');
    END IF;
    
    IF(mesiac>50) THEN
        mesiac:=mesiac-50;
    END IF;    
    
    BEGIN
        datum:= den||'.'||mesiac||'.'||rok;
    EXCEPTION
        WHEN OTHERS THEN
             Raise_Application_Error (-20204,'Neplatne datum v rodnom cisle');
        END;
   END tr_rodne_cislo;
   /
show errors        


--trigger na kontrolu DIC

ALTER session SET nls_date_format='dd.mm.yy';
SET serveroutput ON;
CREATE OR REPLACE TRIGGER tr_dic
    BEFORE INSERT OR UPDATE OF DIC ON Firma
    FOR EACH ROW
DECLARE
    dic_for_tr Firma.DIC%TYPE;
    stat VARCHAR(2);
    cisla VARCHAR(10);
    
BEGIN
    dic_for_tr:= :NEW.DIC;
    stat:= SUBSTR(dic_for_tr,1,2);
    cisla:= SUBSTR(dic_for_tr,3,10);
    
    
    IF(LENGTH(dic_for_tr)<10 OR LENGTH(dic_for_tr)>12 ) THEN
        Raise_Application_Error (-20203,'Neplatny format DIC');
    END IF;
    
    IF(LENGTH(TRIM(TRANSLATE(stat,'ABCDEFGHIJKLMNOPQRSTUVWXYZ',''))) !=null) THEN
        Raise_Application_Error (-20203,'Neplatny format DIC');
    END IF;  
    
    IF(LENGTH(TRIM(TRANSLATE(stat,'0123456789',''))) !=null) THEN
        Raise_Application_Error (-20203,'Neplatny format DIC');
    END IF;   
  
   END tr_dic;
   /
show errors       

--procedura percento danej farby kostymov 

ALTER session SET nls_date_format='dd.mm.yy';
SET serveroutput ON;
CREATE OR REPLACE PROCEDURE proc_farba (Farba in VARCHAR)
    IS CURSOR farby IS SELECT *FROM Kus;
    info farby%ROWTYPE;
    pocet_vsetkych NUMBER;
    pocet_konkretnej NUMBER;
   
BEGIN
    pocet_vsetkych:=0;
    pocet_konkretnej:=0;
    OPEN farby;
    LOOP
    FETCH farby INTO info;
    EXIT WHEN farby%NOTFOUND;
    
    IF(TRIM(info.Farba)=Farba) THEN
        pocet_konkretnej := pocet_konkretnej+1;    
    END IF;
    
    IF(info.Farba IS NOT NULL) THEN
        pocet_vsetkych := pocet_vsetkych+1;    
    END IF;
   
    END LOOP;
    CLOSE farby;
    dbms_output.put_line('Mame '|| pocet_vsetkych || ' farby, z toho ' || Farba || ' farba je zastupena ' || pocet_konkretnej || 'krat, percentulne to je ' ||pocet_konkretnej/pocet_vsetkych *100 || ' percent' );
    EXCEPTION WHEN ZERO_DIVIDE THEN 
    dbms_output.put_line('Nemame ziadne farby');
    WHEN OTHERS THEN
    Raise_Application_Error (-20206,'Chyba pri hladani farby');  
    END;
   /
  show errors
  
  --procedura na najdenie najvyssej ceny za pozicany kostym

ALTER session SET nls_date_format='dd.mm.yy';
SET serveroutput ON;
CREATE OR REPLACE PROCEDURE proc_cena (Celkova_cena in INTEGER)
    IS CURSOR max_cena IS SELECT *FROM Zaznam;
    info max_cena%ROWTYPE;
    cena_max NUMBER;
    cena_vypozicky NUMBER;
   
BEGIN
    cena_max:=0;
    cena_vypozicky:=0;
    OPEN max_cena;
    LOOP
    FETCH max_cena INTO info;
    EXIT WHEN max_cena%NOTFOUND;
       
     IF(TRIM(info.Celkova_cena)=Celkova_cena) THEN
        cena_vypozicky := cena_vypozicky+Celkova_cena ;    
    END IF;
    IF(cena_vypozicky>cena_max) THEN
        cena_max:=cena_vypozicky;
    END IF;
      
    END LOOP;
    
    CLOSE max_cena;
    dbms_output.put_line('Najvyssia cena je ' || cena_max || ' . ');
    EXCEPTION WHEN OTHERS THEN
    Raise_Application_Error (-20207,'Chyba pri hladani najvyssej ceny');  
    END;
   /
  show errors
  
  
ALTER TABLE Zaznam ADD CONSTRAINT PK_Zaznam PRIMARY KEY (id);
ALTER TABLE Kus ADD CONSTRAINT PK_Kus PRIMARY KEY (id);
ALTER TABLE Doplnky ADD CONSTRAINT PK_Doplnky PRIMARY KEY (id);
ALTER TABLE Zamestnanec ADD CONSTRAINT PK_Zamestnanec PRIMARY KEY (Cislo_zamestnanca);
ALTER TABLE Kostym ADD CONSTRAINT PK_Kostym PRIMARY KEY (id);
ALTER TABLE Kategoria_kostymu ADD CONSTRAINT PK_Katgoria_kostimu PRIMARY KEY (id);
ALTER TABLE Vyrobca ADD CONSTRAINT PK_Vyrobca PRIMARY KEY (id);
ALTER TABLE Klient ADD CONSTRAINT PK_Klient PRIMARY KEY (id);
ALTER TABLE Sukromna_osoba ADD CONSTRAINT FK_Sukromna_osoba FOREIGN KEY (id) REFERENCES Klient; 
ALTER TABLE Firma ADD CONSTRAINT FK_Firma FOREIGN KEY (id) REFERENCES Klient;

ALTER TABLE Spravuje ADD CONSTRAINT PK_Spravuje PRIMARY KEY (id,Cislo_zamestnanca);
ALTER TABLE Vyrobil ADD CONSTRAINT PK_Vyrobil PRIMARY KEY (id,id2);
ALTER TABLE Patri ADD CONSTRAINT PK_Patri PRIMARY KEY (id,id3);


INSERT INTO Zaznam (id,Datum_vypozicania,Datum_vratenia,Celkova_cena)
VALUES('17834596',TO_DATE('16.01.2018','dd.mm.yyyy'),TO_DATE('25.02.2018','dd.mm.yyyy'),'1000');
INSERT INTO Zaznam (id,Datum_vypozicania,Datum_vratenia,Celkova_cena)
VALUES('21397546',TO_DATE('19.05.2012','dd.mm.yyyy'),TO_DATE('19.10.2012','dd.mm.yyyy'),'1500');

INSERT INTO Kus (id, Farba, Velkost)
VALUES('90856473','ruzova', '38');
INSERT INTO Kus (id, Farba, Velkost)
VALUES('80754631','modra', '40');
INSERT INTO Kus (id, Farba, Velkost)
VALUES('75643218','cierna', '26');

INSERT INTO Vyrobca (id, Meno, Obdobie_posobenia,Kontakt, id2, id22)
VALUES('12346598','Slniecko','1996 - 2008','905036079', '40365400', '40352306');
INSERT INTO Vyrobca (id, Meno, Obdobie_posobenia,Kontakt, id2, id22)
VALUES('21397546','Albi', '1991 - súcastnost','730800720', '40378901', '40352302');


INSERT INTO Klient (id, Meno, Adresa, Kontakt)
VALUES('00001234','Lucia Benková', 'Hlavná 18 Trnava', '907638489');
INSERT INTO Klient (id, Meno, Adresa, Kontakt)
VALUES('00001235','OTE', 'Božetechova 87 Praha','789654123');
INSERT INTO Klient (id, Meno, Adresa, Kontakt)
VALUES('00001236','Tank ONO','Èeská 68 Plzeò','789632541');
INSERT INTO Klient (id, Meno, Adresa, Kontakt)
VALUES('00001237','Richard Novak', 'Masna 46 Brno', '907638459');

INSERT INTO Firma (id, ICO, DIC)
VALUES('00001235','26463318','CZ16ddd77');                                  
INSERT INTO Firma (id, ICO, DIC)
VALUES('00001236','48365289','CZ1917256978');

INSERT INTO Sukromna_osoba (id, Rodne_cislo, Datum_narodenia)
VALUES('00001234','9758278694',TO_DATE('27.08.1997','dd.mm.yyyy'));
INSERT INTO Sukromna_osoba (id, Rodne_cislo, Datum_narodenia)
VALUES('00001237','9662163918',TO_DATE('16.12.1996','dd.mm.yyyy'));


INSERT INTO Zamestnanec (Cislo_zamestnanca, Meno, Priezvisko, Adresa, Kontakt)
VALUES('06196258','Nina','Wolk','Slovanská 66 Olomouc','904535817');
INSERT INTO Zamestnanec (Cislo_zamestnanca, Meno, Priezvisko, Adresa, Kontakt)
VALUES('05196438','Mia','Harper','Úzka 99 Ostrava','914639812');
INSERT INTO Zamestnanec (Cislo_zamestnanca, Meno, Priezvisko, Adresa, Kontakt)
VALUES('04194568','Patricia','Crosby','Srbská 42 Bratislava','904562823');

--id2 je id kategorie kostymu
--id3 je id vyrobcu kostymu

INSERT INTO Kostym (id, Nazov, Datum_vyroby, Pocet_pouziti, id2, id3)
VALUES('40365400','Batman',TO_DATE('10.08.2007','dd.mm.yyyy'),'11', '12346598', '40569822');
INSERT INTO Kostym (id, Nazov, Datum_vyroby, Pocet_pouziti, id2, id3)
VALUES('40378901','Catwoman',TO_DATE('25.10.2010','dd.mm.yyyy'),'5', '21397546', '32569411');
INSERT INTO Kostym (id, Nazov, Datum_vyroby, Pocet_pouziti, id2, id3)
VALUES('40352302','Cert',TO_DATE('11.04.2005','dd.mm.yyyy'),'8', '21397546', '32417355');
INSERT INTO Kostym (id, Nazov, Datum_vyroby, Pocet_pouziti, id2, id3)
VALUES('40352306','Princezná',TO_DATE('11.07.2000','dd.mm.yyyy'),'28', '12346598', '32417345');


INSERT INTO Kategoria_kostymu (id, Nazov, Osoba_vyuzitia, Prilezitost)
VALUES('40569822','Filmová postava','muz','akcia');
INSERT INTO Kategoria_kostymu (id, Nazov, Osoba_vyuzitia, Prilezitost)
VALUES('32569411','Filmová postava','zena','akcia');
INSERT INTO Kategoria_kostymu (id, Nazov, Osoba_vyuzitia, Prilezitost)
VALUES('32417355','Bytost','dieta','sviatok');
INSERT INTO Kategoria_kostymu (id, Nazov, Osoba_vyuzitia, Prilezitost)
VALUES('32417345','Rozprávka','dieta','akcia');

INSERT INTO Doplnky (id, Nazov, Datum_vyroby, Popis_vyuzitia, Pocet_pouziti, Cislo_zamestnanca)
VALUES('40352673','vidli',TO_DATE('23.01.2004','dd.mm.yyyy'),'Skvele sa hodí ku kostýmu certa','15','06196258');
INSERT INTO Doplnky (id, Nazov, Datum_vyroby, Popis_vyuzitia, Pocet_pouziti, Cislo_zamestnanca)
VALUES('40983523','bic',TO_DATE('21.11.2011','dd.mm.yyyy'),'Vhodný ku kostýmu catwoman a certa','20','06196258');
INSERT INTO Doplnky (id, Nazov, Datum_vyroby, Popis_vyuzitia, Pocet_pouziti, Cislo_zamestnanca)
VALUES('40213523','pistol',TO_DATE('05.12.2003','dd.mm.yyyy'),'Pouzíva sa ku kostýmu batmana','10','05196438');
INSERT INTO Doplnky (id, Nazov, Datum_vyroby, Popis_vyuzitia, Pocet_pouziti, Cislo_zamestnanca)
VALUES('40212623','koruna',TO_DATE('25.03.2006','dd.mm.yyyy'),'Pouzíva sa ku kostýmu princeznej','18','04194568');


INSERT INTO Spravuje (id, Cislo_zamestnanca)
VALUES('40212623','04194568');
INSERT INTO Spravuje (id, Cislo_zamestnanca)
VALUES('40213523','05196438');
INSERT INTO Spravuje (id, Cislo_zamestnanca)
VALUES('40983523','06196258');
INSERT INTO Spravuje (id, Cislo_zamestnanca)
VALUES('40352673','06196258');

INSERT INTO Patri (id, id3)
VALUES('40365400','40569822');
INSERT INTO Patri (id, id3)
VALUES('40378901','32569411');
INSERT INTO Patri (id, id3)
VALUES('40352302','32417355');
INSERT INTO Patri (id, id3)
VALUES('40352306','32417345');

INSERT INTO Vyrobil (id, id2)
VALUES('40365400','12346598');
INSERT INTO Vyrobil (id, id2)
VALUES('40378901','21397546');
INSERT INTO Vyrobil (id, id2)
VALUES('40352302','21397546');
INSERT INTO Vyrobil (id, id2)
VALUES('40352306','12346598');

--spojenie 2 tabuliek
--vypise adresu a kontakt na zamestnanca s menom Nina

SELECT 
Z.Adresa,
Z.Kontakt
FROM 
Zamestnanec Z, 
Doplnky D
WHERE
Z.Cislo_zamestnanca = D.Cislo_zamestnanca
AND
Z.Meno='Nina';

--spojenie 2 tabuliek
--vypise nazov a pocet pouziti doplnku ktorý spravoval zamestnanec s priezviskom Crosby

SELECT
D.Nazov,
D.Pocet_pouziti
FROM
Zamestnanec Z, 
Doplnky D
WHERE
Z.Cislo_zamestnanca = D.Cislo_zamestnanca
AND
Z.Priezvisko='Crosby';


--spojenie 3 tabuliek
--vypise nazov kostymu, meno toho kto kostym vyrobil, a nazov kategorie kostymu

SELECT
K.Nazov,
V.Meno ,
KK.Nazov
FROM
Kostym K,
Kategoria_kostymu KK,
Vyrobca V
WHERE
K.id3=KK.id AND K.id2=V.id;

--GROUP BY a agregaèná funkcia
--vypise pocet danych osob vyuzitia 

SELECT 
KK.Osoba_vyuzitia,
COUNT(KK.Osoba_vyuzitia)
FROM
Kategoria_kostymu KK
GROUP BY 
KK.Osoba_vyuzitia;

--GROUP BY a agregaèná funkcia
--vypise pocet danych prilezitostí

SELECT
KK.Prilezitost, 
COUNT(KK.Prilezitost)
FROM
Kategoria_kostymu KK
GROUP BY
KK.Prilezitost;

--IN s vnorenym selectom
--vypise informacie o kostyme ktory vyrobila firma slniecko

SELECT *
FROM Kostym K
WHERE K.id
IN (
    SELECT V.id2
    FROM Vyrobca V
    WHERE V.Meno='Slniecko'
);

--EXIST 
--vypise informacie o doplnkoch, ktore spravovala ina osoba, ako ta, ktorej patri kontakt '904562823'

SELECT D.*
FROM Doplnky D, Zamestnanec Z
WHERE Z.Cislo_zamestnanca = D.Cislo_zamestnanca AND 
EXISTS( 
    SELECT *
    FROM Zamestnanec Z
    WHERE Z.Cislo_zamestnanca = D.Cislo_zamestnanca AND
    Z.KONTAKT<>'904562823'
);

--udelenie prav

GRANT ALL ON Zaznam TO xjendr03;
GRANT ALL ON Kus TO xjendr03;
GRANT ALL ON Doplnky TO xjendr03;
GRANT ALL ON Zamestnanec TO xjendr03;
GRANT ALL ON Kostym TO xjendr03;
GRANT ALL ON Kategoria_kostymu TO xjendr03;
GRANT ALL ON Vyrobca TO xjendr03;
GRANT ALL ON Klient TO xjendr03;
GRANT ALL ON Sukromna_osoba TO xjendr03;
GRANT ALL ON Firma TO xjendr03;

GRANT EXECUTE ON proc_farba TO xjendr03;
GRANT EXECUTE ON proc_cena TO xjendr03;

--explain plan a index 



EXPLAIN PLAN 
SET STATEMENT_ID 'myexplainplan'  FOR
SELECT Meno, AVG(Pocet_pouziti)
FROM Vyrobca NATURAL JOIN Kostym
GROUP BY Pocet_pouziti,Meno;
 
SELECT PLAN_TABLE_OUTPUT 
FROM TABLE(dbms_xplan.display('plan_table','myexplainplan','typical'));

CREATE INDEX index_explain ON Vyrobca (Meno);

EXPLAIN PLAN FOR
SELECT Meno, AVG(Pocet_pouziti)
FROM Vyrobca NATURAL JOIN Kostym
GROUP BY Pocet_pouziti,Meno;
SELECT* FROM TABLE(dbms_xplan.display);

DROP INDEX index_explain;
REVOKE ALL ON Vyrobca FROM xjendr03;
GRANT SELECT,UPDATE,INSERT,DELETE ON Vyrobca TO xjendr03;

--materializovany pohlad

CREATE MATERIALIZED VIEW vyr_view
NOLOGGING
CACHE
BUILD IMMEDIATE
REFRESH ON COMMIT
AS SELECT Meno FROM Vyrobca;
GRANT SELECT ON vyr_view TO xjendr03;



-- procedura vyrata percentualne zastupenie ruzovej
  exec proc_farba('ruzova');
  exec proc_cena('1500');
