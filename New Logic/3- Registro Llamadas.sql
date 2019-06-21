

/*
    Esto unicamente se va a ejecutar al inicio para rellenar las tablas ya que luego se va a estar ejecutando un job
    que va a mandar a traer aquellos registros que no se han registrado ()
*/

IF(EXISTS(SELECT OBJECT_ID('tempdb..#TempTable')))
BEGIN
    DROP TABLE #TempTable
    SELECT a.phone_number [Telefono], a.status[Tipificacion], a.call_date [UltimaLlamada],a.called_count[CalledCount] INTO #TempTable FROM openquery([VICIDIAL],'select a.phone_number,a.status,a.call_date,a.called_count from vicidial_log a where a.campaign_id = ''EFNI''') A
END 



/*
    SE INGRESAN LOS TELEFONOS POR [PRIMERA] VEZ 
*/
;WITH cte_Data (Telefono,Tipificacion,UltimaLlamada,CalledCount,Registro)
AS
(
    SELECT 
        A.Telefono, 
        A.Tipificacion, 
        A.UltimaLlamada, 
        A.CalledCount, 
        ROW_NUMBER() OVER (PARTITION BY A.Telefono ORDER BY A. UltimaLlamada DESC) 
    FROM 
        #TempTable A
    WHERE 
        A.Telefono LIKE '[2,5,7,8,9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
)   

INSERT INTO EFNI.dbo.Telefono (EFNI_Telefono,LastIdPersona,Tipificacion,FechaLlamada,CalledCount,Lote)
SELECT 
    DISTINCT
    A.Telefono, 
    B.IdPersonas,
    A.Tipificacion, 
    A.UltimaLlamada, 
    A.CalledCount,
    0
FROM 
    cte_Data A
    INNER JOIN GOLKIIDATA.dbo.Telefonos B ON A.Telefono = B.Telefono
WHERE
    A.Registro = 1

/*
    SE INGRESA LA DATA DE LA PERSONA POR [PRIMERA] VEZ
    JUNTO CON SU CALLCOUNT GLOBAL
*/
INSERT INTO EFNI.dbo.Persona (EFNI_Persona,UltimaLlamada,CCGlobal)
SELECT 
    A.LastIdPersona,
    MAX(A.FechaLlamada),
    MAX(A.CalledCount)
FROM 
    EFNI.dbo.Telefono A
WHERE
    A.LastIdPersona IS NOT NULL
GROUP BY 
    A.LastIdPersona

/*
    ACTUALIZAMOS EL CALLCOUNT MENSUAL
*/

DECLARE @MONTH AS INT, @YEAR AS INT
SET @MONTH = MONTH(GETDATE());SET @YEAR = YEAR(GETDATE())
;WITH cte_Data
AS
(
    SELECT
        C.EFNI_Persona,
        COUNT(1) [CC]
    FROM 
        #TempTable A 
        INNER JOIN EFNI.dbo.Telefono B ON A.Telefono = B.EFNI_Telefono
        INNER JOIN EFNI.dbo.Persona C ON C.EFNI_Persona = B.LastIdPersona
    WHERE 
        YEAR(A.UltimaLlamada) = @YEAR AND MONTH(A.UltimaLlamada) = @MONTH
        AND A.Telefono LIKE '[2,5,7,8,9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    GROUP BY
        C.EFNI_Persona
)

UPDATE B SET B.CCMensual = A.CC FROM cte_Data A INNER JOIN EFNI.dbo.Persona B ON B.EFNI_Persona = A.EFNI_Persona

