USE BaseControl

GO

CREATE SCHEMA Politicas

GO

CREATE TABLE Politicas.CallRestriccion
(
	IdRestriccion VARCHAR(2) PRIMARY KEY NOT NULL,
	InitCallCount TINYINT NOT NULL,
	EndCallCount TINYINT NULL
)

GO

CREATE TABLE Politicas.GroupTipificaciones
(
	IdGroupTipificaciones VARCHAR(6) PRIMARY KEY,
	Descripcion VARCHAR(50) NULL,
	Relevancia TINYINT UNIQUE NULL,
	Estado BIT DEFAULT 1
)

GO

CREATE TABLE Politicas.RelTipificionesGroup
(
	IdRelTipificionesGroup INT PRIMARY KEY IDENTITY(1,1),
	IdGroupTipificaciones VARCHAR(6) FOREIGN KEY REFERENCES Politicas.GroupTipificaciones(IdGroupTipificaciones),
	IdCampaignStatuses INT FOREIGN KEY REFERENCES Vicidial.campaignStatuses(IdCampaignStatuses),
	Estado BIT DEFAULT 0
)
GO 

CREATE TABLE Politicas.Reciclaje
(
	IdRestricciones INT PRIMARY KEY IDENTITY (1,1),
	IdCallRestriction VARCHAR(2) FOREIGN KEY REFERENCES Politicas.CallRestriccion(IdRestriccion),
	IdGroupTipificaciones VARCHAR(6) FOREIGN KEY REFERENCES Politicas.GroupTipificaciones(IdGroupTipificaciones),
	DaysWithoutCall TINYINT NOT NULL,
	Relevancia TINYINT NOT NULL
)

GO
/*SE INGRESAN LOS RANGOS*/
INSERT INTO Politicas.CallRestriccion (IdRestriccion,InitCallCount,EndCallCount)
VALUES 
	('A',0,5),
	('B',6,12),
	('C',13,NULL)

/*SE INGRESA EL GRUPO DE LAS TIPIFICACIONES*/
INSERT INTO Politicas.GroupTipificaciones (IdGroupTipificaciones,Descripcion,Relevancia)
VALUES
	('A',NULL,1),
	('B',NULL,2),
	('C',NULL,3),
	('D',NULL,4),
	('E',NULL,5)

SELECT * FROM Politicas.GroupTipificaciones

/*SE INGRESAN LAS TIPIFICACIONES PARA SER PROCESADAS A UN GRUPO ESPECIFICO*/
INSERT INTO	Politicas.RelTipificionesGroup (IdGroupTipificaciones,IdCampaignStatuses,Estado)
VALUES 
	('A',6,1),
	('A',58,1),
	('A',64,1),
	('A',76,1),
	('A',124,1),
	('A',3,1),
	('A',4,1),
	('A',6,1),
	('A',8,1),
	('A',9,1),
	('B',4,1),
	('B',6,1),
	('C',5,1),
	('C',6,1),
	('C',7,1),
	('D',1,1),
	('D',2,1),
	('D',44,1),
	('E',36,1),
	('E',5,1)


/*SE INGRESA EN LA TABLA DE POLITICAS*/
INSERT INTO Politicas.Reciclaje (IdCallRestriction,IdGroupTipificaciones,DaysWithoutCall,Relevancia)
VALUES 
	('A','A',60,1),
	('A','B',60,1),
	('B','B',60,1),
	('C','C',90,1)

GO

