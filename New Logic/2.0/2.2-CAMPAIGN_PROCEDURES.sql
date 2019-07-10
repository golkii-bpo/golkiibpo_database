USE GOLKIIDATA_2
GO
-- =============================================
-- Se tiene que realizar un reemplazo de todas las referencias de la campañia de EFNI
-- Para que pueda funcionar en otras campañias
-- =============================================
-- =============================================
-- Author:      Jackzeel Garcia
-- Create date: 06/18/2019
-- Type: Procedimiento
-- Description: Realiza un reset de los call counts mensuales de las personas que tenemos en la base de datos
-- Schedule: Procedimiento sera ejecutado a inicio de cada mes
-- =============================================
CREATE PROCEDURE EFNI.ResetCallCounts
AS
BEGIN
    UPDATE A
    SET A.CCMensual = 0
    FROM GOLKIIDATA_2.EFNI.Persona A;
END;

GO
-- =============================================
-- Author:      Jackzeel Garcia
-- Create date: 06/18/2019
-- Type: Procedimiento
-- Description: Este procedimiento se encarga de recolectar información de las llamadas para la 
--              campañia 
-- Schedule: Este Procedimiento se va a ejecutar en un job que se va a ejecutar cada hora todos los dias 
--			 de lunes a viernes de 7am a 8pm 
-- =============================================
CREATE PROCEDURE EFNI.HistorialData
AS
BEGIN
    DECLARE @Q AS VARCHAR(MAX),
            @Fecha AS DATETIME;
    --SE INGRESA EL ULTIMO REGISTRO INGRESADO DEL MYSQL
    SELECT @Fecha = MAX(A.FechaLlamada)
    FROM GOLKIIDATA_2.EFNI.Telefono A;
    SET @Q = CONCAT('CALL EFNI.LoadTempData(''', CONVERT(VARCHAR, @Fecha, 120), ''');');

    -- SE EJECUTA LoadTempData DE LA BASE DE DATOS EFNI EN EL MYSQL. 
    -- ESTO LO QUE HACE ES QUE LLENA UNA TABLA CON TODOS AQUELLOS REGISTROS QUE SE HAN MARCADO DESPUES DEL ULTIMO REGISTRO QUE HAY
    -- EN LA BASE DE DATOS
    EXECUTE (@Q) AT [VICIDIAL];

    -- SE VALIDA QUE LA TABLA NO EXISTA
    IF (OBJECT_ID('tempdb..#TempData') IS NOT NULL)
    BEGIN
        DROP TABLE #TempData;
    END;

    -- SE INSERTA LA INFORMACION QUE SE LLENO DEL MYSQL
    SELECT A.Telefono,
           A.CalledCount,
           A.LastCalled,
           A.Tipificacion
    INTO #TempData
    FROM OPENQUERY
         ([VICIDIAL], 'select a.* from EFNI.Telefonos a') A;

    IF (OBJECT_ID('tempdb..#TempDataResume') IS NOT NULL)
    BEGIN
        DROP TABLE #TempDataResume;
    END;

    SELECT B.Telefono,
           B.CalledCount,
           B.LastCalled,
           B.Tipificacion
    INTO #TempDataResume
    FROM
    (
        SELECT ROW_NUMBER() OVER (PARTITION BY A.Telefono ORDER BY A.LastCalled DESC) [Registros],
               A.Telefono,
               A.CalledCount,
               A.LastCalled,
               A.Tipificacion
        FROM #TempData A
    ) B
    WHERE B.Registros = 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- SE BUSCA Y SE SUMA 1 AL ULTIMO LOTE QUE SE AGREGO ESTO ES PARA LLEVAR UN MEJOR CONTROL DE LO QUE SE HA SUBIDO
        DECLARE @Lote AS INT;
        SET @Lote = ISNULL(
                        (
                            SELECT MAX(A.Lote) FROM GOLKIIDATA_2.EFNI.Telefono A
                        ),
                        0
                    ) + 1;

        --PRIMERO ACTUALIZO LOS NUMEROS QUE YA SE ENCUENTRAN REGISTRADOS
        UPDATE B
        SET B.CalledCount = A.CalledCount,
            B.FechaLlamada = A.LastCalled,
            B.Tipificacion = A.Tipificacion,
            B.Lote = @Lote
        FROM #TempDataResume A
            INNER JOIN GOLKIIDATA_2.EFNI.Telefono B
                ON A.Telefono = B.EFNI_Telefono;

        -- SE INGRESAN AQUELLOS NUMEROS QUE NO ESTAN REGISTRADOS
        INSERT INTO GOLKIIDATA_2.EFNI.Telefono
        (
            EFNI_Telefono,
            CalledCount,
            FechaLlamada,
            Tipificacion,
            Lote
        )
        SELECT A.Telefono,
               A.CalledCount,
               A.LastCalled,
               A.Tipificacion,
               @Lote
        FROM #TempDataResume A
            LEFT JOIN GOLKIIDATA_2.EFNI.Telefono B
                ON A.Telefono = B.EFNI_Telefono
        WHERE B.EFNI_Telefono IS NULL

        -- SE MOFICAN LAS PERSONAS QUE YA SE TIENE REGISTRO
        ;
        WITH cte_Data
        AS (SELECT B.IdPersonas [EFNI_Persona],
                   SUM(A.CalledCount) [CC],
                   MAX(A.FechaLlamada) [UL]
            FROM GOLKIIDATA_2.EFNI.Telefono A
                INNER JOIN GOLKIIDATA.dbo.Telefonos  B  ON A.EFNI_Telefono = B.Telefono
                INNER JOIN GOLKIIDATA_2.EFNI.Persona C  ON C.EFNI_Persona  = B.IdPersonas
            WHERE A.Lote = @Lote
            GROUP BY B.IdPersonas)
        UPDATE B
        SET B.CCGlobal += A.CC,
            B.UltimaLlamada = A.UL,
            B.Disponible = 0
        FROM cte_Data A
            INNER JOIN GOLKIIDATA_2.EFNI.Persona B
                ON A.EFNI_Persona = B.EFNI_Persona

        -- SE AGREGAN LAS PERSONAS QUE NO POSEEN UN REGISTRO
        ;
        WITH cte_Data
        AS (SELECT B.IdPersonas [EFNI_Persona],
                   SUM(A.CalledCount) [CC],
                   MAX(A.FechaLlamada) [UL]
            FROM GOLKIIDATA_2.EFNI.Telefono A
                INNER JOIN GOLKIIDATA.dbo.Telefonos     B ON A.EFNI_Telefono = B.Telefono
                LEFT JOIN  GOLKIIDATA_2.EFNI.Persona    C ON C.EFNI_Persona = B.IdPersonas
            WHERE A.Lote = @Lote
                  AND C.EFNI_Persona IS NULL
            GROUP BY B.IdPersonas)
        INSERT INTO GOLKIIDATA_2.EFNI.Persona
        (
            EFNI_Persona,
            CCGlobal,
            CCMensual,
            UltimaLlamada,
            Disponible
        )
        SELECT A.EFNI_Persona,
               A.CC,
               A.CC,
               A.UL,
               0
        FROM cte_Data A

        --SE ACTUALIZAN LOS CALLCOUNTS MENSUALES
        ;
        WITH cte_Data
        AS (SELECT B.EFNI_Persona,
                   COUNT(1) [CCM]
            FROM GOLKIIDATA_2.EFNI.Telefono A
                INNER JOIN GOLKIIDATA_2.EFNI.Persona B
                    ON A.LastIdPersona = B.EFNI_Persona
            WHERE A.Lote = @Lote
            GROUP BY B.EFNI_Persona)
        UPDATE B
        SET B.CCMensual += A.CCM
        FROM cte_Data A
            INNER JOIN GOLKIIDATA_2.EFNI.Persona B
                ON A.EFNI_Persona = B.EFNI_Persona;
        PRINT 'SE REALIZO EL COMMIT';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        PRINT 'SE REALIZO EL ROLLBACK';
        ROLLBACK TRANSACTION;
    END CATCH;

    -- Se liberan recursos de la base de datos
    DROP TABLE #TempData;
    DROP TABLE #TempDataResume;

    -- Se libera recursos del mysql
    EXECUTE ('CALL EFNI.CleanTempData();') AT [VICIDIAL];
END
GO
-- =============================================
-- Author:      Jackzeel Garcia
-- Create date: 06/19/2019
-- Tipo: Procedure 
-- Description: Procedimiento llena todos los estatus de la campania, 
--				tambien desactiva aquellos statuses que ya no estan registrados. 
-- =============================================
CREATE PROCEDURE EFNI.Llenar_CampaingStatuses
AS
BEGIN
    IF (OBJECT_ID('tempdb..#TempStatuses') IS NOT NULL)
    BEGIN
        DROP TABLE #TempStatuses;
    END;

    --SE INGRESA LAS TIPIFICACIONES DE LA CAMPAÑIA ESTO PARA LLEVAR UN MEJOR REGISTROS DE AQUELLAS TIPIFICACIONES QUE ESTAN Y NO ESTAN VIGENTES
    SELECT *
    INTO #TempStatuses
    FROM OPENQUERY
         ([VICIDIAL], 'select * from vicidial_campaign_statuses where campaign_id = ''EFNI'';');

    INSERT INTO GOLKIIDATA_2.EFNI.CampaingStatuses
    (
        IdStatus,
        status_name,
        human_answerd,
        sale,
        dnc,
        customer_contact,
        not_interested,
        unworkable,
        schedule_callback,
        completed,
        Fuente
    )
    SELECT A.[status],
           A.[status_name],
           IIF(A.human_answered = 'Y', 1, 0),
           IIF(A.sale = 'Y', 1, 0),
           IIF(A.dnc = 'Y', 1, 0),
           IIF(A.customer_contact = 'Y', 1, 0),
           IIF(A.not_interested = 'Y', 1, 0),
           IIF(A.unworkable = 'Y', 1, 0),
           IIF(A.scheduled_callback = 'Y', 1, 0),
           IIF(A.completed = 'Y', 1, 0),
           'CAMPAIGN'
    FROM #TempStatuses A
        LEFT JOIN GOLKIIDATA_2.EFNI.CampaingStatuses B
            ON A.[status] = B.IdStatus
               AND B.Fuente = 'CAMPAIGN'
    WHERE B.IdStatus IS NULL;

    -- SE QUITAN AQUELLOS REGISTROS QUE YA NO ESTAN EN LA TABLA 

    UPDATE A
    SET A.Estado = 0
    FROM GOLKIIDATA_2.EFNI.CampaingStatuses A
        LEFT JOIN #TempStatuses B
            ON A.IdStatus = B.[status]
               AND A.Fuente = 'CAMPAIGN'
    WHERE B.[status] IS NULL;

    UPDATE A
    SET A.Estado = 1
    FROM GOLKIIDATA_2.EFNI.CampaingStatuses A
        INNER JOIN #TempStatuses B
            ON A.IdStatus = B.[status]
    WHERE A.Fuente = 'CAMPAIGN'
          AND A.Estado = 0;

    -- SE LIBERA LA TABLA TEMPORAL
    DROP TABLE #TempStatuses;

    -- =============================================
    -- SE PROCEDE CON EXTRAER LA DATA DEL SYSTEMA
    -- =============================================

    SELECT *
    INTO #TempSystemStatuses
    FROM OPENQUERY
         ([VICIDIAL], 'select * from asterisk.vicidial_statuses a where a.selectable = ''Y''') A;

    --SE INGRESA LA DATA DEL SISTEMA
    INSERT INTO GOLKIIDATA_2.EFNI.CampaingStatuses
    (
        IdStatus,
        status_name,
        human_answerd,
        sale,
        dnc,
        customer_contact,
        not_interested,
        unworkable,
        schedule_callback,
        completed
    )
    SELECT A.[status],
           A.[status_name],
           IIF(A.human_answered = 'Y', 1, 0),
           IIF(A.sale = 'Y', 1, 0),
           IIF(A.dnc = 'Y', 1, 0),
           IIF(A.customer_contact = 'Y', 1, 0),
           IIF(A.not_interested = 'Y', 1, 0),
           IIF(A.unworkable = 'Y', 1, 0),
           IIF(A.scheduled_callback = 'Y', 1, 0),
           IIF(A.completed = 'Y', 1, 0)
    FROM #TempSystemStatuses A
        LEFT JOIN GOLKIIDATA_2.EFNI.CampaingStatuses B
            ON A.[status] = B.IdStatus
               AND B.Fuente = 'SYSTEM'
    WHERE B.IdStatus IS NULL;

    -- SE ACTUALIZA DE AQUELLOS REGISTROS QUE YA NO SE ENCUENTRAN DISPONIBLES
    UPDATE A
    SET A.Estado = 0
    FROM GOLKIIDATA_2.EFNI.CampaingStatuses A
        INNER JOIN #TempSystemStatuses B
            ON A.IdStatus = B.[status]
               AND A.Fuente = 'SYSTEM'
    WHERE B.[status] IS NULL;

    --SE ACTUALIZAN AQUELLOS REGISTROS QUE ESTABAN DESACTIVADOS PARA QUE VUELVAN A ENTRAR AL PROCESO
    UPDATE A
    SET A.Estado = 1
    FROM GOLKIIDATA_2.EFNI.CampaingStatuses A
        INNER JOIN #TempSystemStatuses B
            ON A.IdStatus = B.[status]
               AND A.Fuente = 'SYSTEM'
    WHERE A.Estado = 0;

    -- SE LIBERAN RECURSOS
    DROP TABLE #TempSystemStatuses;
