/*SCRIPT DE INSERCION*/

/*SE INGRESA LA DATA DE PROCEDENCIA*/
INSERT INTO GOLKIIDATA.dbo.Procedencia(Procedencia,Descripcion,Estado)
SELECT A.Procedencia,A.Procedencia,1 FROM Procedencia A

SELECT * FROM GOLKIIDATA.dbo.Procedencia

/*SE INGRESA LA DATA DE PERSONA*/

INSERT INTO GOLKIIDATA.dbo.Persona(Nombre,Cedula,Domicilio,Edad)
SELECT A.Nombre,A.Cedula,A.Domicilio,0 FROM Persona A
-- Me hace falta actualizar la edad de las personas

SELECT * FROM GOLKIIDATA.dbo.Persona

SELECT * FROM GOLKIIDATA.dbo.Empresas

/*
    En esta parte del codigo se necesita ingresar las empresas de las personas
    igual si es ingresa una nueva empresa se tiene que desactivar las empresas anteriores
*/
INSERT INTO GOLKIIDATA.dbo.Empresas(IdPersona,Empresa,Salario)
SELECT
    D.IdPersona,
    LEFT(C.Empresa,150),
    C.SALARIO
FROM 
    Persona A 
    CROSS APPLY (
        SELECT B.EMPRESA,B.SALARIO FROM REFCOMERCIAL.dbo.infoINSS B WHERE B.CEDULA COLLATE Modern_Spanish_CI_AS = A.Cedula AND B.disponible = 1
    ) C
    INNER JOIN GOLKIIDATA.dbo.Persona D ON D.Cedula = A.Cedula COLLATE Modern_Spanish_CI_AS


SELECT * FROM GOLKIIDATA.dbo.Empresas

GO

INSERT INTO GOLKIIDATA.dbo.Departamento(Departamento,Abreviatura)
SELECT Departamento,Abreviatura FROM Demografia.Departamento

SELECT * FROM GOLKIIDATA.dbo.Departamento

GO

INSERT INTO GOLKIIDATA.dbo.Municipio(IdDepartamento,CodMunicipio,Municipio)
SELECT 
    C.IdDepartamento,B.CodMunicipio,B.Municipio
FROM 
Demografia.Departamento A 
INNER JOIN GOLKIIDATA.dbo.Departamento C ON C.Departamento = A.Departamento COLLATE Modern_Spanish_CI_AS
INNER JOIN Demografia.Municipio B ON A.IdDepartamento = B.IdDepartamento 

SELECT * FROM GOLKIIDATA.dbo.Municipio

GO

INSERT INTO GOLKIIDATA.dbo.Bancos (Banco)
SELECT A.Banco FROM Bancos A WHERE A.IdBancos BETWEEN 1 AND 5
INSERT INTO GOLKIIDATA.dbo.Bancos (Banco) VALUES ('Otros')

SELECT * FROM GOLKIIDATA.dbo.Bancos

GO

INSERT INTO GOLKIIDATA.dbo.Tarjetas(IdPersona,IdBanco,Limite)
SELECT
    DISTINCT
    B.IdPersona,
    E.IdBanco,
    ISNULL(C.Limite,0)
FROM 
    Persona A 
    INNER JOIN GOLKIIDATA.dbo.Persona B ON B.Cedula COLLATE Modern_Spanish_CI_AS = A.Cedula
    INNER JOIN Tarjetas C ON C.IdCliente = A.IdPersona
    INNER JOIN Bancos D ON C.IdBancos = D.IdBancos
    INNER JOIN GOLKIIDATA.dbo.Bancos E ON E.Banco COLLATE Modern_Spanish_CI_AS = D.Banco

SELECT TOP 100 * FROM GOLKIIDATA.dbo.Tarjetas

GO

INSERT INTO GOLKIIDATA.dbo.StatusCredex (Nombre,Descripcion,Aprobado,EnProceso,Rechazo)
VALUES
    ('Linea Autorizada','Posee una linea autorizada para poder venderle',1,0,0),
    ('Cancelado','Linea Cancelada',0,0,1),
    ('Verificado','Linea que esta aprobada',1,0,0),
    ('Linea Inactiva','Linea desactivada por falta de uso',0,1,0),
    ('Linea Rechazada','Linea fue rechazada en la entrevista',0,0,1),
    ('Linea Bloqueada','Linea Bloqueada por algun motivo',0,0,1),
    ('Linea Suspendida','Linea suspendida por algun motivo',1,0,0),
    ('En Proceso','En Proceso',0,1,0),
    ('Aprobado Credex','Listo para vender',1,0,0)

INSERT INTO 
    GOLKIIDATA.dbo.Credex(IdPersona,IdStatus)
SELECT
    B.IdPersona,C.IdStatus
FROM
    Persona A 
    INNER JOIN GOLKIIDATA.dbo.Persona B ON A.Cedula = B.Cedula COLLATE Modern_Spanish_CI_AS
    INNER JOIN GOLKIIDATA.dbo.StatusCredex C ON A.StatusCredex = C.Nombre COLLATE Modern_Spanish_CI_AS
WHERE
    A.StatusCredex IS NOT NULL

SELECT * FROM GOLKIIDATA.dbo.Credex

GO

/*
    LOS PREFIJOS SE TIENEN QUE ACTUALIZAR CADA VEZ QUE ENVIEN BASE
*/
INSERT INTO GOLKIIDATA.dbo.Prefijos(Prefijo,Operadora)
SELECT
    DISTINCT
    A.prefijo,
    UPPER(A.operador) 
FROM 
    BasePrefijos A 

SELECT * FROM GOLKIIDATA.dbo.Prefijos

GO

WITH cte_Telefono
AS
(
    SELECT A.Telefono,A.IdPersona,ROW_NUMBER() OVER (PARTITION BY A.Telefono ORDER BY A.FechaIngreso DESC) [Registros] FROM Telefonos A WHERE A.Telefono LIKE '[2,5,7,8,9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
)
INSERT INTO GOLKIIDATA.dbo.Telefonos (Telefono,IdPersonas,IdProcedencia,Operadora)
SELECT DISTINCT
    A.Telefono,
    C.IdPersona,
    1,
    UPPER(D.operador)
FROM 
    cte_Telefono A
    INNER JOIN Persona B ON A.IdPersona = B.IdPersona
    INNER JOIN GOLKIIDATA.dbo.Persona C ON C.Cedula COLLATE Modern_Spanish_CI_AS = B.Cedula
    LEFT JOIN BasePrefijos D ON D.prefijo = SUBSTRING(CAST(A.Telefono AS VARCHAR(MAX)),1,4)
WHERE 
    A.Registros = 1

SELECT * FROM GOLKIIDATA.dbo.Telefonos
