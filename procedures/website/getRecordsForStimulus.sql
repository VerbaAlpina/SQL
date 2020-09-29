DROP PROCEDURE IF EXISTS getRecords;

DELIMITER $$

CREATE PROCEDURE getRecords (id_st INT UNSIGNED, show_typified BOOLEAN, show_with_concept BOOLEAN, show_alpes BOOLEAN, filter_lang VARCHAR(20))

BEGIN

DROP TEMPORARY TABLE IF EXISTS rstimuli;
DROP TEMPORARY TABLE IF EXISTS res;

CREATE TEMPORARY TABLE rstimuli (ID_Stimulus INT UNSIGNED) ENGINE=Memory;
IF id_st = 90322 THEN
	INSERT INTO rstimuli SELECT ID_Stimulus FROM Stimuli WHERE Erhebung = 'CROWD';
ELSE
	INSERT INTO rstimuli VALUES (id_st);
END IF;

CREATE TEMPORARY TABLE res AS
-- TOKENS
SELECT
	'T' AS Art,
	-1 AS Id_Typ,
	Token, 
	tk.Genus, 
	tk.IPA, 
	tk.Original, 
	tk.Id_Stimulus,
	s.Erhebung,
	tk.Konzepte,
	IF(tk.Id_Stimulus = 90322, GROUP_CONCAT(DISTINCT i.Ortsname ORDER BY i.Ortsname ASC), GROUP_CONCAT(DISTINCT i.Nummer ORDER BY i.Position ASC)) as Informanten,
	tk.Bemerkung AS Bemerkungen,
	IFNULL(vt.Tokengruppe, '') AS Tokengruppe,
	Id_morph_Typ,
	lex_unique(m.Orth, m.Sprache, m.Genus) as Typ,
	IFNULL(tk.Relevanz, 1) AS Relevanz,
	GROUP_CONCAT(tk.Id_Token) AS TokenIds,
	GROUP_CONCAT(tk.Aeusserung SEPARATOR '###') AS Aeusserungen
FROM 
	(SELECT Id_Token, t.Id_Stimulus, t.Id_Informant, Token, IPA, Original, Genus, GROUP_CONCAT(Id_Konzept ORDER BY Id_Konzept) as Konzepte, Id_Tokengruppe, t.Bemerkung, SUM(Relevanz) > 0 AS Relevanz, Aeusserung
		FROM 
		Tokens t 
		LEFT JOIN VTBL_Token_Konzept USING (Id_Token)
		LEFT JOIN Aeusserungen USING (Id_Aeusserung)
		LEFT JOIN Konzepte USING (Id_Konzept)
		WHERE (Grammatikalisch IS NULL OR NOT Grammatikalisch)
		GROUP BY Id_Token) AS tk
	LEFT JOIN Stimuli s USING (ID_Stimulus)
	LEFT JOIN Informanten i USING (Id_Informant)
	LEFT JOIN VTBL_Token_morph_Typ vm USING (Id_Token)
	LEFT JOIN morph_Typen m USING (Id_morph_Typ)
	LEFT JOIN V_Tokengruppen vt USING (Id_Tokengruppe)
WHERE 
	NOT EXISTS (SELECT * FROM locks WHERE Wert = 
		CONCAT(tk.Token, '%%%', tk.Genus, '%%%', tk.Id_Stimulus, '%%%', SUBSTR(tk.Bemerkung, 0, 70), '%%%', IFNULL(vt.Tokengruppe, ''), '%%%T%%%[', IFNULL(tk.Konzepte, ''), ']'))
	AND Token != ''
	AND (m.Quelle IS NULL OR m.Quelle = 'VA')
	AND tk.Id_Stimulus IN (SELECT * FROM rstimuli)
	AND (show_typified OR Id_morph_Typ IS NULL)
	AND (show_with_concept OR Konzepte IS NULL)
	AND (show_alpes OR i.Alpenkonvention)
	AND (filter_lang = '' OR i.Sprache = filter_lang)
GROUP BY Token collate utf8_bin, tk.Genus, tk.Id_Stimulus, tk.Konzepte, tk.Bemerkung, vt.Tokengruppe,
	s.Erhebung, Id_morph_Typ;

	