END;
GO
/*INSERCION DE TODOS LOS STATUS EXCEPTOS LOS QUE SON DNS EN LA TABLA DE REPROCESAMIENTO*/
-- =============================================
-- Author:      Jackzeel Garcia
-- Create date: 06/19/2019
-- Tipo: Procedure 
-- Description: Insercion de todos los status que estan en el mysql de la tabla de reprocesamiento
--				Esto es un procedimiento inicial o bien progresivo ya que a como se puede ejecutar una vez o
--				se puede ejecutar varias veces dependiendo de lo que se quiera realizar
-- =============================================
CREATE PROCEDURE EFNI.LlenarTipificaciones
AS
BEGIN
	-- SE INGRESAN TODAS LAS TIPIFICACIONES NORMALES
	INSERT INTO GOLKIIDATA_2.EFNI.PoliticaReprocesamiento
	(
		IdTipificacion,
		Tipificacion,
		DaysWithOutCall,
		CCGlobal,
		CCMensual,
		Fuente,
		Estado
	)

	SELECT A.IdStatus,A.status_name,90,NULL,NULL,A.Fuente,1FROM GOLKIIDATA_2.EFNI.CampaingStatuses A LEFT JOIN GOLKIIDATA_2.EFNI.PoliticaReprocesamiento B ON A.IdStatus = B.IdTipificacion WHERE B.IdTipificacion IS NULL AND A.dnc != 1 AND A.schedule_callback != 1;

	-- SE INGRESAN TODAS LAS TIPIFICIACIONES CON DNC
	INSERT INTO GOLKIIDATA_2.EFNI.PoliticaReprocesamiento
	(
		IdTipificacion,
		Tipificacion,
		DaysWithOutCall,
		CCGlobal,
		CCMensual,
		Estado,
		Fuente
	)

	SELECT A.IdStatus,A.status_name,180,NULL,NULL,1,A.Fuente FROM GOLKIIDATA_2.EFNI.CampaingStatuses A LEFT JOIN GOLKIIDATA_2.EFNI.PoliticaReprocesamiento B ON A.IdStatus = B.IdTipificacion WHERE B.IdTipificacion IS NULL AND A.dnc = 1

	-- SE INGRESAN TODOS AQUELLOS QUE SON CALLBACKS
	INSERT INTO GOLKIIDATA_2.EFNI.PoliticaReprocesamiento
	(
		IdTipificacion,
		Tipificacion,
		DaysWithOutCall,
		CCGlobal,
		CCMensual,
		Estado,
		Fuente
	)
	SELECT A.IdStatus,A.status_name,90,NULL,NULL,1,A.Fuente FROM GOLKIIDATA_2.EFNI.CampaingStatuses A LEFT JOIN GOLKIIDATA_2.EFNI.PoliticaReprocesamiento B ON A.IdStatus = B.IdTipificacion WHERE B.IdTipificacion IS NULL AND A.schedule_callback = 1
