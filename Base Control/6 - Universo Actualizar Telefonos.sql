

USE BaseControl

GO

ALTER TABLE dbo.TelefonosPerCampaign ADD TipoBase VARCHAR(10) DEFAULT NULL
ALTER TABLE Vicidial.campaignStatuses ADD TipoStatus VARCHAR(15)


GO

CREATE SCHEMA Vicidial

GO

/*FUNCION QUE TE PERMITE CONVERTIR DE STRING DE BIT*/
CREATE FUNCTION Vicidial.CastEnumToBit(@Type AS VARCHAR(1))
RETURNS BIT
AS
BEGIN
	RETURN CASE WHEN @Type = 'Y' THEN 1 WHEN @Type = 'N' THEN 0  ELSE 0 END
END

GO

CREATE PROCEDURE Vicidial.UpdateSystemStatus
AS
BEGIN

	SELECT * FROM TelefonosPerCampaign A 

	/*SE BORRA SI EL REGISTRO NO EXISTE*/
	IF(OBJECT_ID('tempdb..#SystemStatus') IS NOT NULL)
	BEGIN
		DROP TABLE #SystemStatus
	END

	SELECT 		
		A.status COLLATE Modern_Spanish_CI_AS [status],
		A.status_name COLLATE Modern_Spanish_CI_AS [status_name],
		Vicidial.CastEnumToBit(A.human_answered) [human_answered],
		Vicidial.CastEnumToBit(A.sale) [sale],
		Vicidial.CastEnumToBit(A.customer_contact)[customer_contact],
		Vicidial.CastEnumToBit(A.answering_machine)[answering_machine],
		Vicidial.CastEnumToBit(A.not_interested)[not_interested],
		Vicidial.CastEnumToBit(A.dnc)[dnc],
		Vicidial.CastEnumToBit(A.unworkable)[unworkable],
		Vicidial.CastEnumToBit(Completed)[Completed],
		'Sistema' [TipoBase]
	INTO 
		#SystemStatus 
	FROM 
		OPENQUERY(VICIDIAL,'select * from vicidial_statuses') A

	INSERT INTO Vicidial.campaignStatuses 
		(IdTipificacion,Tipificacion,CampaingId,HumanAnswered,IsSale,CustomerContact,AnsweringMachine,NotInterested,DoNotCall,UnWorkable,Completed,TipoBase)
	SELECT
		A.status,A.status_name,C.IdCampaign,A.human_answered,A.sale,A.customer_contact,A.answering_machine,A.not_interested,A.dnc,A.unworkable,A.Completed,A.TipoBase
	FROM 
		#SystemStatus A 
		LEFT JOIN Vicidial.campaignStatuses B ON A.status = B.IdTipificacion COLLATE SQL_Latin1_General_CP1_CI_AS,
		Vicidial.Campaigns C
	WHERE
		B.IdTipificacion IS NULL

	DROP TABLE #SystemStatus
END

GO

/*FUNCION QUE TE PERMITE ACTUALIZAR E INSERTAR LAS TIPIFICACIONES DE LAS CAMA�AS*/
CREATE PROCEDURE Vicidial.UpdateStatus
AS
BEGIN
	/*SE BORRA SI EL REGISTRO NO EXISTE*/
	IF(OBJECT_ID('tempdb..#TempStatus') IS NOT NULL)
	BEGIN
		DROP TABLE #TempStatus
	END

	/*SE LLENA LOS DATOS CON LA INFORMACION QUE HAY EN BASE DE DATOS*/
	SELECT 
		A.status COLLATE Modern_Spanish_CI_AS [status],
		A.status_name COLLATE Modern_Spanish_CI_AS [status_name],
		A.campaign_id COLLATE Modern_Spanish_CI_AS [campaign_id],
		Vicidial.CastEnumToBit(A.human_answered) [human_answered],
		Vicidial.CastEnumToBit(A.sale) [sale],
		Vicidial.CastEnumToBit(A.customer_contact)[customer_contact],
		Vicidial.CastEnumToBit(A.answering_machine)[answering_machine],
		Vicidial.CastEnumToBit(A.not_interested)[not_interested],
		Vicidial.CastEnumToBit(A.dnc)[dnc],
		Vicidial.CastEnumToBit(A.unworkable)[unworkable],
		Vicidial.CastEnumToBit(Completed)[Completed],
		'Campaign' [TipoStatus]
	INTO 
		#TempStatus 
	FROM 
		OPENQUERY(VICIDIAL,'select * from vicidial_campaign_statuses') A

	/*SE ACTUALIZAN LOS REGISTROS QUE HAY EN LA BASE DE DATOS*/
	UPDATE
		B
	SET
		B.Tipificacion = a.status_name,
		B.HumanAnswered = A.human_answered,
		B.IsSale = A.sale,
		B.CustomerContact = A.customer_contact,
		B.AnsweringMachine = A.answering_machine,
		B.NotInterested = A.not_interested,
		B.DoNotCall = A.dnc,
		B.UnWorkable = A.unworkable,
		B.Completed = A.Completed,
		B.TipoStatus = A.TipoStatus
	FROM 
		#TempStatus A 
		INNER JOIN Vicidial.campaignStatuses B ON A.status = B.IdTipificacion AND A.campaign_id = B.CampaingId


	/*SE INSERTAN LOS NUEVOS REGISTROS*/
	INSERT INTO Vicidial.campaignStatuses 
		(IdTipificacion,Tipificacion,CampaingId,HumanAnswered,IsSale,CustomerContact,AnsweringMachine,NotInterested,DoNotCall,UnWorkable,Completed,TipoStatus)
	SELECT 
		A.status,A.status_name,A.campaign_id,A.human_answered,A.sale,A.customer_contact,A.answering_machine,A.not_interested,A.dnc,A.unworkable,A.Completed,'Campaign'
	FROM 
		#TempStatus A 
		LEFT JOIN Vicidial.campaignStatuses B ON A.status = B.IdTipificacion AND A.campaign_id = B.CampaingId
	WHERE 
		B.IdTipificacion IS NULL

	/*SE ELIMINA LA TABLA TEMPORAL*/
	DROP TABLE #TempStatus
