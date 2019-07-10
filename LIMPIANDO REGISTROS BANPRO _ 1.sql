
WITH
CTE_CLEANING_DATA
AS (
    SELECT
        A.[No],
        RTRIM(LTRIM(REPLACE(A.CEDULA,'-','')))  COLLATE DATABASE_DEFAULT AS CEDULA,
        RTRIM(LTRIM(NOMBRE))  COLLATE DATABASE_DEFAULT AS NOMBRE,
        REPLACE(STR(A.TEL#1,8),'-','') AS TELEFONO,
        A.PRODUCTO  COLLATE DATABASE_DEFAULT AS TTARJETA
    FROM BasesRecibidas..db_banpro_corregida_03072019 A
),
CTE_PERSONAS
AS(
    SELECT 
        A.[No],
        A.CEDULA,
        A.NOMBRE,
        A.TELEFONO,
        A.TTARJETA,
        B.IdPersona
    FROM CTE_CLEANING_DATA A
    INNER JOIN Persona B    ON A.NOMBRE= B.Nombre                      
     WHERE 
    --  IdProcedencia != 4
    --  AND 
    A.TELEFONO LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
    AND
    A.CEDULA != B.Cedula
    AND
    A.CEDULA NOT IN (
        '4492011810004N',
        '1212111420001U'
    )
)
SELECT 
    A.TELEFONO,
    A.CEDULA,
    A.NOMBRE,
    A.IdPersona,
    B.IdPersonas AS PERSONAACTUAL,
    C.Nombre AS NOMBREACTUAL,
    C.Cedula AS CEDULAACTUAL,
    B.IdProcedencia TELPROCEDE,
    C.IdProcedencia PERPROCEDE,
    ROW_NUMBER()OVER(PARTITION BY A.TELEFONO ORDER BY A.TELEFONO) N
-- INTO #MATCH_DATA
FROM CTE_PERSONAS A
INNER JOIN Telefonos B ON A.TELEFONO = B.Telefono
INNER JOIN PERSONA C ON B.IdPersonas = C.IdPersona
WHERE A.IdPersona != B.IdPersonas
and B.IdProcedencia != 4
-- AND 
--     C.NOMBRE LIKE '%'+REPLACE(A.NOMBRE,' ','%')+'%'
GROUP BY A.TELEFONO,
    A.CEDULA,
    C.Cedula,
    A.NOMBRE,
    A.IdPersona,
    B.IdPersonas,
    C.Nombre,
    B.IdProcedencia,
    C.IdProcedencia



-- SELECT * FROM #MATCH_DATA

-- UPDATE A
-- SET IdProcedencia = 4
-- FROM Persona A
-- INNER JOIN #MATCH_DATA B ON A.IdPersona = B.PERSONAACTUAL

-- UPDATE A 
-- SET IDPROCEDENCIA = 4
-- FROM Telefonos A
-- INNER JOIN #MATCH_DATA B  ON A.Telefono = B.TELEFONO




 