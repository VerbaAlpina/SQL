DROP VIEW IF EXISTS V_Tokengruppen;

CREATE VIEW V_Tokengruppen AS

(SELECT 	Id_Tokengruppe, 
		Id_Informant, 
		Id_Stimulus, 
		IF (p.Id_phon_Typ IS NOT NULL AND p.Quelle = Erhebung, '', 
			GROUP_CONCAT(CONCAT(Token, IF(Trennzeichen IS NULL, '', Trennzeichen)) ORDER BY Ebene_3 ASC SEPARATOR '')) AS Tokengruppe, 
		IF (p.Id_phon_Typ IS NOT NULL AND p.Quelle = Erhebung, '', 
			GROUP_CONCAT(CONCAT(IF(t.IPA REGEXP '^$', 'XXX', t.IPA), IF(Trennzeichen_IPA IS NULL, '', IF(Trennzeichen_IPA REGEXP '^$', 'XXX', Trennzeichen_IPA))) ORDER BY Ebene_3 ASC SEPARATOR '')) AS IPA,
		IF (p.Id_phon_Typ IS NOT NULL AND p.Quelle = Erhebung, '', 
			GROUP_CONCAT(CONCAT(IF(t.Original REGEXP '^$', 'XXX', t.Original), IF(Trennzeichen_Original IS NULL, '', IF(Trennzeichen_Original REGEXP '^$', 'XXX', Trennzeichen_Original))) ORDER BY Ebene_3 ASC SEPARATOR '')) AS Original,
		Tokengruppen.Numerus,
		Tokengruppen.Genus,
		Id_Aeusserung, 
		Erfasst_Von, 
		Erfasst_Am, 
		Version,
		Tokengruppen.Bemerkung
FROM Tokens t 
	JOIN Tokengruppen USING (Id_Tokengruppe) 
	JOIN Stimuli USING (Id_Stimulus)
	LEFT JOIN VTBL_Token_phon_Typ v2 USING (Id_Token) LEFT JOIN phon_Typen p USING (Id_phon_Typ)
WHERE 
	NOT EXISTS (SELECT * FROM VTBL_Token_Konzept v WHERE v.Id_Token = t.Id_Token AND (Id_Konzept = 779 OR (Id_Konzept = 699 AND Ebene_3 = 1))) -- ARTIKEL AM ANFANG UND SONDERZEICHEN AUSSORTIEREN
GROUP BY Id_Tokengruppe)