END

GO

CREATE PROCEDURE Vicidial.UpdatePhones
AS
BEGIN
	IF(OBJECT_ID('tempdb..#TempData') IS NOT NULL)
	BEGIN
		DROP TABLE #TempData
	END
	
	/*INGRESA TODOS LOS REGISTROS DEL VICIDIAL*/
	SELECT A.* INTO #TempData FROM OPENQUERY([VICIDIAL],'SELECT * FROM GolkiiPhones') A WHERE A.Telefono LIKE '[2,5,6,7,8,9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]';

	;WITH cte_Telefonos(Telefono,IdTipificacion,IdCampaign,CalledCount,LastCallDate,UserName,TipoBase)
	AS
	(
		SELECT 
			CAST(A.Telefono AS INT),
			A.IdTipificacion,
			LEFT(LTRIM(RTRIM(A.IdCampaign)),8) COLLATE Modern_Spanish_CI_AS, 
			CAST(A.CalledCount AS INT), 
			CAST(A.CallDate AS DATETIME),
			A.FullName,
			CASE WHEN A.ListId = '998' THEN 'Manual' ELSE 'Vicidial' END --HAY QUE CAMBIAR ESTO PORQUE HAY OTRO CAMPO QUE TE DICE SI FUE MANUAL O NO LA DATA
			FROM 
		#TempData A
	)
	UPDATE
		C
	SET
		C.IdTipificacion = A.IdTipificacion,
		C.CalledCount +=  IIF(C.CalledCount IS NULL,0,A.CalledCount),
		C.LastCalled = CAST(A.LastCallDate AS DATETIME),
		C.[User] = A.UserName,
		c.Disponible = 0,
		C.TipoBase = A.TipoBase
	FROM 
		cte_Telefonos A
		INNER JOIN dbo.Telefonos B ON A.Telefono = B.Telefono
		INNER JOIN dbo.TelefonosPerCampaign C ON C.IdTelefono = B.IdTelefono AND C.IdCampaign = A.IdCampaign
	DROP TABLE #TempData
END

GO

/*OBTIENE TODA LA INFORMACION DE LOS NUMEROS ALMACENADA EN EL DIALER*/
CREATE PROCEDURE Vicidial.Update_Numeros
AS
BEGIN
	BEGIN TRY
		/*OBTIENE LA ULTIMA LLAMADA*/
		DECLARE @D AS VARCHAR(25),@Fecha AS VARCHAR(25) 
		SET @D = (SELECT TOP 1 A.LastCalled FROM dbo.TelefonosPerCampaign A ORDER BY A.LastCalled DESC);
		SET @D = ISNULL(@D,'2018-01-01 00:00:00');
		SET @Fecha = CONVERT(VARCHAR(25),CAST(@D AS DATETIME),120)
		/*SE MANDA A CARGAR LOS TELEFONOS EN LA TABLA TEMPORAL*/
		EXEC ('CALL GetUpdatePhones ('''+@Fecha+''')') AT VICIDIAL;

		/*SE ACTUALIZAN LOS TELEFONOS*/
		EXEC Vicidial.UpdatePhones;
		/*SE DROPEA LA TABLA TEMPORAL*/
		EXEC ('CALL DropPhones();') AT VICIDIAL;

		/*
			FALTAN 2 PROCEDIMIENTOS UNO SE VA A ENCARGA DE TRAER TODOS LOS REGISTROS CON ESTADO DE NEW LEAD CON
			EL REGISTRO DE LA BASE DE DATOS APAGADA
			EL OTRO PROCEDIMIENTO SE VA A ENCARGAR DE ELIMINAR LOS REGISTROS QUE ESTAN CON ESTADO DE NEW LEAD
		*/
		
	END TRY
	BEGIN CATCH
		SELECT ERROR_MESSAGE()
	END CATCH
END

GO

/*RESET PARA PROBAR EL FUNCIONAMIENTO DE LAS TIPIFICACIONES DE LOS TELEFONOS*/
-- UPDATE C
-- SET 
-- 	C.IdTipificacion = NULL,
-- 	C.CalledCount = NULL,
-- 	C.LastCalled = NULL,
-- 	C.[User] = NULL,
-- 	C.IsReprocessed = NULL,
-- 	C.DateReprocessed = NULL,
-- 	C.Disponible = 1
-- FROM 
-- 	dbo.TelefonosPerCampaign C