INSERT INTO res
-- TOKENGRUPPEN
SELECT
	'G' AS Art,
	-1 AS Id_Typ,
	Tokengruppe AS Token, 
	tk.Genus, 
	IF(LOCATE('XXX', IPA), '', IPA) as IPA,
	IF(LOCATE('XXX', Original), '', Original) as Original,
	Id_Stimulus,
	s.Erhebung,
	tk.Konzepte,
	IF(Id_Stimulus = 90322, GROUP_CONCAT(DISTINCT i.Ortsname ORDER BY i.Ortsname ASC), GROUP_CONCAT(DISTINCT i.Nummer ORDER BY i.Position ASC)) as Informanten,
	tk.Bemerkung AS Bemerkungen,
	'' AS Tokengruppe,
	Id_morph_Typ,
	lex_unique(m.Orth, m.Sprache, m.Genus) as Typ,
	IFNULL(tk.Relevanz, 1) AS Relevanz,
	GROUP_CONCAT(tk.Id_Tokengruppe) AS TokenIds,
	GROUP_CONCAT(tk.Aeusserung SEPARATOR '###') AS Aeusserungen
FROM 
	(SELECT Id_Tokengruppe, t.Id_Stimulus, t.Id_Informant, Tokengruppe, IPA, Original, Genus, GROUP_CONCAT(Id_Konzept ORDER BY Id_Konzept) as Konzepte, t.Bemerkung, SUM(Relevanz) > 0 AS Relevanz, Aeusserung
		FROM 
		V_Tokengruppen t 
		LEFT JOIN VTBL_Tokengruppe_Konzept USING (Id_Tokengruppe)
		LEFT JOIN Aeusserungen USING (Id_Aeusserung)
		LEFT JOIN Konzepte USING (Id_Konzept)
		WHERE (Relevanz IS NULL OR Relevanz)
		GROUP BY Id_Tokengruppe) AS tk
	LEFT JOIN Stimuli s USING (ID_Stimulus)
	LEFT JOIN Informanten i USING (Id_Informant)
	LEFT JOIN VTBL_Tokengruppe_morph_Typ vm USING (Id_Tokengruppe)
	LEFT JOIN morph_Typen m USING (Id_morph_Typ)
WHERE 
	NOT EXISTS (SELECT * FROM locks WHERE Wert = 
		CONCAT(tk.Tokengruppe, '%%%', tk.Genus, '%%%', tk.Id_Stimulus, '%%%', SUBSTR(tk.Bemerkung, 0, 70), '%%%%%%G%%%[', IFNULL(tk.Konzepte, ''), ']'))
	AND Tokengruppe != ''
	AND (m.Quelle IS NULL OR m.Quelle = 'VA')
	AND tk.Id_Stimulus IN (SELECT * FROM rstimuli)
	AND (show_typified OR Id_morph_Typ IS NULL)
	AND (show_with_concept OR Konzepte IS NULL)
	AND (show_alpes OR i.Alpenkonvention)
	AND (filter_lang = '' OR i.Sprache = filter_lang)
GROUP BY Tokengruppe collate utf8_bin, tk.Genus, Id_Stimulus, tk.Konzepte, tk.Bemerkung,
	s.Erhebung, Id_morph_Typ;
	
INSERT INTO res
-- MORPH-LEX. TYPEN AUS ATLANTEN
SELECT
	'M' AS Art,
	srm.Id_morph_Typ AS Id_Typ, 
	CONCAT(s.Erhebung, '-MTyp ', srm.Orth) AS Token, 
	tk.Genus,
	'' AS IPA,
	'' AS Original,
	Id_Stimulus,
	s.Erhebung,
	tk.Konzepte,
	IF(Id_Stimulus = 90322, GROUP_CONCAT(DISTINCT i.Ortsname ORDER BY i.Ortsname ASC), GROUP_CONCAT(DISTINCT i.Nummer ORDER BY i.Position ASC)) as Informanten,
	tk.Bemerkung AS Bemerkungen,
	IFNULL(grm.Orth, '') AS Tokengruppe,
	vam.Id_morph_Typ,
	lex_unique(vam.Orth, vam.Sprache, vam.Genus) as Typ,
	IFNULL(tk.Relevanz, 1) AS Relevanz,
	GROUP_CONCAT(tk.Id_Token) AS TokenIds,
	GROUP_CONCAT(tk.Aeusserung SEPARATOR '###') AS Aeusserungen
