WITH
CTE_DATA
AS(
    SELECT  A.IDPERSONA,
            A.NOMBRE,
            A.TEL1,
            A.TEL2,
            B.Domicilio,
            B.Salario,
            B.Cedula,
            B.Demografia 
    FROM BASEYOTA A
    INNER JOIN Persona B ON A.IDPERSONA = B.IdPersona
),
CTE_DEMOGRAFIAS
AS (
    SELECT  A.IDPERSONA,
            CAST(A.Demografia AS INT) AS DEMO
    FROM CTE_DATA A
    WHERE Demografia LIKE '[0-9][0-9][0-9]'
),
CTE_MD
AS(
    SELECT 
        A.IDPERSONA,
        Municipio,
        Departamento
    FROM CTE_DEMOGRAFIAS A
    INNER JOIN Municipio B ON A.DEMO = B.CodMunicipio
    INNER JOIN Departamento C ON B.IdDepartamento = C.IdDepartamento
),
CTE_PERSONAS
AS(
    SELECT A.*,
            B.Departamento,
            B.Municipio
    FROM CTE_DATA A
    LEFT JOIN CTE_MD B ON A.IDPERSONA = B.IDPERSONA
),
cte_DataTarjeta (IdPersona,Registros,Banco)
AS
(
	SELECT 
        A.IdPersona,
        ROW_NUMBER() OVER (PARTITION BY A.IdPersona ORDER BY A.IdBanco ASC) [Registros],
        B.Banco 
    FROM 
        Tarjetas A 
        INNER JOIN Bancos B ON B.IdBanco = A.IdBanco 
        INNER JOIN CTE_PERSONAS C ON A.IDPERSONA = C.IDPERSONA
    WHERE 
        A.IdBanco BETWEEN 1 AND 5
),
cte_Tarjeta(IdPersona,Banco)
AS
(
	SELECT pvt.IdPersona,[1] [Banco] FROM cte_DataTarjeta x PIVOT ( max(x.Banco) FOR x.Registros IN ([1]) ) pvt
)
SELECT A.*,
        B.Banco,
        D.Nombre
FROM CTE_PERSONAS A
LEFT JOIN cte_Tarjeta B ON A.IDPERSONA = B.IDPERSONA 
LEFT JOIN Credex C ON A.IDPERSONA = C.IdPersona
LEFT JOIN StatusCredex D ON C.IdStatus = D.IdStatus
WHERE D.Aprobado = 1
OR B.Banco IS NOT NULL 
OR A.Salario > 15000






