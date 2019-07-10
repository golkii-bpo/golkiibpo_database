ALTER DATABASE GOLKIIDATA_2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
USE master
DROP DATABASE GOLKIIDATA_2
GO
CREATE DATABASE GOLKIIDATA_2
GO
USE GOLKIIDATA_2
GO
CREATE TABLE GOLKIIDATA_2.dbo.Procedencia
(
    IdProcedencia INT PRIMARY KEY IDENTITY(1,1),
    Procedencia VARCHAR(20) NOT NULL,
    Descripcion VARCHAR(250) NOT NULL,
    Estado BIT DEFAULT 0,
    FechaIngreso DATETIME DEFAULT GETDATE()
)
CREATE TABLE GOLKIIDATA_2.dbo.Departamento
(
    IdDepartamento INT PRIMARY KEY IDENTITY(1,1),
    Departamento VARCHAR(30) NOT NULL,
    Abreviatura VARCHAR(2) NOT NULL
)
CREATE TABLE GOLKIIDATA_2.dbo.Municipio
(
    CodMunicipio INT NOT NULL PRIMARY KEY,
    IdDepartamento INT FOREIGN KEY REFERENCES Departamento(IdDepartamento),
    Municipio VARCHAR(100)
)
CREATE TABLE GOLKIIDATA_2.dbo.Persona
(
    IdPersona INT PRIMARY KEY IDENTITY(1,1),
    IdProcedencia INT FOREIGN KEY REFERENCES Procedencia(IdProcedencia) NOT NULL,
    Nombre VARCHAR(100) NOT NULL,
    Cedula VARCHAR(14) CHECK(Cedula LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][A-z]' OR Cedula IS NULL),
    Domicilio VARCHAR(MAX),
    Demografia AS SUBSTRING(Cedula,1,3), -- ESTE INDICA EL MUNICIPIO DE ORIGEN DE LA PERSONA, NO DONDE VIVE
    Edad INT NULL,
    Sexo CHAR CHECK (Sexo IN('M','F',NULL)) DEFAULT NULL,
    Salario MONEY DEFAULT 0,
    Estado BIT DEFAULT 1,
    Disponible BIT DEFAULT 1,
    FechaIngreso DATE DEFAULT GETDATE(),
    FechaModificacion DATE DEFAULT GETDATE()
)
CREATE TABLE GOLKIIDATA_2.dbo.InssAsociado
(
    IdInssEmpresa INT NOT NULL,
    IdPersona INT FOREIGN KEY REFERENCES Persona(IdPersona),
    Empresa VARCHAR(150) NOT NULL,
    Salario MONEY,
    FechaRegistro DATETIME DEFAULT GETDATE(),
    Disponible BIT DEFAULT 1,
    PRIMARY KEY (IdInssEmpresa,IdPersona)
)
CREATE TABLE GOLKIIDATA_2.dbo.Bancos
(
    IdBanco INT PRIMARY KEY IDENTITY(1,1),
    Banco VARCHAR(50),
    FechaIngreso DATE DEFAULT GETDATE()
)
CREATE TABLE GOLKIIDATA_2.dbo.Tarjetas
(
    IdPersona INT FOREIGN KEY REFERENCES Persona(IdPersona) NOT NULL,
    IdBanco INT FOREIGN KEY REFERENCES Bancos(IdBanco) NOT NULL,
    IdProcedencia INT FOREIGN KEY REFERENCES Procedencia(IdProcedencia) NOT NULL,
    Lote INT NULL,
    Descripcion VARCHAR(150),
    Limite MONEY,
    Disponible BIT DEFAULT 1,
    FechaIngreso DATE DEFAULT GETDATE(),
    FechaModificacion DATE DEFAULT GETDATE(),
    PRIMARY KEY (IdPersona,IdBanco)
)
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
CREATE TABLE Credex
(
    IdPersona INT PRIMARY KEY FOREIGN KEY REFERENCES Persona (IdPersona) NOT NULL,
    IdStatus INT FOREIGN KEY REFERENCES StatusCredex (IdStatus) NOT NULL,
    Credito MONEY,
    Disponible BIT DEFAULT 1,
    Lote INT,
    FechaIngreso DATE DEFAULT GETDATE(),
    FechaModificacion DATE DEFAULT GETDATE()
)
CREATE TABLE Prefijos
(
    Prefijo INT PRIMARY KEY,
    Operadora VARCHAR(20),
    Disponible BIT DEFAULT 1
)
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


