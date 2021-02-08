DELIMITER $$

DROP PROCEDURE IF EXISTS buildSourceList$$

CREATE PROCEDURE buildSourceList ()
BEGIN

	DELETE FROM A_Quellenliste;

	INSERT INTO A_Quellenliste
	select CONCAT('P', Id_phon_Typ), group_concat(DISTINCT Erhebung ORDER BY Erhebung) 
	FROM Tokens JOIN Informanten USING (Id_Informant) JOIN VTBL_Token_phon_Typ USING (Id_Token) JOIN phon_Typen p USING (Id_phon_Typ) WHERE p.Quelle = 'VA'
	GROUP BY Id_phon_Typ

	UNION

	select CONCAT('L', Id_morph_Typ), group_concat(DISTINCT Erhebung ORDER BY Erhebung) 
	FROM (
		SELECT Id_Informant, Id_morph_Typ FROM Tokens JOIN VTBL_Token_morph_Typ USING (Id_Token) JOIN morph_Typen m USING (Id_morph_Typ) WHERE m.Quelle = 'VA'
			UNION 
		SELECT Id_Informant, Id_morph_Typ FROM V_Tokengruppen JOIN VTBL_Tokengruppe_morph_Typ USING (Id_Tokengruppe) JOIN morph_Typen m USING (Id_morph_Typ) WHERE m.Quelle = 'VA') t
		JOIN Informanten USING (Id_Informant)
	GROUP BY Id_morph_Typ

	UNION

	select CONCAT('B', Id_Basistyp), group_concat(DISTINCT Erhebung ORDER BY Erhebung) 
	FROM (
		SELECT Id_Informant, Id_morph_Typ FROM Tokens JOIN VTBL_Token_morph_Typ USING (Id_Token) 
			UNION 
		SELECT Id_Informant, Id_morph_Typ FROM V_Tokengruppen JOIN VTBL_Tokengruppe_morph_Typ USING (Id_Tokengruppe)) t JOIN VTBL_morph_Basistyp USING (Id_morph_Typ) JOIN Informanten USING (Id_Informant)
	GROUP BY Id_Basistyp

	UNION

	select CONCAT('C', Id_Konzept), group_concat(DISTINCT Erhebung ORDER BY Erhebung) 
	FROM (
		SELECT Id_Informant, Id_Konzept FROM Tokens JOIN VTBL_Token_Konzept USING (Id_Token) 
			UNION 
		SELECT Id_Informant, Id_Konzept FROM V_Tokengruppen JOIN VTBL_Tokengruppe_Konzept USING (Id_Tokengruppe)) t JOIN Informanten USING (Id_Informant)
	GROUP BY Id_Konzept;

END$$

DELIMITER ;