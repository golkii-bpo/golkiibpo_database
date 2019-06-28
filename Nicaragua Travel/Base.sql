
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


SELECT * FROM BD_REF.Telefono
SELECT * FROM #TEMP_TELEFONO
DELETE FROM #TEMP_TELEFONO WHERE TEL = '22225603'
--FC
DELETE FROM #TEMP_TELEFONO WHERE TEL = '22226565'
--FC
DELETE FROM #TEMP_TELEFONO WHERE TEL =  '22256014'

select 
a.*,
ROW_NUMBER() over (partition by tel order by tel) as n
into #repeated
from #TEMP_TELEFONO a
delete from #repeated where n = 1

select * from #repeated

select * from #TEMP_TELEFONO a
left join #repeated b on a.TEL = b.TEL
where b.TEL is  null
order by a.tel

-- EVITO INGRESAR NUMEROS REPETIDOS PARA NO HACER CONFLICTO CON LA PRIMARY KEY
INSERT INTO BD_REF.Telefono
(TELEFONO,IdPersona,CALLED,DATECALL,LOTE)
SELECT 
    A.TEL,B.ID,1,'2019-06-24',1
FROM #TEMP_TELEFONO A
INNER JOIN BD_REF.PERSONA B ON A.NAME = B.NOMBRE
left join #repeated c on a.TEL = c.TEL
where c.TEL is  null
--###########################--###########################--###########################--#####################
