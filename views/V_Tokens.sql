DELIMITER $$

DROP VIEW IF EXISTS V_Tokens$$

CREATE VIEW V_Tokens AS

SELECT 
	Id_Token, 
	Id_Informant, 
	Id_Stimulus, 
	Original,
	Numerus,
	IF(t.Id_Tokengruppe IS NULL OR (t.Token = '' AND NOT EXISTS (SELECT * FROM VTBL_Tokengruppe_phon_Typ tgp JOIN phon_Typen p USING (Id_phon_Typ) where tgp.Id_Tokengruppe = t.Id_Tokengruppe and p.Quelle = Erhebung)), 
		IF(t.IPA = '' OR t.IPA IS NULL, 
			IF(t.Original = '' OR t.Original IS NULL, 
				t.Token, 
				t.Original), 
			t.IPA), 
		CONCAT(
			IF(t.IPA = '' OR t.IPA IS NULL, 
				IF(t.Original = '' OR t.Original IS NULL, 
					t.Token, 
					t.Original), 
				t.IPA), 
			'###', 
			IF (t.Token = '',
				(SELECT 
					IF(p.Original != '',
						p.Original,
						p.Beta)
				FROM tokengruppen v join vtbl_tokengruppe_phon_typ vtp using (Id_Tokengruppe) join phon_Typen p using (Id_phon_Typ) where v.Id_Tokengruppe = t.Id_Tokengruppe and p.Quelle = Erhebung),
				(SELECT 
					IF(v.IPA = '' OR v.IPA IS NULL OR v.IPA LIKE '%XXX%', 
						IF(v.Original = '' OR v.Original IS NULL OR v.Original LIKE '%XXX%', 
							REPLACE(REPLACE(v.Tokengruppe, '<', '&lt;'), '>', '&gt;'),
							v.Original), 
						v.IPA) 
				FROM v_tokengruppen v WHERE v.Id_Tokengruppe = t.Id_Tokengruppe)
		)
	)) as Beleg,
	IF(t.IPA = '' OR t.IPA IS NULL, IF(t.Original = '' OR t.Original IS NULL, 4, 3), IF(VA_IPA, 2, 1)) AS Beleg_Codierung,
	Erfasst_am
FROM Tokens t 
JOIN Stimuli USING (Id_Stimulus) 
JOIN Bibliographie ON Erhebung = Abkuerzung$$

DELIMITER ;