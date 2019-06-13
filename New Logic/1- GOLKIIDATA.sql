/*CREACION DE BASES DE DATOS Y TABLAS*/

CREATE DATABASE GOLKIIDATA
GO
USE GOLKIIDATA
GO

/*
    Creacion de Tablas
        1. Personas
            Persona
        2. Demografia
            Municipio
            Departamento
        3. StatusCredito
            Banco
            Tarjeta
            Historial Crediticio
        4. Telefonos
            Telefono
        5. StatusCredex
        6. INSS
*/
GO

CREATE TABLE Procedencia
(
    IdProcedencia INT PRIMARY KEY IDENTITY(1,1),
    Procedencia VARCHAR(20) NOT NULL,
    Descripcion VARCHAR(250) NOT NULL,
    Estado BIT DEFAULT 0,
    FechaIngreso DATETIME DEFAULT GETDATE()
)

GO

CREATE FUNCTION ObtenerEdad
(
    @Cedula AS VARCHAR(14)
)
RETURNS INT
AS
BEGIN
    DECLARE @YEAR AS INT, @AYEAR AS INT, @IDATE AS DATE;
    SET @YEAR = CAST(SUBSTRING(@Cedula,8,2) AS INT);SET @YEAR = CASE WHEN 0 <= @YEAR AND @YEAR <= SUBSTRING(CONVERT(VARCHAR,GETDATE(),112),3,2) THEN 2000+@YEAR ELSE 1900+@YEAR END;
    
    SET @IDATE = CAST(CONCAT(@YEAR,'-',SUBSTRING(@Cedula,6,2),'-',SUBSTRING(@Cedula,4,2)) AS DATE);
    RETURN CEILING(DATEDIFF(DAY,@IDATE,GETDATE())/365)
END

GO
/*
    CREACION DE TABLA QUE VA A CONTENER A TODAS LAS PERSONAS IGUAL CON SUS DATOS DEMOGRAFICOS Y DATOS GLOBALES
*/
CREATE TABLE Persona
(
    IdPersona int PRIMARY KEY IDENTITY(1,1),
    IdProcedencia INT FOREIGN KEY REFERENCES Procedencia(IdProcedencia),
    Nombre VARCHAR(100) NOT NULL,
    Cedula VARCHAR(14) CHECK(Cedula LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][A-z]'),
    Domicilio VARCHAR(MAX),
    Demografia AS SUBSTRING(Cedula,1,3),
    Edad AS dbo.ObtenerEdad(Cedula),
    Sexo CHAR CHECK (Sexo IN('M','F',NULL)) DEFAULT NULL,
    Salario MONEY DEFAULT 0,
    Estado BIT DEFAULT 1,
    Disponible BIT DEFAULT 1,
    FechaIngreso DATE DEFAULT GETDATE(),
    FechaModificacion DATE DEFAULT GETDATE()
)

GO

CREATE TRIGGER TRI_PERSONA 
ON Persona 
AFTER UPDATE 
AS
BEGIN
    DECLARE @F AS DATE SET @F = GETDATE();
    UPDATE A SET A.FechaModificacion = @F FROM Persona A INNER JOIN inserted B ON A.IdPersona = B.IdPersona
END

GO

CREATE TABLE Empresas
(
    IdEmpresaCliente INT PRIMARY KEY IDENTITY(1,1),
    IdPersona INT FOREIGN KEY REFERENCES Persona(IdPersona),
    Empresa VARCHAR(150) NOT NULL,
    Salario MONEY,
    Fecha DATETIME DEFAULT GETDATE(),
    Disponible BIT DEFAULT 1
)

GO

CREATE TABLE Departamento
(
    IdDepartamento INT PRIMARY KEY IDENTITY(1,1),
    Departamento VARCHAR(30) NOT NULL,
    Abreviatura VARCHAR(2) NOT NULL
)

GO

CREATE TABLE Municipio
(
    IdMunicipio INT PRIMARY KEY IDENTITY(1,1),
    IdDepartamento INT FOREIGN KEY REFERENCES Departamento(IdDepartamento),
    CodMunicipio INT NOT NULL UNIQUE,
    Municipio VARCHAR(100)
)

GO

CREATE TABLE Bancos
(
    IdBanco INT PRIMARY KEY IDENTITY(1,1),
    Banco VARCHAR(50),
    FechaIngreso DATE DEFAULT GETDATE()
)

GO

CREATE TABLE Tarjetas
(
    IdPersona INT FOREIGN KEY REFERENCES Persona(IdPersona),
    IdBanco INT FOREIGN KEY REFERENCES Bancos(IdBanco),
    IdProcedencia INT FOREIGN KEY REFERENCES Procedencia(IdProcedencia),
    Lote INT NULL,
    Descripcion VARCHAR(150),
    Disponible BIT DEFAULT 1,
    FechaIngreso DATE DEFAULT GETDATE(),
    FechaModificacion DATE DEFAULT GETDATE(),
    PRIMARY KEY (IdPersona,IdBanco)
)

