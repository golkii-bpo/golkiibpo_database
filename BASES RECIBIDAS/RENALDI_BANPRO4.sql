
----------------------------------------------------------------------------------
-- PARA AGILIZAR SOLO EJECUTAR LA PRIMERA VEZ ESTA PARTE                        --
                                                                                --
IF OBJECT_ID('tempdb..#PHONES') IS NOT NULL                                     --
    DROP TABLE #PHONES                                                          --
                                                                                --
DECLARE @QUERY NVARCHAR(MAX)                                                    --
SELECT @QUERY = GOLKIIDATA.DBO.QUERY_PHONES_ALREADY_CALLED ();                  --
CREATE TABLE #PHONES (PHONE INT)                                                --
SET @QUERY = 'INSERT INTO #PHONES '+@QUERY                                      --
EXEC (@QUERY)                                                                   --
                                                                                --
-- HASTA AQUI LA PRIMERA EJECUCION                                              --
----------------------------------------------------------------------------------
;
WITH
CTE_RECIBIDA
AS(
    select 
        ID,
        [Nombre Cliente] COLLATE DATABASE_DEFAULT AS CLIENTE,
        CONCAT('BANPRO ',TC) COLLATE DATABASE_DEFAULT AS TARJETA,
        Cedula COLLATE DATABASE_DEFAULT AS  CEDULA,
        Celular AS TEL1,
        Telefono AS TEL2,
        Correo COLLATE DATABASE_DEFAULT AS CORREO
    from BASE_BANPRO4_RENALDI_21092019
),
CTE_TELEFONOS
AS(
    SELECT 
    U.ID,
    U.CLIENTE,
    U.TARJETA,
    U.CEDULA,
    U.CORREO,
    REPLACE(U.TEL,'-','') AS TEL
    FROM CTE_RECIBIDA
    UNPIVOT(TEL FOR TELEFONOS IN(TEL1,TEL2))U
),
CTE_CLEANER
AS(
   SELECT * FROM CTE_TELEFONOS A
   WHERE  A.TEL LIKE '[5|6|7|8][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
),
CTE_NOT_CALLED
AS(
    SELECT 
    A.ID,
    A.CEDULA,
    A.CLIENTE,
    A.CORREO,
    A.TARJETA,
    CAST(A.TEL AS INT) AS TEL
    FROM CTE_CLEANER A
    LEFT JOIN #PHONES B ON B.PHONE = A.TEL
    WHERE B.PHONE IS NULL
),
CTE_COUNTER
AS(
    SELECT A.*,
        ROW_NUMBER() OVER(PARTITION BY A.ID ORDER BY A.ID)N
    FROM CTE_NOT_CALLED A
),
CTE_DATA
AS(
    SELECT P.*,SUBSTRING(P.CEDULA,1,3) DEMOGRAFIA 
    FROM CTE_COUNTER A
    PIVOT( MAX(A.TEL) FOR N IN ([1],[2]))P
),
CTE_FULL_DATA
AS(
    SELECT A.*,B.Municipio,C.Departamento FROM CTE_DATA A
    LEFT JOIN GOLKIIDATA.DBO.Municipio B ON A.DEMOGRAFIA = CAST(B.CodMunicipio AS CHAR(3))
    LEFT JOIN GOLKIIDATA.DBO.Departamento C ON B.IdDepartamento = C.IdDepartamento
)
-- SELECT COUNT(*),Departamento FROM CTE_FULL_DATA
-- WHERE Departamento not IN ('MATAGALPA','JINOTEGA','ESTELI','RIVAS','CARAZO','MASAYA','GRANADA','BOACO','CHONTALES')
-- GROUP BY Departamento
SELECT * FROM CTE_FULL_DATA
WHERE Departamento IN ('LEON')