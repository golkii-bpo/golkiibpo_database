WITH
CTE_DATA
AS (
    SELECT 
        DISTINCT    IDP,
                    NOMBRE,
                    TELEFONO
    FROM BasesRecibidas.DBO.BD_EVELING_27062019
    UNPIVOT (TELEFONO FOR TELNO IN (TEL1,TEL2)) PVT
    WHERE TELEFONO LIKE '[5|7|8][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
),
CTE_COUNTER
AS (
    SELECT 
        IDP,
        LTRIM(RTRIM(A.NOMBRE)) AS NOMBRE,
        CAST(A.TELEFONO AS INT) AS TELEFONO,
        ROW_NUMBER() OVER(PARTITION BY IDP ORDER BY TELEFONO) N
    FROM CTE_DATA A
),
CTE_PIVOTER
AS (
    SELECT 
        IDP,
        [1] TEL1,
        [2] TEL2
    FROM CTE_COUNTER
    PIVOT( MAX(TELEFONO) FOR N IN([1],[2]) )P
)
,CTE_JOIN_BC 
AS(
    SELECT DISTINCT
        A.IDP,
        B.IdPersona,
        A.NOMBRE AS N1,
        REPLACE(C.Nombre,'NULL','') AS N2,
        A.TELEFONO AS T1
    FROM CTE_COUNTER A
    INNER JOIN BASECONTROL.DBO.TELEFONOS B ON A.TELEFONO = B.Telefono
    INNER JOIN BASECONTROL.DBO.Persona C ON B.IdPersona = C.IdPersona
),
CTE_IDP
AS(
    SELECT IDP,IdPersona FROM CTE_JOIN_BC
    WHERE '%'+REPLACE(N1,' ','%')+'%' LIKE '%'+REPLACE(N2,' ','%')+'%'
),
CTE_PERSONAS
AS(
    SELECT  A.IdPersona,
            A.Nombre,
            A.CEDULA,
            A.Domicilio,
            A.Departamento,
            A.Municipios,
            A.SalarioInss,
            a.StatusCredex
    FROM BaseControl.DBO.Persona A
    inner join CTE_IDP B ON A.IdPersona = B.IDPERSONA
),
CTE_TARJETAS
AS (
    SELECT  DISTINCT
            A.IdCliente,
            B.Banco,
            ROW_NUMBER() OVER(PARTITION BY IdCliente ORDER BY a.IdCliente asc) N 
    FROM BaseControl.DBO.Tarjetas A
    INNER JOIN BaseControl.dbo.Bancos B ON A.IdBancos = B.IdBancos
    INNER JOIN CTE_PERSONAS C ON A.IdCliente = C.IdPersona
),
CTE_TARJETA_UNICA
AS (
    SELECT 
        IDCLIENTE IDPERSONA,
        [1] BANCO
    FROM CTE_TARJETAS A
    PIVOT(MIN(BANCO) FOR N IN ([1]) ) P
)
SELECT 
    DISTINCT
    A.IdPersona,
    A.idp,--id propio de la base
    D.Nombre,
    B.Domicilio,
    B.Departamento,
    B.Municipios,
    E.TEL1,
    E.TEL2,
    C.BANCO
INTO BasesRecibidas.DBO.DB_CARLOS_RAMIREZ_FILTRADA_28062019_2
FROM CTE_IDP A
INNER JOIN BaseControl.DBO.Persona B ON A.IdPersona =B.IdPersona
INNER JOIN CTE_TARJETA_UNICA C ON B.IdPersona = C.IDPERSONA
INNER JOIN CTE_DATA D ON A.IDP = D.IDP
INNER JOIN CTE_PIVOTER E ON E.IDP = A.IDP

