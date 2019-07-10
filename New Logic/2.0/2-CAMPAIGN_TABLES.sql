/*Esta Logica se va a crear por cada una de las campañias Que se vayan a crear*/

USE GOLKIIDATA_2
GO
CREATE SCHEMA EFNI
CREATE TABLE GOLKIIDATA_2.EFNI.Telefono 
(
    EFNI_Telefono INT PRIMARY KEY,
    LastIdPersona INT NULL,
    Tipificacion VARCHAR(20),
    FechaLlamada DATETIME,
    CalledCount INT,
    Reprocesada BIT DEFAULT 0,
    FechaReprocesamiento DATE DEFAULT GETDATE(),
    Lote INT,
	Disponible BIT DEFAULT 0
)
CREATE TABLE GOLKIIDATA_2.EFNI.Persona 
(
    EFNI_Persona INT PRIMARY KEY,
    UltimaLlamada DATETIME,
    CCMensual INT DEFAULT 0,
    CCGlobal INT DEFAULT 0,
    CCReproceso INT DEFAULT 0,
    Disponible BIT DEFAULT 0,
    Lote INT DEFAULT 0,
    FechaReprocesamiento DATE
)
CREATE TABLE GOLKIIDATA_2.EFNI.LogReproceso
(
	IdLog INT PRIMARY KEY IDENTITY(1,1),
	[Procedure] VARCHAR(MAX),
	[Message] VARCHAR(MAX),
	[Severity] INT,
	[State] INT,
	Fecha DATETIME DEFAULT GETDATE(),
)
-- =============================================
-- Author:      Jackzeel Garcia
-- Create date: 06/19/2019
-- Tipo: Tabla
-- Description: Esta tabla lo que va a llevar son de todas las tipificaciones
-- =============================================
CREATE TABLE GOLKIIDATA_2.EFNI.PoliticaReprocesamiento
(
    IdTipificacion VARCHAR(6) PRIMARY KEY,
    Tipificacion VARCHAR(30) NOT NULL,
    DaysWithOutCall TINYINT,
    CCGlobal INT NULL,
    CCMensual INT NULL,
    Fuente VARCHAR(20),
	Prioridad INT,
    Estado BIT
        DEFAULT 1
)
-- =============================================
-- Author:      Jackzeel Garcia
-- Create date: 06/19/2019
-- Tipo: Tabla
-- Description: Registro Historico de las tipificaciones de la campañia
-- =============================================

CREATE TABLE GOLKIIDATA_2.EFNI.CampaingStatuses
(
    IdStatus VARCHAR(6),
    status_name VARCHAR(30),
    human_answerd BIT
        DEFAULT 0,
    sale BIT
        DEFAULT 0,
    dnc BIT
        DEFAULT 0,
    customer_contact BIT
        DEFAULT 0,
    not_interested BIT
        DEFAULT 0,
    unworkable BIT
        DEFAULT 0,
    schedule_callback BIT
        DEFAULT 0,
    completed BIT
        DEFAULT 0,
    Estado BIT
        DEFAULT 1,
    Fuente VARCHAR(20)
        DEFAULT 'SYSTEM'
)


GO


