drop database if exists proiectMySql;
create database proiectMySql;
use proiectMySql;

delimiter $
create procedure init()
begin
	 drop table if exists medici, pacienti, cabinete;
     drop table if exists clinicamedicala;
     drop table if exists vizite;
	 drop table if exists logs;
    create table medici(nume varchar(40), prenume varchar(40), statut enum('primar', 'specialist'),
						specialitate varchar(40), idMedic int primary key auto_increment, 
                        UNIQUE UniqueIndex(nume, prenume));
                        
	create table pacienti(nume varchar(40), prenume varchar(40),
						idPacient int primary key auto_increment, 
                        UNIQUE UniqueIndex(nume, prenume));
    create table cabinete(denumire varchar(40), idCabinet int primary key auto_increment, 
						UNIQUE UniqueIndex(denumire));
  
	create table vizite(dataSiOra datetime, idMedic int, idPacient int, idCabinet int,
						foreign key(idMedic) references medici(idMedic) on delete cascade, 
                        foreign key (idPacient) references pacienti(idPacient) on delete cascade, 
                        foreign key (idCabinet) references cabinete(idCabinet) on delete cascade);
                        
	create table clinicaMedicala(DataVizita varchar(12),
								 OraIntrare time, NumePacient varchar(40),
                                 PrenumePacient varchar(40), NumeMedic varchar(40),
                                 PrenumeMedic varchar(40), Cabinet varchar(40));
	
    CREATE TABLE logs(Moment DATETIME, Coment TEXT);
end$
delimiter ;

SET FOREIGN_KEY_CHECKS=0;
call init();
SET FOREIGN_KEY_CHECKS=1;

load data local infile 'C:\\Users\\Ioana\\Downloads\\sql_pfinal_date\\vizite.txt' 
    into table clinicaMedicala
	fields terminated by ','
	lines terminated by '\n'
    ignore 190000 lines;
    

load data local infile 'C:\\Users\\Ioana\\Downloads\\sql_pfinal_date\\medici.txt' 
    into table medici
	fields terminated by ','
	lines terminated by '\n'
	ignore 1 lines
    (nume, prenume, statut, specialitate);


insert into pacienti(nume, prenume) select distinct numePacient, prenumePacient from clinicaMedicala; 

insert into cabinete(denumire) select distinct cabinet from clinicaMedicala;

alter table clinicamedicala add column(idMedic int, idPacient int, idCabinet int);


update clinicamedicala join medici on numeMedic=nume and prenumeMedic = prenume 
						set clinicamedicala.idMedic = medici.idMedic;

update clinicamedicala inner join pacienti on numePacient = nume
						and prenumePacient = prenume
						set  clinicamedicala.idPacient = pacienti.idPacient;
                        

update clinicamedicala join cabinete on clinicamedicala.cabinet = cabinete.denumire 
						set clinicamedicala.idCabinet = cabinete.idCabinet;

                    
alter table clinicaMedicala add column fulldate varchar(20);          
update clinicaMedicala set fulldate = (select concat(dataVizita, ' ', OraIntrare));          


insert into vizite select str_to_date(fulldate, '%d/%m/%Y %H:%i:%s'), 
					idMedic, idPacient, idCabinet from clinicamedicala;


delimiter $
create procedure ViewTables()
begin
	select * from clinicaMedicala;
	select * from medici;
	select * from pacienti;
	select * from cabinete;
    select * from vizite;
end$
delimiter ;


call viewTables;


delimiter $
create function generareData(varstaMin int, varstaMax int) returns date not deterministic
begin
		DECLARE a date;
		select curdate()- interval(varstaMin) year -
				interval(floor(rand()*((varstaMax - varstaMin)*365+13))) day into a;
        return a;
end$ 
delimiter ;

delimiter $
create function generateDurata() returns int not deterministic
begin
		return (5 + rand()*25);
end$
delimiter ;

