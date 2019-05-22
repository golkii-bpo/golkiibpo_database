

WITH cte_Dirty
AS
(
	SELECT
		A.IdTelefono,
		LTRIM(RTRIM(STR(A.Telefono,8,0))) [Telefono]
	FROM 
		dbo.Telefonos A
),cte_Telefonos
AS
(
	SELECT A.*,UPPER(B.operador) [Operador] FROM
	(
		SELECT A.IdTelefono,A.Telefono,SUBSTRING(A.Telefono,1,4)[Prefijo] FROM cte_Dirty A 
	) A INNER JOIN BaseControl.dbo.BasePrefijos B ON B.prefijo = A.Prefijo
)
UPDATE
	A
SET 
	A.Operadora = B.Operador
FROM 
	BaseControl.dbo.Telefonos A
	INNER JOIN cte_Telefonos B ON B.IdTelefono = A.IdTelefono