GO

CREATE TRIGGER TRI_I_Tarjetas
ON Tarjetas
AFTER INSERT 
AS
BEGIN
    DECLARE @Lote AS INT, @F AS DATE 
    SET @Lote = ISNULL((SELECT MAX(A.Lote) FROM Tarjetas A),0) + 1
    SET @F = GETDATE()
    UPDATE A SET A.Lote = @Lote, A.FechaIngreso = @F,A.FechaModificacion = @F FROM Tarjetas A INNER JOIN inserted B ON A.IdBanco = B.IdBanco AND A.IdPersona = B.IdPersona
END

GO

CREATE TRIGGER TRI_U_Tarjetas
ON Tarjetas
AFTER UPDATE 
AS
BEGIN
    DECLARE @Lote AS INT, @F AS DATE 
    SET @Lote = ISNULL((SELECT MAX(A.Lote) FROM Tarjetas A),0) + 1 ; SET @F = GETDATE();
    UPDATE A SET A.Lote = @Lote,A.FechaModificacion = @F FROM Tarjetas A INNER JOIN inserted B ON A.IdBanco = B.IdBanco AND A.IdPersona = B.IdPersona
END

GO

CREATE TABLE StatusCredex 
(
    IdStatus INT PRIMARY KEY IDENTITY(1,1),
    Nombre VARCHAR(50) NOT NULL UNIQUE,
    Descripcion VARCHAR(250) NULL,
    Aprobado BIT DEFAULT 0,
    EnProceso BIT DEFAULT 0,
    Rechazo BIT DEFAULT 0,
    Fecha DATE DEFAULT GETDATE() 
)

GO

CREATE TABLE Credex
(
    IdCredex INT PRIMARY KEY,
    IdPersona INT FOREIGN KEY REFERENCES Persona(IdPersona),
    IdStatus INT FOREIGN KEY REFERENCES StatusCredex(IdStatus),
    Credito MONEY,
    Disponible BIT DEFAULT 1,
    Lote INT,
    FechaIngreso DATE DEFAULT GETDATE(),
    FechaModificacion DATE DEFAULT GETDATE()
)

GO

CREATE TRIGGER TRI_I_Credex
ON Credex
AFTER INSERT
AS
BEGIN
    DECLARE @Lote AS INT, @F AS DATE 
    SET @Lote = ISNULL((SELECT MAX(Lote) FROM Credex),0) + 1;
    SET @F = GETDATE()
    UPDATE A SET A.Lote = @Lote,A.FechaIngreso = @F FROM Credex A INNER JOIN inserted B ON A.IdCredex = B.IdCredex
END

GO 

CREATE TRIGGER TRI_U_Credex
ON Credex
AFTER UPDATE
AS
BEGIN
    DECLARE @Lote AS INT, @F AS DATE 
    SET @Lote = ISNULL((SELECT MAX(Lote) FROM Credex),0) + 1;
    SET @F = GETDATE()
    UPDATE A SET A.Lote = @Lote,A.FechaModificacion = @F FROM Credex A INNER JOIN inserted B ON A.IdCredex = B.IdCredex
END

GO

CREATE TABLE Prefijos
(
    Prefijo INT PRIMARY KEY,
    Operadora VARCHAR(20),
    Disponible BIT DEFAULT 1
)

GO

CREATE TABLE Telefonos
(
    Telefono INT PRIMARY KEY,
    IdPersonas INT FOREIGN KEY REFERENCES Persona(IdPersona),
    IdProcedencia INT FOREIGN KEY REFERENCES Procedencia(IdProcedencia),
    Operadora VARCHAR(10),
    Lote INT,
    FechaIngreso DATE DEFAULT GETDATE(),
    FechaModificacion DATE DEFAULT GETDATE()
)

GO

CREATE TRIGGER TRI_I_Telefono
ON Telefonos
AFTER INSERT
AS
BEGIN
    DECLARE @F AS DATE,@Lote AS INT;
    SET @Lote = ISNULL((SELECT MAX(Lote) FROM Telefonos),0);
    SET @F = GETDATE()
    UPDATE A SET A.Lote = @Lote, A.FechaIngreso = @F FROM Telefonos A INNER JOIN inserted B ON A.Telefono = B.Telefono
END

GO

CREATE TRIGGER TRI_U_Telefono
ON Telefonos
AFTER UPDATE
AS
BEGIN
    DECLARE @F AS DATE,@Lote AS INT;
    SET @Lote = ISNULL((SELECT MAX(Lote) FROM Telefonos),0);
    SET @F = GETDATE()
    UPDATE A SET A.Lote = @Lote, A.FechaIngreso = @F FROM Telefonos A INNER JOIN inserted B ON A.Telefono = B.Telefono
END

GO

CREATE 