WITH CTE_CleaningNumbers
AS (
    SELECT 
        Nombre COLLATE DATABASE_DEFAULT AS NOMBRE,
        REPLACE(TEL1,'-','') AS TEL1,
        REPLACE(TEL2,'-','') AS TEL2,
        REPLACE(TEL3,'-','') AS TEL3,
        REPLACE(TEL4,'-','') AS TEL4,
        DATO
    FROM ExcelImports..NT_DB_22060219
),
CTE_join_BaseControl
AS (
    SELECT 
        A.NOMBRE AS [NAME],
        A.TEL1,
        A.TEL2,
        A.TEL3,
        A.TEL4,
        A.DATO,
        B.Nombre AS [jNAME],
        B.Cedula
    FROM CTE_CleaningNumbers A
    LEFT JOIN BaseControl..Persona B ON A.Nombre = B.NOMBRE 
),
CTE_countPersona
AS (
    select 
        ROW_NUMBER() OVER( PARTITION BY A.NAME ORDER BY CEDULA ) as [RN],
        A.*
    from CTE_join_BaseControl A
),
CTE_UNIQUE_PERSONA
AS(
    SELECT MAX(RN),
        A.NAME,
        A.TEL1,
        A.TEL2,
        A.TEL3,
        A.TEL4,
        A.DATO
    FROM CTE_countPersona A
    GROUP BY 
        A.NAME,
        A.TEL1,
        A.TEL2,
        A.TEL3,
        A.TEL4,
        A.DATO
)

