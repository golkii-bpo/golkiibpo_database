

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