
WITH CTE_CleaningNumbers
AS (
    SELECT 
        [NOMBRE DEL CLIENTE ] COLLATE DATABASE_DEFAULT AS NOMBRE,
        REPLACE(TEL1,'-','') AS TEL1,
        REPLACE(TEL2,'-','') AS TEL2,
        REPLACE(TEL3,'-','') AS TEL3,
        REPLACE(TEL4,'-','') AS TEL4,
        DATO
    FROM BasesRecibidas.dbo.NT_DB_22062019
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
    SELECT MAX(RN) as [INDEX],
        A.NAME,
        A.TEL1,
        A.TEL2,
        A.TEL3,
        A.TEL4,
        A.DATO,
        MAX(A.Cedula) AS [CEDULA]
    FROM CTE_countPersona A
    GROUP BY 
        A.NAME,
        A.TEL1,
        A.TEL2,
        A.TEL3,
        A.TEL4,
        A.DATO
)

select * 
INTO #TEMP_PERSONA
from CTE_UNIQUE_PERSONA

UPDATE #TEMP_PERSONA
SET [INDEX] = ''
WHERE [INDEX] > 1

-- SELECT * FROM #TEMP_PERSONA
-- WHERE [INDEX] = 0

-- SELECT * FROM GOLKIIDATA.dbo.Procedencia

-- INSERT INTO GOLKIIDATA.dbo.Persona (IdProcedencia,Nombre,Cedula,Estado,Disponible,FechaIngreso,FechaModificacion)
-- SELECT 6,[NAME],CEDULA,1,1,GETDATE(),GETDATE() FROM #TEMP_PERSONA
-- WHERE [INDEX] = 0

-- INSERT INTO GOLKIIDATA.dbo.Persona (IdProcedencia,Nombre,Cedula,Estado,Disponible,FechaIngreso,FechaModificacion)
-- SELECT 
-- 6,[NAME],CEDULA,1,1,GETDATE(),GETDATE()
-- FROM #TEMP_PERSONA
-- WHERE CEDULA IS NULL

-- SELECT 
-- 6,[NAME],CEDULA,1,1,GETDATE(),GETDATE()
-- FROM #TEMP_PERSONA
-- WHERE CEDULA IS NOT NULL


-- UPDATE GOLKIIDATA.dbo.Persona
-- SET IdProcedencia = 6
-- FROM GOLKIIDATA.dbo.Persona A 
-- INNER JOIN #TEMP_PERSONA B ON A.Cedula COLLATE DATABASE_DEFAULT =B.CEDULA COLLATE DATABASE_DEFAULT
-- WHERE  B.CEDULA IS NOT NULL


SELECT *
INTO #TEMP_TELEFONO
FROM 
    #TEMP_PERSONA
UNPIVOT
(
    TEL FOR [NOMBRE] IN (TEL1,TEL2,TEL3,TEL4) 
) UN



-- UPDATE GOLKIIDATA.DBO.Telefonos
-- SET 
-- ESTADO = 0 
-- FROM GOLKIIDATA.DBO.Telefonos A
-- INNER JOIN GOLKIIDATA.DBO.Persona B ON A.IdPersonas = B.IdPersona
-- WHERE B.IdProcedencia = 6


-- SELECT * FROM #TEMP_TELEFONO A
-- INNER JOIN GOLKIIDATA.DBO.PERSONA B ON A.CEDULA COLLATE DATABASE_DEFAULT = B.Cedula COLLATE DATABASE_DEFAULT
-- INNER JOIN 
-- WHERE A.CEDULA IS NOT NULL

UPDATE
#TEMP_TELEFONO
SET TEL = LTRIM(RTRIM(TEL))
FROM #TEMP_TELEFONO WHERE TEL NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' 


-- SELECT * FROM #TEMP_TELEFONO WHERE TEL NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'  


DELETE FROM #TEMP_TELEFONO WHERE TEL NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'

--###########################--###########################--###########################--#####################

SELECT c.IdPersona,c.Nombre,b.Telefono, A.*
FROM #TEMP_TELEFONO A
INNER JOIN GOLKIIDATA.DBO.Telefonos B ON A.TEL=B.Telefono
INNER JOIN GOLKIIDATA.DBO.Persona C ON C.IdPersona = B.IdPersonas
WHERE C.Nombre LIKE '%'+REPLACE(A.NAME,' ','%')+'%'


-- DELETE
SELECT *
FROM GOLKIIDATA.DBO.Persona
WHERE 
-- IdProcedencia = 6 AND 
-- Cedula IS NULL OR 
Cedula IN (
'2841704710001S',
'6032505800005U',
'4061703920000S',
'4022511880000P',
'1212305840009Q'
)

UPDATE
GOLKIIDATA.DBO.Telefonos
SET IdProcedencia = 6 
FROM #TEMP_TELEFONO A
INNER JOIN GOLKIIDATA.DBO.Telefonos B ON A.TEL=B.Telefono


SELECT * 
FROM GOLKIIDATA.DBO.Telefonos 
WHERE IdProcedencia = 6 



UPDATE
    GOLKIIDATA.DBO.Telefonos
    SET IdProcedencia = 6
FROM  #TEMP_TELEFONO A
INNER JOIN GOLKIIDATA.DBO.Telefonos B ON A.TEL = B.Telefono



select * from Persona where IdProcedencia = 6 and Cedula is null



UPDATE 
GOLKIIDATA.DBO.Telefonos
    SET IdPersonas = 1
FROM GOLKIIDATA.DBO.Telefonos A
INNER JOIN #TEMP_
WHERE A.IdProcedencia = 6