END
GO
-- =============================================
-- Author:      Jackzeel Garcia
-- Create date: 06/20/2019
-- Tipo: Procedure 
-- Description: Procedimiento que reprocesa los numeros de telefonos y valida el call coaunt y la ultima fecha
-- =============================================
CREATE PROCEDURE EFNI.ReprocesoTelefonos
AS
BEGIN
	DECLARE @F AS DATE SET @F = GETDATE();

	IF(OBJECT_ID('tempdb..#TempReprocesamiento') IS NOT NULL)
	BEGIN
		DROP TABLE #TempReprocesamiento
	END

	SELECT 
		A.IdTipificacion [IdTipificacion],
		A.DaysWithOutCall [DaysWithOutCall],
		A.CCGlobal [CCGlobal],
		A.CCMensual [CCMensual],
		A.Fuente [Fuente],
		0 [Procesado] 
	INTO 
		#TempReprocesamiento
	FROM 
		GOLKIIDATA_2.EFNI.PoliticaReprocesamiento A

	DECLARE 
		@IdTipificacion AS VARCHAR(6),
		@DayWithOutCall AS INT,
		@CCGlobal AS INT,
		@CCMensual AS INT,
		@Fuente AS VARCHAR(20)

	WHILE((SELECT TOP 1 COUNT(1) FROM #TempReprocesamiento A WHERE A.Procesado = 0) != 0)
	BEGIN
		-- SE INICIALIZAN TODAS LAS VARIABLES
		SELECT TOP 1 
			@IdTipificacion = A.IdTipificacion,
			@DayWithOutCall = A.DaysWithOutCall,
			@CCGlobal = A.CCGlobal,
			@CCMensual = A.CCMensual,
			@Fuente = A.Fuente
		FROM 
			#TempReprocesamiento A
		WHERE
			A.Procesado = 0

		UPDATE 
			A 
		SET 
			A.Disponible = 1,
			A.Reprocesada = 1,
			A.FechaReprocesamiento = @F
		FROM 
			GOLKIIDATA_2.EFNI.Telefono A 
		WHERE 
			A.Tipificacion = @IdTipificacion 
			AND DATEDIFF(DAY,A.FechaLlamada,@DayWithOutCall) <= @DayWithOutCall
		-- SE TIENE QUE AGREGAR LA LOGICA PARA IMPLEMENTAR EL TEMA DE LOS CALL COUNTS SI ES QUE SE ESTA INTERESADO EN
		-- TOMAR EN CUENTA ESTAS VARIABLES

		-- SE SETEA QUE YA SE PROCESO. TIPO LA FUNCION DE CURSOR
		UPDATE A SET A.Procesado = 1 FROM #TempReprocesamiento A WHERE A.IdTipificacion = @IdTipificacion AND A.Fuente = @Fuente
	END
END;
GO
-- =============================================
-- Author:      Jackzeel Garcia
-- Create date: 06/20/2019
-- Tipo: Procedure 
-- Description: Procedimiento que realiza el reprocesamiento por las personas, este procedimiento valida si la persona ya es valida para volver a ser marcada
-- =============================================
CREATE PROCEDURE EFNI.ReprocesoPersona
AS
BEGIN	
	DECLARE @Lote AS INT 
	SET @Lote = ISNULL((SELECT MAX(A.Lote) FROM GOLKIIDATA_2.EFNI.Persona A),0)
	SET @Lote += 1;
	UPDATE A
	SET 
		A.Disponible = 1,
		A.CCReproceso += 1,
		A.FechaReprocesamiento = GETDATE(),
		A.Lote = @Lote
	FROM 
		GOLKIIDATA_2.EFNI.Persona A
		OUTER APPLY (
			SELECT B.EFNI_Telefono FROM GOLKIIDATA_2.EFNI.Telefono B WHERE B.LastIdPersona = A.EFNI_Persona AND A.Disponible = 0 AND B.EFNI_Telefono IS NOT NULL
		) C
	WHERE 
		C.EFNI_Telefono IS NULL
		AND A.Disponible = 0
END
GO
-- =============================================
-- Author:      Jackzeel Garcia
-- Create date: 06/20/2019
-- Tipo: Procedure 
-- Description: Procedimiento que sera ejecutado a travez de un job el cual sirve para ejecutar los procedimientos de reproceso
-- Schedule: Se va a ejecutar cada hora de lunes a viernes de 7am a 8pm y los sabados de 7am a las 5pm
-- =============================================
CREATE PROCEDURE EFNI.ReprocesoJob
AS
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY
		EXECUTE GOLKIIDATA_2.EFNI.ReprocesoTelefonos
		EXECUTE GOLKIIDATA_2.EFNI.ReprocesoPersona
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		INSERT INTO LogReproceso ([Procedure],[Message],[Severity],[State],[Fecha]) VALUES (ERROR_PROCEDURE(),ERROR_MESSAGE(),ERROR_SEVERITY(),ERROR_STATE(),GETDATE());
	END CATCH
END