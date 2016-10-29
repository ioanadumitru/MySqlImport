
use proiectMySql;

SET FOREIGN_KEY_CHECKS=0;

call init();

SET FOREIGN_KEY_CHECKS=1;

load data local infile 'C:\\Users\\Ioana\\Downloads\\sql_pfinal_date\\medici.txt' 
    into table medici
	fields terminated by ','
	lines terminated by '\n'
	ignore 1 lines
    (nume, prenume, statut, specialitate);

load data local infile 'C:\\Users\\Ioana\\Downloads\\sql_pfinal_date\\vizite.txt' 
    into table clinicaMedicala
	fields terminated by ','
	lines terminated by '\n'
	ignore 190000 lines;


delimiter $
create procedure insertPacienti()
begin
	declare n, p, nP, pp varchar(40);
    declare nr int default 0;
   
	DECLARE cursorPacienti CURSOR FOR 
    select  NumePacient,  PrenumePacient from clinicaMedicala;
    DECLARE EXIT HANDLER FOR 1329 BEGIN END;
    
	open cursorPacienti;
    bucla:loop
    
    FETCH cursorPacienti INTO n, p;
    
    set nr = (select count(*) from pacienti where nume = n and prenume = p);
    
	if nr > 0 then
		ITERATE bucla;
	end if;
  
	insert into pacienti(nume, prenume) values(n, p);
	end loop;
end$
delimiter ;

call insertPacienti();


delimiter $
create procedure insertIntoCabinete()
begin
	declare den varchar(40);
    declare nr int default 0;
   
	DECLARE cursorClinica CURSOR FOR 
    select  Cabinet from clinicaMedicala;
    DECLARE EXIT HANDLER FOR 1329 BEGIN END;
    
	open cursorClinica;
    bucla:loop
    
    FETCH cursorClinica INTO den;
    
    set nr = (select count(*) from cabinete where denumire = den);
    
	if nr > 0 then
		ITERATE bucla;
	end if;
  
	insert into cabinete(denumire) values(den);
	end loop;
end$
delimiter ;


call insertIntoCabinete();

set @dt = now();

delimiter $
create procedure insertIntoVizite()
begin
	declare dat, numeP, prenumeP, numeM, prenumeM, den, fullDate varchar(40);
    declare oraI time;
    declare dt datetime;
    declare nr, idP, idM, idC int default 0;
   
	DECLARE cursorVizite CURSOR FOR 
    select  DataVizita, OraIntrare, NumePacient, PrenumePacient, NumeMedic, PrenumeMedic, Cabinet 
    from clinicaMedicala;
    DECLARE EXIT HANDLER FOR 1329 BEGIN END;
    
	open cursorVizite;
    bucla:loop
    
    FETCH cursorVizite INTO dat, oraI, numeP, prenumeP, numeM, prenumeM, den;
    
     set fulldate =  concat(dat,' ', oraI);
        
	 set @dt = STR_TO_DATE(fulldate, '%e/%c/%Y %H:%i');
	 set idP = (select idPacient from Pacienti where nume = numeP and prenume = prenumeP);
	 set idM = (select idMedic from Medici where nume = numeM and prenume = prenumeM);
     set idC = (select idCabinet from cabinete where denumire = den);
    
	insert into vizite values(@dt, idM, idP, idC);
	end loop;
end$
delimiter ;

call insertIntoVizite();

call updateDatabase();
# generare rapoarte
call GenerareRapoarte();
call istoricPacient();
call rapoarte();