FROM 
	(SELECT Id_Token, t.Id_Stimulus, t.Id_Informant, Token, Id_Tokengruppe, IPA, Original, Genus, GROUP_CONCAT(Id_Konzept ORDER BY Id_Konzept) as Konzepte, t.Bemerkung, SUM(Relevanz) > 0 AS Relevanz, Aeusserung
		FROM 
		Tokens t 
		LEFT JOIN VTBL_Token_Konzept USING (Id_Token)
		LEFT JOIN Aeusserungen USING (Id_Aeusserung)
		LEFT JOIN Konzepte USING (Id_Konzept)
		WHERE (Relevanz IS NULL OR Relevanz)
		GROUP BY Id_Token) AS tk
	JOIN VTBL_Token_morph_Typ vm2 USING (ID_Token) 
	JOIN morph_Typen srm USING (Id_morph_Typ) 
	LEFT JOIN Stimuli s USING (Id_Stimulus)
	LEFT JOIN Informanten i USING (Id_Informant)
	LEFT JOIN (SELECT Id_Token, m.Id_morph_Typ, Quelle, Orth, Sprache, Genus FROM VTBL_Token_morph_Typ vm JOIN morph_typen m USING (Id_morph_Typ)) vam ON vam.Id_Token = tk.Id_Token AND vam.Quelle = 'VA'
	LEFT JOIN (SELECT Id_Tokengruppe, Quelle, Orth FROM VTBL_Tokengruppe_morph_Typ JOIN morph_typen USING (Id_morph_Typ)) grm ON grm.Id_Tokengruppe = tk.Id_Tokengruppe AND grm.Quelle = s.Erhebung
WHERE 
	NOT EXISTS (SELECT * FROM locks WHERE Wert = 
		CONCAT(s.Erhebung, '-MTyp ', srm.Orth, '%%%', tk.Genus, '%%%', tk.Id_Stimulus, '%%%', SUBSTR(tk.Bemerkung, 0, 70), '%%%%%%M%%%[', IFNULL(tk.Konzepte, ''), ']'))
	AND tk.Token = '' 
	AND srm.Quelle = s.Erhebung
	AND tk.Id_Stimulus IN (SELECT * FROM rstimuli)
	AND (show_typified OR vam.Id_morph_Typ IS NULL)
	AND (show_with_concept OR Konzepte IS NULL)
	AND (show_alpes OR i.Alpenkonvention)
	AND (filter_lang = '' OR i.Sprache = filter_lang)
GROUP BY srm.Id_morph_Typ, tk.Genus, Id_Stimulus, tk.Konzepte, tk.Bemerkung,
	s.Erhebung, vam.Id_morph_Typ;
	
INSERT INTO res
-- PHON. TYPEN AUS ATLANTEN
SELECT DISTINCT 
	'P' AS Art,
	p.Id_phon_Typ AS Id_Typ, 
	CONCAT(s.Erhebung, '-PTyp ', IF(p.Original = '', p.Beta, p.Original)) AS Token, 
	tk.Genus,
	'' AS IPA,
	'' AS Original,
	tk.Id_Stimulus,
	s.Erhebung,
	tk.Konzepte,
	IF(tk.Id_Stimulus = 90322, GROUP_CONCAT(DISTINCT i.Ortsname ORDER BY i.Ortsname ASC), GROUP_CONCAT(DISTINCT i.Nummer ORDER BY i.Position ASC)) as Informanten,
	tk.Bemerkung AS Bemerkungen,
	IFNULL(grp.Beta, '') AS Tokengruppe,
	vam.Id_morph_Typ,
	lex_unique(vam.Orth, vam.Sprache, vam.Genus) as Typ,
	IFNULL(tk.Relevanz, 1) AS Relevanz,
	GROUP_CONCAT(tk.Id_Token) AS TokenIds,
	GROUP_CONCAT(tk.Aeusserung SEPARATOR '###') AS Aeusserungen
FROM 
	(SELECT Id_Token, t.Id_Stimulus, t.Id_Informant, Token, IPA, Original, Genus, GROUP_CONCAT(Id_Konzept ORDER BY Id_Konzept) as Konzepte, t.Bemerkung, SUM(Relevanz) > 0 AS Relevanz, Aeusserung, Id_Tokengruppe
		FROM 
		Tokens t 
		LEFT JOIN VTBL_Token_Konzept USING (Id_Token)
		LEFT JOIN Aeusserungen USING (Id_Aeusserung)
		LEFT JOIN Konzepte USING (Id_Konzept)
		WHERE (Relevanz IS NULL OR Relevanz)
		GROUP BY Id_Token) AS tk
	JOIN VTBL_Token_phon_Typ v2 USING (ID_Token) 
	JOIN phon_Typen p USING (Id_phon_Typ) 
	LEFT JOIN Stimuli s USING (Id_Stimulus)
	LEFT JOIN Informanten i USING (Id_Informant)
	LEFT JOIN (SELECT Id_Token, Quelle, Id_morph_Typ, Orth, Sprache, Genus FROM VTBL_Token_morph_Typ JOIN morph_Typen USING (Id_morph_Typ)) vam ON vam.Id_Token = tk.Id_Token AND vam.Quelle = 'VA'
	LEFT JOIN (SELECT Id_Tokengruppe, Quelle, IF(Original != '', Original, Beta) AS Beta FROM VTBL_Tokengruppe_phon_Typ JOIN phon_typen USING (Id_phon_Typ)) grp ON grp.Id_Tokengruppe = tk.Id_Tokengruppe AND grp.Quelle = s.Erhebung
