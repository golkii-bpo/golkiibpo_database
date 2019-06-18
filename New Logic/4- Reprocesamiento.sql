
/*
    SE TIENE QUE CREAR UNA LOGICA PARA RESETEAR LOS CALLCOUNTS POR MES
*/

/*
    Este va a ser un metodo que se va a ejecutar para la campañia de UCE
*/

DECLARE @Q AS VARCHAR(MAX),@Fecha AS DATETIME
SELECT @Fecha = MAX(a.FechaLlamada) FROM EFNI.dbo.Telefono A
SET @Q = CONCAT('CALL EFNI.LoadTempData(''',CONVERT(VARCHAR,@Fecha,120),''');');

EXECUTE(@Q) AT [VICIDIAL]

IF(EXISTS(SELECT OBJECT_ID('tempdb..#TempData')))
BEGIN
    DROP TABLE #TempData
END
    SELECT 
        A.Telefono,
        A.CalledCount,
        A.LastCalled,
        A.Tipificacion 
    INTO 
        #TempData 
    FROM 
        OPENQUERY([Vicidial],'select a.* from EFNI.Telefonos a') A

IF(EXISTS(SELECT OBJECT_ID('tempdb..#TempDataResume')))
BEGIN
    DROP TABLE #TempDataResume
END
    SELECT
        B.Telefono,
        B.CalledCount,
        B.LastCalled,
        B.Tipificacion         
    INTO
        #TempDataResume 
    FROM (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY A.Telefono ORDER BY A.LastCalled DESC)[Registros],
            A.Telefono,
            A.CalledCount,
            A.LastCalled,
            A.Tipificacion
        FROM 
            #TempData A
    ) B 
    WHERE 
        B.Registros = 1

BEGIN TRANSACTION
BEGIN TRY
    DECLARE @Lote AS INT
    SET @Lote = ISNULL((SELECT MAX(a.Lote) FROM EFNI.dbo.Telefono A),0);
    SET @Lote = @Lote + 1;
    SELECT @Lote

    --PRIMERO ACTUALIZO LOS NUMEROS QUE YA SE ENCUENTRAN REGISTRADOS
    UPDATE 
        B
    SET
        B.CalledCount = A.CalledCount,
        B.FechaLlamada = A.LastCalled,
        B.Tipificacion = A.Tipificacion,
        B.Lote = @Lote
    FROM 
        #TempDataResume A
        INNER JOIN EFNI.dbo.Telefono B ON A.Telefono = B.EFNI_Telefono

    -- SE INGRESAN AQUELLOS NUMEROS QUE NO ESTAN REGISTRADOS
    INSERT INTO EFNI.dbo.Telefono (EFNI_Telefono,CalledCount,FechaLlamada,Tipificacion,Lote)
    SELECT
        A.Telefono,A.CalledCount,a.LastCalled,a.Tipificacion,@Lote
    FROM
    #TempDataResume A
    LEFT JOIN EFNI.dbo.Telefono B ON A.Telefono = B.EFNI_Telefono
    WHERE
        B.EFNI_Telefono IS NULL

    -- SE MOFICAN LAS PERSONAS QUE YA SE TIENE REGISTRO
    ;WITH cte_Data
    AS
    (
        SELECT B.IdPersonas [EFNI_Persona],SUM(A.CalledCount)[CC],MAX(A.FechaLlamada)[UL]
        FROM 
            EFNI.dbo.Telefono A
            INNER JOIN GOLKIIDATA.dbo.Telefonos B ON A.EFNI_Telefono = B.Telefono
            INNER JOIN EFNI.dbo.Persona C ON C.EFNI_Persona = B.IdPersonas
        WHERE 
            A.Lote = @Lote
        GROUP BY
            B.IdPersonas
    )
    UPDATE B SET B.CCGlobal += A.CC,B.UltimaLlamada = A.UL,B.Disponible = 0 FROM cte_Data A INNER JOIN EFNI.dbo.Persona B ON A.EFNI_Persona = B.EFNI_Persona

    -- SE AGREGAN LAS PERSONAS QUE NO POSEEN UN REGISTRO
    ;WITH cte_Data
    AS
    (
        SELECT B.IdPersonas [EFNI_Persona],SUM(A.CalledCount)[CC],MAX(A.FechaLlamada)[UL]
        FROM 
            EFNI.dbo.Telefono A
            INNER JOIN GOLKIIDATA.dbo.Telefonos B ON A.EFNI_Telefono = B.Telefono
            LEFT JOIN EFNI.dbo.Persona C ON C.EFNI_Persona = B.IdPersonas
        WHERE
            A.Lote = @Lote AND
            C.EFNI_Persona IS NULL
        GROUP BY
            B.IdPersonas
    )
    INSERT INTO EFNI.dbo.Persona (EFNI_Persona,CCGlobal,CCMensual,UltimaLlamada,Disponible)
    SELECT A.EFNI_Persona,A.CC,A.CC,A.UL,0 FROM cte_Data A

    --SE ACTUALIZAN LOS CALLCOUNTS MENSUALES
    ;WITH cte_Data
    AS
    (
        SELECT 
            B.EFNI_Persona,
            COUNT(1)[CCM]
        FROM 
            EFNI.dbo.Telefono A
            INNER JOIN EFNI.dbo.Persona B ON A.LastIdPersona = B.EFNI_Persona
        WHERE
            A.Lote = @Lote
        GROUP BY
            B.EFNI_Persona
    )

    UPDATE B SET B.CCMensual += A.CCM FROM cte_Data A INNER JOIN EFNI.dbo.Persona B ON A.EFNI_Persona = B.EFNI_Persona
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
END CATCH

-- Se liberan recursos
DROP TABLE #TempData
DROP TABLE #TempDataResume

EXECUTE('CALL CleanTempData();')
