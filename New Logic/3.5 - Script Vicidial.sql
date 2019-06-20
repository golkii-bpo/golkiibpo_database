create database EFNI;

use EFNI;

create table Telefonos
(
  Telefono int,
  CalledCount int,
  LastCalled datetime,
  Tipificacion varchar(20)
);

create procedure LoadTempData (in D datetime)
begin
	truncate table EFNI.Telefonos;
	insert into EFNI.Telefonos (Telefono,CalledCount,LastCalled,Tipificacion)
	select 
		a.phone_number,
		a.called_count,
		a.call_date,
		a.status 
	from 
		asterisk.vicidial_log a 
	where 
		a.campaign_id = 'EFNI' and a.call_date > '2019-06-10 00:00:00' and a.phone_number REGEXP '^[2,5,7,8,9]{1}[0-9]{7}$';
end;

create procedure CleanTempData()
begin
	truncate table EFNI.Telefonos;
end;

