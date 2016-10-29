
use proiectMySql;

set @idP=0, @idC=0, @idM=0;

SET FOREIGN_KEY_CHECKS=0;

call init();

SET FOREIGN_KEY_CHECKS=1;

delimiter $
create trigger popularePacienti before insert on clinicaMedicala
for each row 
begin
	
		DECLARE dublare CONDITION FOR 1062;

		DECLARE CONTINUE handler for dublare
		hand: begin
		INSERT INTO logs VALUES(NOW(), new.numePacient);
        
		end hand;
		
        insert into pacienti(nume, prenume) values(new.numePacient, new.prenumePacient);
		
end$
delimiter ;


delimiter $
create trigger populareCabinete before insert on clinicaMedicala
for each row 
begin
	
		DECLARE dublare CONDITION FOR 1062;

		DECLARE CONTINUE handler for dublare
		hand: begin
		
		INSERT INTO logs VALUES(NOW(), new.Cabinet);
		end hand;
    
		insert into cabinete(denumire) values(new.Cabinet);
end$
delimiter ;

set @fullDate = '';

delimiter $
create trigger populareVizite before insert on clinicaMedicala
for each row 
begin     
        select idMedic from medici where new.numeMedic = nume and prenume = new.prenumeMedic into @idM;
		select idPacient from pacienti where new.numePacient = nume and prenume = new.PrenumePacient into @idP; 
        select idCabinet from cabinete where new.Cabinet = denumire into @idC;
        
        set @fulldate =  concat(NEW.dataVizita,' ', new.OraIntrare);
        
		set @dt = STR_TO_DATE(@fulldate, '%e/%c/%Y %H:%i');
		insert into vizite values(@dt, @idM, @idP, @idC);
end$
delimiter ;

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

call updateDatabase();
call GenerareRapoarte();
call istoricPacient();
call rapoarte();