WHERE 
	NOT EXISTS (SELECT * FROM locks WHERE Wert = 
		CONCAT(s.Erhebung, '-PTyp ', IF(p.Original != '', p.Original, p.Beta), '%%%', tk.Genus, '%%%', tk.Id_Stimulus, '%%%', SUBSTR(tk.Bemerkung, 0, 70), '%%%%%%P%%%[', IFNULL(tk.Konzepte, ''), ']'))
	AND tk.Token = '' 
	AND p.Quelle = s.Erhebung
	AND tk.Id_Stimulus IN (SELECT * FROM rstimuli)
	AND (show_typified OR vam.Id_morph_Typ IS NULL)
	AND (show_with_concept OR Konzepte IS NULL)
	AND (show_alpes OR i.Alpenkonvention)
	AND (filter_lang = '' OR i.Sprache = filter_lang)
GROUP BY p.Id_phon_Typ, tk.Genus, tk.Id_Stimulus, tk.Konzepte, tk.Bemerkung,
	s.Erhebung, vam.Id_morph_Typ, grp.Beta;

INSERT INTO res
SELECT DISTINCT
	'GP' AS Art,
	Id_phon_Typ AS Id_Typ, 
	CONCAT(s.Erhebung, '-PTyp ', IF(p.Original = '', p.Beta, p.Original)) AS Token,
	tk.Genus, 
	'' as IPA,
	'' as Original,
	Id_Stimulus,
	s.Erhebung,
	tk.Konzepte,
	IF(Id_Stimulus = 90322, GROUP_CONCAT(DISTINCT i.Ortsname ORDER BY i.Ortsname ASC), GROUP_CONCAT(DISTINCT i.Nummer ORDER BY i.Position ASC)) as Informanten,
	tk.Bemerkung AS Bemerkungen,
	'' AS Tokengruppe,
	vam.Id_morph_Typ,
	lex_unique(vam.Orth, vam.Sprache, vam.Genus) as Typ,
	IFNULL(tk.Relevanz, 1) AS Relevanz,
	GROUP_CONCAT(tk.Id_Tokengruppe) AS TokenIds,
	GROUP_CONCAT(tk.Aeusserung SEPARATOR '###') AS Aeusserungen
FROM 
	(SELECT Id_Tokengruppe, t.Id_Stimulus, t.Id_Informant, Genus, GROUP_CONCAT(Id_Konzept ORDER BY Id_Konzept) as Konzepte, t.Bemerkung, SUM(Relevanz) > 0 AS Relevanz, Aeusserung
		FROM 
		V_Tokengruppen t 
		LEFT JOIN VTBL_Tokengruppe_Konzept USING (Id_Tokengruppe)
		LEFT JOIN Aeusserungen USING (Id_Aeusserung)
		LEFT JOIN Konzepte USING (Id_Konzept)
		WHERE (Relevanz IS NULL OR Relevanz)
		GROUP BY Id_Tokengruppe) AS tk
	JOIN VTBL_Tokengruppe_phon_Typ tgp USING (ID_Tokengruppe) 
	JOIN phon_Typen p USING (Id_phon_Typ) 
	LEFT JOIN Stimuli s USING (ID_Stimulus)
	LEFT JOIN Informanten i USING (Id_Informant)
	LEFT JOIN (SELECT Id_Tokengruppe, Quelle, Id_morph_Typ, Orth, Sprache, Genus FROM VTBL_Tokengruppe_morph_Typ JOIN morph_Typen USING (Id_morph_Typ)) vam ON vam.Id_Tokengruppe = tk.Id_Tokengruppe AND vam.Quelle = 'VA'
