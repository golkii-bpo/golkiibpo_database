

/*SE INGRESAN TODAS LAS PERSONAS QUE NO SE ENCUENTRA REGISTRADAS*/
;WITH cte_data
AS
(
	SELECT A.Cedula FROM dbo.DB_22052019 A WHERE A.Cedula LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][A-z]'
	EXCEPT
	SELECT a.Cedula FROM BaseControl.dbo.Persona A WHERE A.Cedula LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][A-z]' GROUP BY a.Cedula
),cte_persona
AS
(
	SELECT B.Nombres,B.Cedula, B.departamento,B.municipio,B.salario FROM cte_data A INNER JOIN dbo.DB_22052019 B ON A.Cedula = B.Cedula
)
SELECT
	1 [IdProcedencia]
	,A.Nombres
	,A.Cedula
	,A.salario
	,A.departamento
	,A.municipio
	,GETDATE() [FechaIngreso]
	,1 [Estado]
INTO #TempPersonas
FROM cte_persona A

INSERT INTO BaseControl.dbo.Persona
(
    IdProcedencia,
    Nombre,
    Cedula,
    Salario,
    Departamento,
    Municipios,
    FechaIngreso,
    Estado
)

SELECT 
	A.IdProcedencia,
	A.Nombres,
	A.Cedula,
	A.salario,
	A.departamento,
	A.municipio,
	A.FechaIngreso,
	A.Estado
 FROM #TempPersonas A 

 GO
 WITH cte_Data 
 AS
 (
	SELECT * FROM dbo.DB_22052019 A 
 )
 GO

 /*SE ACTUALIZA EL INSS DE LA BASE NUEVA QUE SE ESTA REGISTRADO*/
 ;WITH cte_INSS
 AS
 (
	SELECT A.CEDULA COLLATE Modern_Spanish_CI_AS [Cedula],SUM(A.SALARIO) [Salario] FROM REFCOMERCIAL.dbo.infoINSS A WHERE A.disponible = 1 GROUP BY A.CEDULA
 )

UPDATE B SET B.IsWorking = 1,B.SalarioInss = A.Salario FROM cte_INSS A INNER JOIN BaseControl.dbo.Persona B ON B.Cedula = A.Cedula WHERE B.IsWorking = 0

GO

/*INGRESAMOS TELEFONOS QUE NO HAY EN BASE DE DATOS*/
WITH cte_telefonosD
AS
(
	SELECT
		B.Cedula,
		STR(B.Tel,8,0) [Telefonos] 
	FROM 
		DB_22052019 A
		UNPIVOT(Tel FOR [Col] IN (a.Telefono,a.Telefono1)) B
	WHERE
		B.Tel IS NOT NULL
),cte_telefonos
AS
(
	SELECT a.Cedula [Cedula],A.Telefonos FROM cte_telefonosD A WHERE A.Telefonos LIKE '[2,5,7,8,9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' GROUP BY A.Telefonos,a.Cedula
)
INSERT INTO BaseControl.dbo.Telefonos
(
    IdPersona,
    Telefono,
    FechaIngreso,
    Estado,
    IdProcedencia
)
SELECT 
	B.IdPersona,
	A.Telefonos,
	GETDATE(),
	1,
	1 
FROM 
	cte_telefonos A
	INNER JOIN BaseControl.dbo.Persona B ON B.Cedula = A.Cedula

GO

/*SE VA HA ACTUALIZAR LOS NUMEROS DE TELEFONOS */
WITH cte_telefonosD
AS
(
	SELECT
		B.Cedula,
		STR(B.Tel,8,0) [Telefonos] 
	FROM 
		DB_22052019 A
		UNPIVOT(Tel FOR [Col] IN (a.Telefono,a.Telefono1)) B
	WHERE
		B.Tel IS NOT NULL
),cte_telefonos
AS
(
	SELECT CAST(A.Telefonos AS INT) [Telefonos],B.IdPersona
	FROM 
	cte_telefonosD A
	INNER JOIN BaseControl.dbo.Persona B ON A.Cedula = B.Cedula
	WHERE A.Telefonos LIKE '[2,5,7,8,9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' 
	GROUP BY A.Telefonos,B.IdPersona
)
UPDATE
	C
SET
	 C.IdPersona = A.IdPersona
FROM 
	cte_telefonos A 
	INNER JOIN BaseControl.dbo.Telefonos C ON C.Telefono = A.Telefonos 
WHERE 
	A.IdPersona != C.IdPersona


-- ;WITH cte_data
-- AS
-- (
-- 	select a.Cedula from BaseControl.dbo.Persona a inner join BaseControl.dbo.Tarjetas b on a.IdPersona = b.IdCliente where b.IdBancos = 7
-- ),cte_Unique
-- AS
-- (
-- 	select a.Cedula from DB_22052019 a
-- 	except 
-- 	select a.Cedula from cte_data a
-- ), cte_final
-- AS
-- (
-- 	select b.IdPersona From cte_Unique a inner join BaseControl.dbo.Persona b on a.Cedula = b.Cedula
-- )

-- select * from cte_final


-- insert into BaseControl.dbo.Tarjetas (IdCliente,IdBancos,IdProcedencia,FechaIngreso,Estado)
-- select a.IdPersona,7,1,GETDATE(),1 from cte_final a 

with cte_data
as
(
	select 
		case a.banco
			when 'Banco Ficohsa Nicaragua, S.A' then 3
			when 'SIMAN' then 6
			when 'BANPRO' then 5
			when 'BANCO DE AMERICA CENTRAL' then 1
			when 'LA FISE' then 4
			when 'Banco Lafise Bancentro' then 4
			when 'BANCENTRO' then 4
			when 'BANCO DE LA PRODUCCION S' then 5
			when 'BANCO DE FINANZAS' then 2
			when 'BDF' then 2
			when 'BAC' then 1
			when 'FICOHSA' then 3
			else 7
		end [IdBancos],
		b.IdPersona [IdCliente]
	from DB_22052019 a inner join BaseControl.dbo.Persona b on a.Cedula = b.Cedula
),cte_unicos
as
(
	select a.IdCliente,a.IdBancos from cte_data a
	except
	select b.IdCliente ,b.IdBancos from BaseControl.dbo.Tarjetas b
)
insert into BaseControl.dbo.Tarjetas (IdCliente,IdBancos,IdProcedencia,FechaIngreso)
select a.IdCliente,a.IdBancos,1,GETDATE() from cte_unicos a