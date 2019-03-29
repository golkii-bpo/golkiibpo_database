

;WITH cte_PersonasTarjetas
AS
(
    SELECT A.IdPersona,COUNT(1) [Registros] FROM dbo.Persona A INNER JOIN dbo.Tarjetas B ON A.IdPersona = B.IdCliente WHERE B.IdBancos BETWEEN 1 AND 5 GROUP BY A.IdPersona
), cte_TarjetasOtras
AS
(
    SELECT A.IdPersona FROM dbo.Persona A INNER JOIN dbo.Tarjetas B ON A.IdPersona = B.IdCliente WHERE B.IdBancos = 7 GROUP BY A.IdPersona
), cte_Final
AS
(
    SELECT a.IdPersona,a.Registros FROM cte_PersonasTarjetas a INNER JOIN cte_TarjetasOtras B ON A.IdPersona = B.IdPersona
)

DELETE A FROM Tarjetas A INNER JOIN cte_Final B ON A.IdCliente = B.IdPersona WHERE A.IdBancos = 7