WHERE 
	NOT EXISTS (SELECT * FROM locks WHERE Wert = 
		CONCAT(s.Erhebung, '-GPTyp ', IF(p.Original != '', p.Original, p.Beta), '%%%', tk.Genus, '%%%', tk.Id_Stimulus, '%%%', SUBSTR(tk.Bemerkung, 0, 70), '%%%%%%G%%%[', IFNULL(tk.Konzepte, ''), ']'))
	AND p.Quelle = s.Erhebung
	AND tk.Id_Stimulus IN (SELECT * FROM rstimuli)
	AND (show_typified OR vam.Id_morph_Typ IS NULL)
	AND (show_with_concept OR Konzepte IS NULL)
	AND (show_alpes OR i.Alpenkonvention)
	AND (filter_lang = '' OR i.Sprache = filter_lang)
GROUP BY p.Beta collate utf8_bin, tk.Genus, Id_Stimulus, tk.Konzepte, tk.Bemerkung,
	s.Erhebung, vam.Id_morph_Typ;
	
	
INSERT INTO res	
SELECT DISTINCT 
	'K' AS Art,
	m2.Id_morph_Typ AS Id_Typ, 
	CONCAT(s.Erhebung, '-KTyp ', m2.Orth) AS Token, 
	tk.Genus,
	'' AS IPA,
	'' AS Original,
	Id_Stimulus,
	s.Erhebung,
	tk.Konzepte,
	IF(Id_Stimulus = 90322, GROUP_CONCAT(DISTINCT i.Ortsname ORDER BY i.Ortsname ASC), GROUP_CONCAT(DISTINCT i.Nummer ORDER BY i.Position ASC)) as Informanten,
	tk.Bemerkung AS Bemerkungen,
	'' AS Tokengruppe,
	vam.Id_morph_Typ,
	lex_unique(vam.Orth, vam.Sprache, vam.Genus) as Typ,
	IFNULL(tk.Relevanz, 1) AS Relevanz,
	GROUP_CONCAT(tk.Id_Tokengruppe) AS TokenIds,
	GROUP_CONCAT(tk.Aeusserung SEPARATOR '###') AS Aeusserungen
FROM 
	(SELECT Id_Tokengruppe, t.Id_Stimulus, t.Id_Informant, IPA, Original, Genus, GROUP_CONCAT(Id_Konzept ORDER BY Id_Konzept) as Konzepte, t.Bemerkung, SUM(Relevanz) > 0 AS Relevanz, Aeusserung
		FROM 
		V_Tokengruppen t 
		LEFT JOIN VTBL_Tokengruppe_Konzept USING (Id_Tokengruppe)
		LEFT JOIN Aeusserungen USING (Id_Aeusserung)
		LEFT JOIN Konzepte USING (Id_Konzept)
		WHERE (Relevanz IS NULL OR Relevanz)
		GROUP BY Id_Tokengruppe) AS tk
	JOIN VTBL_Tokengruppe_morph_Typ vm2 USING (ID_Tokengruppe) 
	JOIN morph_Typen m2 USING (Id_morph_Typ) 
	JOIN Stimuli s USING (Id_Stimulus)
	LEFT JOIN Informanten i USING (Id_Informant)
	LEFT JOIN (SELECT Id_Tokengruppe, Quelle, Id_morph_Typ, Orth, Sprache, Genus FROM VTBL_Tokengruppe_morph_Typ JOIN morph_Typen USING (Id_morph_Typ)) vam ON vam.Id_Tokengruppe = tk.Id_Tokengruppe AND vam.Quelle = 'VA'
WHERE
	NOT EXISTS (SELECT * FROM locks WHERE Wert = 
		CONCAT(s.Erhebung, '-KTyp ', m2.Orth, '%%%', tk.Genus, '%%%', tk.Id_Stimulus, '%%%', SUBSTR(tk.Bemerkung, 0, 70), '%%%%%%T%%%[', IFNULL(tk.Konzepte, ''), ']'))
	AND m2.Quelle = s.Erhebung
	AND tk.Id_Stimulus IN (SELECT * FROM rstimuli)
	AND (show_typified OR vam.Id_morph_Typ IS NULL)
	AND (show_with_concept OR Konzepte IS NULL)
	AND (show_alpes OR i.Alpenkonvention)
	AND (filter_lang = '' OR i.Sprache = filter_lang)
GROUP BY m2.Id_morph_Typ, tk.Genus, Id_Stimulus, tk.Konzepte, tk.Bemerkung,
	s.Erhebung, vam.Id_morph_Typ;
	
SELECT * FROM res ORDER BY Token;
	
END$$

DELIMITER ;