update vizite set durata = generateDurata();


#rapoarte
delimiter $
create function varsta(d date) returns int deterministic
begin 
	declare v int;
	select year(current_date()) - year(d) into v;
	return v;
end$
delimiter ;

#functie pentru generarea unui nr random
delimiter $
create function randomNumber(m int, ma int) returns int not deterministic
begin
	
    return (floor(m + rand()*(ma - m)));
	
end$
delimiter ;


delimiter $
create procedure updateDatabase()
begin
	drop table clinicaMedicala;

	alter table vizite add column durata int;
	alter table pacienti add column ziNastere date;
	
	update pacienti set ziNastere = generareData(20, 80);
    update vizite set durata = generateDurata();
end$
delimiter ;

call updateDatabase();

#procedura care produce urmatoarele rapoarte
delimiter $
create procedure GenerareRapoarte()
begin
		#cei mai varstnici 20 de pacienti
		select concat(nume,' ', prenume) as numeComplet, varsta(ziNastere) as varsta from pacienti
			order by varsta desc limit 20;
        
        #nr pacienti pe segmentul de varsta 60-70 de ani
		select count(*) from pacienti where varsta(ziNastere) between 60 and 70;
        
        #lista specialitatilor + numarul de medici 
        select specialitate, count(*) as nrMedici from medici group by specialitate;   
        
        #care este specialitatea la care s-au prezentat cei mai multi bolnavi
        select specialitate, count(idPacient) as nr from vizite join medici using(idMedic) 
		group by specialitate order by nr desc limit 1;
        
        #care este pacientul cu cele mai multe vizite la clinica        
		select count(idPacient) as nr, concat(nume,' ', prenume) from pacienti
        join vizite using (idPacient)
		group by idPacient order by nr desc limit 1;
        
        #care sunt medicii care au consultat mai putin de 250 de pacienti in anul 2009     
		select nume,  prenume, specialitate, year(dataSiOra), count(idMedic) as n from vizite 
			join medici using(idMedic)
            where year(dataSiOra) = 2009
            group by idMedic having n<250;
        
        #care sunt medicii care nu figureaza in evidente cu nicio vizita            
		select nume,  prenume, specialitate, count(idMedic) as n from vizite 
			join medici using(idMedic) group by idMedic  having n<1;
		
        #care sunt pacientii care au cel putin 20 de vizite in weekend
		select nume,  prenume, count(idPacient) as nrVizite from vizite 
			join pacienti using(idPacient) 
            where weekday(dataSiOra) in (5,6) 
            group by idPacient 
            having nrVizite>=20; 
            
		#istoricul (ordonat cronologic) al vizitelor unui pacient        
		select dataSiOra from vizite join pacienti using (idPacient) 
			where idPacient = randomNumber(1, 100);      
end$
delimiter ;
 
call GenerareRapoarte();
 

delimiter $
create procedure istoricPacient()
begin
		declare id int default 0;
		set id = randomNumber(1, 100);
		select dataSiOra from vizite join pacienti using (idPacient) where idPacient =id
		order by dataSiOra;

end$
delimiter ;

call istoricPacient();
                
delimiter $                
create procedure rapoarte()
begin
		declare id int default 0;
		set id = randomNumber(1, 100);
        
        #varsta medie a pacientilor pentru fiecare specialitate in parte in afara de pediatrie
		select avg(varsta(ziNastere)), specialitate from medici 
					join vizite using(idMedic)
                    join pacienti using(idPacient)
					where specialitate not like 'pediatrie'
					group by specialitate;

		select dataSiOra, denumire, concat( medici.nume, ' ', medici.prenume) as numeMedic, specialitate, 
				concat(pacienti.nume, ' ',pacienti.prenume) as NumePacient from pacienti
				join vizite using(idPacient)
				join medici using(idMedic)
				join cabinete using(idCabinet)
				where idPacient = id;

end$
delimiter ;

call rapoarte();