CREATE PROCEDURE Politicas.ReprocesamientoTelefonos
AS
BEGIN
	IF(OBJECT_ID('tempdb..#TempData') IS NOT NULL)
	BEGIN
		DROP TABLE #TempData
	END

	CREATE TABLE #TempData
	(
		Id INT IDENTITY(1,1),
		InitCallCount TINYINT,
		EndCallCount TINYINT,
		IdGroupTipificaciones VARCHAR(6),
		DaysWithoutCall TINYINT,
		Procesado BIT DEFAULT 0
	)

	INSERT INTO #TempData (InitCallCount,EndCallCount,IdGroupTipificaciones,DaysWithoutCall,Procesado)
	SELECT B.InitCallCount,B.EndCallCount,A.IdGroupTipificaciones,A.DaysWithoutCall,1
	FROM 
		Politicas.Reciclaje A 
		INNER JOIN Politicas.CallRestriccion B ON A.IdCallRestriction = B.IdRestriccion
	ORDER BY
		A.Relevancia ASC

	/*VARIABLES QUE VAMOS A UTILIZAR*/
	DECLARE
		@Id AS INT,
		@IdGroupTipificaciones AS VARCHAR(8),
		@DaysWithOutCall AS TINYINT,
		@FMAX AS DATETIME,
		@Lote AS INT

	SET @FMAX = GETDATE();
	SELECT @Lote = MAX(A.Lote) FROM dbo.TelefonosPerCampaign A
	SET @Lote = ISNULL(@Lote,0) + 1;

	/*REALIZAMOS UN CURSOR PARA QUE SEA MUCHO MAS LIGTH LA EJECUCION*/
	WHILE ((SELECT TOP 1 COUNT (1) FROM #TempData A WHERE A.Procesado = 1) > 0)
	BEGIN
		/*ASIGNAMOS LAS VARIABLES*/
		SELECT TOP 1
			@Id = A.Id,
			@IdGroupTipificaciones = A.IdGroupTipificaciones,
			@DaysWithOutCall = A.DaysWithoutCall	 
		FROM #TempData A WHERE a.Procesado = 1 ORDER BY A.Id ASC

		/*CODIGO VA AQUI*/
		UPDATE 
			C
		SET 
			C.Disponible = 1,
			C.IsReprocessed = 1,
			C.DateReprocessed = @FMAX,
			C.Lote = @Lote
		FROM 
            Politicas.RelTipificionesGroup A 
            INNER JOIN Vicidial.campaignStatuses B ON A.IdCampaignStatuses = B.IdCampaignStatuses
            INNER JOIN TelefonosPerCampaign C ON C.IdTipificacion = B.IdTipificacion 
        WHERE 
            A.IdGroupTipificaciones = @IdGroupTipificaciones
            AND @DaysWithOutCall <= DATEDIFF(DAY,C.LastCalled,@FMAX)
            AND C.IdCampaign = B.CampaingId
            AND C.Disponible = 0

		/*VAMOS RESTANDO LOS REGISTROS PARA IR PROGRESANDO CON EL CURSOR*/
		UPDATE A SET A.Procesado = 0 FROM #TempData A WHERE A.Id = @Id
	END
END

GO

ALTER PROCEDURE Politicas.ReprocesamientoLeadsOffBase
AS
BEGIN

	;WITH cte_TelefonosD
	AS
	(
		SELECT CAST(a.phone_number AS VARCHAR(MAX)) [Telefono], CAST(a.alt_phone AS VARCHAR(MAX)) [Alt_phone],a.campaign_id COLLATE Modern_Spanish_CI_AS [IdCampaign] 
		FROM OPENQUERY(VICIDIAL,'select a.phone_number,a.alt_phone,b.campaign_id from vicidial_list a inner join vicidial_lists b on a.list_id = b.list_id where a.`status` = ''NEW'' and b.active = ''N''') a
	),cte_Telefonos (Telefono,IdCampaign)
	AS
	(
		SELECT CAST(UPVT.Tel AS INT),UPVT.IdCampaign FROM cte_TelefonosD A UNPIVOT (Tel FOR Registros IN (Telefono,Alt_phone)) UPVT WHERE UPVT.Tel LIKE '[2,5,6,7,8,9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
	),cte_DataTelefono
	AS
	(
		SELECT 
			B.IdTelefonoPorCamp
		FROM 
			cte_Telefonos A 
			OUTER APPLY
			(
				SELECT TOP 1 B.IdTelefono,C.IdTelefonoPorCamp,C.IdCampaign FROM dbo.Telefonos B INNER JOIN TelefonosPerCampaign C ON B.IdTelefono = C.IdTelefono
				WHERE B.Telefono = A.Telefono AND C.IdCampaign = A.IdCampaign
			) B
	)
	UPDATE B SET B.Disponible = 1 FROM cte_DataTelefono A INNER JOIN TelefonosPerCampaign B ON A.IdTelefonoPorCamp = B.IdTelefonoPorCamp WHERE B.Disponible = 0
END


GO

CREATE PROCEDURE Politicas.ReprocesamientoLeads
AS
BEGIN
	BEGIN TRANSACTION
		BEGIN TRY

			EXECUTE Politicas.ReprocesamientoTelefonos
			EXECUTE Politicas.ReprocesamientoLeadsOffBase

			EXECUTE ('CALL EliminarNewLeadsOffBase();') AT VICIDIAL

			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION
		END CATCH
END

GO
/*
	VALIDACION DE DATOS
*/

SELECT * FROM 
(
    SELECT 
        A.IdTipificacion,
        B.TipoStatus,
        COUNT(1) [Registros] 
    FROM 
        TelefonosPerCampaign A
        INNER JOIN Vicidial.campaignStatuses B ON A.IdTipificacion = B.IdTipificacion AND B.CampaingId = 'EFNI'
    WHERE 
        A.Disponible = 0 
    GROUP BY A.IdTipificacion,B.TipoStatus
) A
ORDER BY
    A.Registros DESC
