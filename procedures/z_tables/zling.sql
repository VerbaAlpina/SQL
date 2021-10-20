DELIMITER $$

DROP PROCEDURE IF EXISTS zling$$

CREATE PROCEDURE `zling` ()
BEGIN

	START TRANSACTION;
	CALL buildConceptCount();
	CALL buildConceptDepthTable();
	CALL buildSourceList();
	CALL computeTypeOccurances();
	COMMIT;

	DELETE FROM A_Referenzen;
	
	INSERT INTO A_Referenzen
		SELECT Id_morph_Typ, CONCAT (lem.Quelle, '|', lem.Subvocem, '|', lem.Bibl_Verweis, '|', Link, '|', Text_Referenz) AS Referenz
		FROM morph_typen m 
			JOIN VTBL_morph_Typ_Lemma USING (Id_morph_Typ)
			JOIN Lemmata lem USING (Id_Lemma)
		WHERE lem.Subvocem != '<vacat>'
	UNION
		SELECT m.Id_morph_Typ, CONCAT (lem.Quelle, '|', lem.Subvocem, '|', lem.Bibl_Verweis, '|', Link, '|', Text_Referenz) AS Referenz
		FROM morph_typen m
			JOIN VTBL_morph_Typ_Bestandteile b USING (Id_morph_Typ)
			JOIN morph_Typen m2 ON b.Id_Bestandteil = m2.Id_morph_Typ
			JOIN VTBL_morph_Typ_Lemma v ON m2.Id_morph_Typ = v.Id_morph_Typ
			JOIN Lemmata lem USING (Id_Lemma)
		WHERE lem.Subvocem != '<vacat>' AND b.Id_morph_Typ != b.Id_Bestandteil AND NOT EXISTS (SELECT * FROM VTBL_morph_Typ_Lemma v2 JOIN lemmata l USING (Id_Lemma) WHERE v2.Id_morph_Typ = m.Id_morph_Typ AND l.Quelle != 'VA');
	
	DELETE FROM A_Basistyp_Referenzen;
		
	INSERT INTO A_Basistyp_Referenzen
	SELECT Id_Basistyp, CONCAT (lem.Quelle, '|', lem.Subvocem, '|', lem.Bibl_Verweis, '|', Link, '|', Text_Referenz) AS Referenz
	FROM Basistypen b 
		JOIN VTBL_Basistyp_Lemma USING (Id_Basistyp)
		JOIN Lemmata_Basistypen lem USING (Id_Lemma);
	
	DELETE FROM A_Basistypen_Zuordnung;
	
	INSERT INTO A_Basistypen_Zuordnung
		SELECT Id_morph_Typ, Id_Basistyp, Basistypen.Orth, Sprache, Unsicher
		FROM VTBL_morph_Basistyp JOIN Basistypen USING (Id_Basistyp)
	UNION
		SELECT mcomp.Id_morph_Typ, Id_Basistyp, Basistypen.Orth, Basistypen.Sprache, Unsicher
		FROM morph_typen mcomp 
			JOIN VTBL_morph_Typ_Bestandteile USING (Id_morph_Typ) 
			JOIN morph_Typen mpart ON Id_Bestandteil = mpart.Id_morph_Typ
			JOIN VTBL_morph_Basistyp vb ON mpart.Id_morph_Typ = vb.Id_morph_Typ
			JOIN Basistypen USING (Id_Basistyp);
	
	DROP TABLE IF EXISTS z_ling_temp;
	
	CREATE TABLE z_ling_temp (
	  Id_Instance bigint(20) unsigned DEFAULT NULL,
	  Instance varchar(5000) CHARACTER SET utf8mb4 NOT NULL,
	  Instance_Encoding enum('1','2','3','4') NOT NULL,
	  Instance_Original varchar(5000) CHARACTER SET utf8mb4 NOT NULL,
	  `Number` enum('','sg','pl','sg+pl') NOT NULL,
	  Id_Informant int(10) unsigned NOT NULL,
	  Instance_Source varchar(200) NOT NULL,
	  id_stimulus int(10) unsigned NOT NULL,
	  Id_Concept int(11) unsigned DEFAULT NULL,
	  QID int(10) unsigned DEFAULT NULL,
	  Geo_Data varchar(100) DEFAULT NULL,
	  Alpine_Convention tinyint(1) NOT NULL,
	  Id_Community int(10) unsigned NOT NULL,
	  Community_Name varchar(200) DEFAULT NULL,
	  Community_Center varchar(100) DEFAULT NULL,
	  Geonames_Id int unsigned DEFAULT NULL,
	  Year_Publication varchar(50) DEFAULT NULL,
	  Year_Survey binary(0) DEFAULT NULL,
	  Informant_Lang char(9) DEFAULT NULL,
	  Informant_Dialect varchar(100) DEFAULT NULL,
	  Type_Kind varchar(1) DEFAULT NULL,
	  Id_Type int(11) unsigned DEFAULT NULL,
	  Type varchar(200) DEFAULT NULL,
	  Type_Lang enum('','sla','roa','gem') DEFAULT NULL,
	  Type_Reference varchar(1000) DEFAULT NULL,
	  Source_Typing varchar(50) DEFAULT NULL,
	  Type_LIDs varchar(100) DEFAULT NULL,
	  POS varchar(8) DEFAULT NULL,
	  Affix varchar(20) DEFAULT NULL,
	  Gender varchar(1) DEFAULT NULL,
	  Id_Base_Type int(10) unsigned DEFAULT NULL,
	  Base_Type varchar(200) DEFAULT NULL,
	  Base_Type_Lang char(3) DEFAULT NULL,
	  Base_Type_Unsure tinyint(1) DEFAULT NULL,
	  Base_Type_Reference varchar(1000) DEFAULT NULL,
	  Id_Etymon int(10) unsigned DEFAULT NULL,
	  Etymon varchar(200) DEFAULT NULL,
	  Etymon_Lang char(3) DEFAULT NULL,
	  Remarks binary(0) DEFAULT NULL,
	  Cluster_Id int(11) NOT NULL,
	  external_id varchar(20) NOT NULL,
	  KEY z_ling_external_id_idx (external_id) USING BTREE,
	  KEY z_ling_id_instance_idx (Id_Instance) USING BTREE,
	  KEY z_ling_id_concept_idx (Id_Concept) USING BTREE,
	  KEY z_ling_id_type_idx (Id_Type,Type_Kind) USING BTREE,
	  KEY z_ling_id_community_idx (Id_Community) USING BTREE,
	  KEY z_ling_id_base_type_idx (Id_Base_Type) USING BTREE,
	  INDEX instance_index (Instance(50)) USING BTREE
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;

   INSERT INTO z_ling_temp
	  -- morph. Types Tokens
	  SELECT 
		t.Id_Token AS Id_Beleg,
		t.Beleg,
		t.Beleg_Codierung AS Beleg_Codierung,
		t.Original AS Beleg_Original,
		IF(t.Numerus IS NULL, '', t.Numerus) as Numerus,
		i.Id_Informant,
		CONCAT(s.Erhebung, '#', s.Karte, '#', s.Nummer, '#', IF(LOCATE('@', i.nummer) = 0, i.nummer, SUBSTR(i.nummer, 1, LOCATE('@', i.nummer) - 1)), '#', i.Ortsname) as Quelle_Beleg,
		s.Id_Stimulus as Id_Stimulus,
		k.Id_Konzept, 
		k.QID,
		AsText(i.Georeferenz) as Geodaten,
		i.Alpenkonvention as Alpenkonvention,
		i.Id_Gemeinde,
		CONCAT(o.Name, getGeoTranslationString(o.Id_Ort)) AS Gemeinde,
		AsText(o.Mittelpunkt) AS Mittelpunkt_Gemeinde,
		IF(o.Geonames = 0, NULL, o.Geonames),
		IF(s.Erhebung = 'CROWD', (SELECT YEAR(Erstellt_Am) FROM va_xxx.Versionen WHERE Erstellt_Am > t.Erfasst_am ORDER BY Erstellt_Am ASC LIMIT 1), bib.Jahr) AS Publikationsjahr,
		NULL AS Erhebungsjahr,
		i.Sprache AS Sprache_Informant,
		IF(d.Name = "no_dialect", NULL, d.Name) as Dialekt_Informant,
		IF(Id_morph_Typ != 4144 AND Id_morph_Typ IS NOT NULL, 'L', NULL) AS Art_Typ,
		IF(Id_morph_Typ = 4144, NULL, Id_morph_Typ) AS Id_Typ,
		IF(Id_morph_Typ = 4144, NULL, m.Orth) AS Typ,
		m.Sprache AS Sprache_Typ,
		r.Referenz,
		m.Quelle AS Quelle_Typisierung,
		(SELECT GROUP_CONCAT(DISTINCT LID ORDER BY Sortier_Rang DESC) FROM lids JOIN Sprachen ON Sprache = Abkuerzung WHERE lids.Id_morph_Typ = m.Id_morph_Typ) AS Typ_LIDs,
		IF(m.Wortart IS NULL, '', m.Wortart) as Wortart,
		IF(m.Affix IS NULL, '', m.Affix) as Affix,
		IF(m.Genus IS NULL, '', m.Genus) as Genus,
		b.Id_Basistyp,
		b.Orth as Basistyp,
		b.Sprache as Sprache_Basistyp,
		b.Unsicher AS Base_Type_Unsure,
		br.Referenz as Referenz_Basistyp,
		e.Id_Etymon,
		e.Orth as Etymon,
		e.Sprache AS Sprache_Etymon,
		NULL AS Bemerkungen,
		IFNULL(a.Nummer, -1) AS Cluster_Id,
		CONCAT('S', t.Id_Token) AS External_Id
	FROM 
		V_Tokens t
		JOIN VTBL_Token_morph_Typ v0 USING (Id_Token)
		LEFT JOIN morph_Typen m USING (Id_morph_Typ)
		LEFT JOIN A_Basistypen_Zuordnung b USING (Id_morph_Typ)
		LEFT JOIN VTBL_Basistyp_Etymon v2 USING (Id_Basistyp)
		LEFT JOIN Etyma e USING (Id_Etymon)
		LEFT JOIN Informanten i USING (Id_Informant)
		LEFT JOIN Orte o ON o.Id_Ort = i.Id_Gemeinde
		LEFT JOIN Bibliographie bib ON i.Erhebung = bib.Abkuerzung
		LEFT JOIN VTBL_Token_Konzept v3 USING (Id_Token)
		LEFT JOIN Konzepte k USING (Id_Konzept)
		LEFT JOIN Stimuli s USING (Id_Stimulus)
		LEFT JOIN A_Referenzen r USING (Id_morph_Typ)
		LEFT JOIN A_Basistyp_Referenzen br USING (Id_Basistyp)
		LEFT JOIN Orte_Uebersetzungen ou USING (Id_Ort)
		LEFT JOIN A_Punkt_Index a ON i.Georeferenz = a.Geodaten
		LEFT JOIN dialects d ON Id_Dialekt = Id_Dialect
	WHERE
		(Grammatikalisch IS NULL OR Grammatikalisch = 0) AND
		i.Georeferenz IS NOT NULL AND i.Georeferenz != '' AND GeometryType(i.Georeferenz) = 'POINT' AND i.Id_Gemeinde IS NOT NULL
		
	UNION ALL

	-- Phon. Types Tokens
	SELECT 
		t.Id_Token AS Id_Beleg,
		t.Beleg,
		t.Beleg_Codierung AS Beleg_Codierung,
		t.Original AS Beleg_Original,
		IF(t.Numerus IS NULL, '', t.Numerus) as Numerus,
		i.Id_Informant,
		CONCAT(s.Erhebung, '#', s.Karte, '#', s.Nummer, '#', IF(LOCATE('@', i.nummer) = 0, i.nummer, SUBSTR(i.nummer, 1, LOCATE('@', i.nummer) - 1)), '#', i.Ortsname) as Quelle_Beleg,
		s.Id_Stimulus as Id_Stimulus,
		k.Id_Konzept,
		k.QID,
		AsText(i.Georeferenz) as Geodaten,
		i.Alpenkonvention as Alpenkonvention,
		i.Id_Gemeinde,
		CONCAT(o.Name, getGeoTranslationString(o.Id_Ort)) AS Gemeinde,
		AsText(o.Mittelpunkt) AS Mittelpunkt_Gemeinde,
		IF(o.Geonames = 0, NULL, o.Geonames),
		IF(s.Erhebung = 'CROWD', (SELECT YEAR(Erstellt_Am) FROM va_xxx.Versionen WHERE Erstellt_Am > t.Erfasst_am ORDER BY Erstellt_Am ASC LIMIT 1), bib.Jahr) AS Publikationsjahr,
		NULL AS Erhebungsjahr,
		i.Sprache AS Sprache_Informant,
		IF(d.Name = "no_dialect", NULL, d.Name) as Dialekt_Informant,
		'P' AS Art_Typ,
		Id_phon_Typ AS Id_Typ,
		IF(p.IPA IS NULL OR p.IPA = '', IF(p.Original IS NULL OR p.Original = '', p.Beta, p.Original), p.IPA) AS Typ,
		'' AS Sprache_Typ,
		NULL AS Referenz,
		p.Quelle AS Quelle_Typisierung,
		NULL AS Typ_LIDs,
		IF(p.Wortart IS NULL, '', p.Wortart) as Wortart,
		IF(p.Affix IS NULL, '', p.Affix) as Affix,
		IF(p.Genus IS NULL, '', p.Genus) as Genus,
		NULL AS Id_Basistyp,
		NULL AS Basistyp,
		NULL as Sprache_Basistyp,
		NULL AS Base_Type_Unsure,
		NULL as Referenz_Basistyp,
		NULL AS Id_Etymon,
		NULL AS Etymon,
		NULL AS Sprache_Etymon,
		NULL AS Bemerkungen,
		IFNULL(a.Nummer, -1) AS Cluster_Id,
		CONCAT('S', t.Id_Token) AS External_Id
	FROM 
		V_Tokens t
		JOIN VTBL_Token_phon_Typ v0 USING (Id_Token)
		LEFT JOIN phon_Typen p USING (Id_phon_Typ)
		LEFT JOIN Informanten i USING (Id_Informant)
		LEFT JOIN Orte o ON o.Id_Ort = i.Id_Gemeinde
		LEFT JOIN Bibliographie bib ON i.Erhebung = bib.Abkuerzung
		LEFT JOIN VTBL_Token_Konzept v3 USING (Id_Token)
		LEFT JOIN Konzepte k USING (Id_Konzept)
		LEFT JOIN Stimuli s USING (Id_Stimulus)
		LEFT JOIN A_Punkt_Index a ON i.Georeferenz = a.Geodaten
		LEFT JOIN dialects d ON Id_Dialekt = Id_Dialect
	WHERE
		(Grammatikalisch IS NULL OR Grammatikalisch = 0) AND
		i.Georeferenz IS NOT NULL AND i.Georeferenz != '' AND GeometryType(i.Georeferenz) = 'POINT' AND i.Id_Gemeinde IS NOT NULL
		
	UNION ALL
	
		-- Tokens without typification
		SELECT 
		t.Id_Token AS Id_Beleg,
		t.Beleg,
		t.Beleg_Codierung AS Beleg_Codierung,
		t.Original AS Beleg_Original,
		IF(t.Numerus IS NULL, '', t.Numerus) as Numerus,
		i.Id_Informant,
		CONCAT(s.Erhebung, '#', s.Karte, '#', s.Nummer, '#', IF(LOCATE('@', i.nummer) = 0, i.nummer, SUBSTR(i.nummer, 1, LOCATE('@', i.nummer) - 1)), '#', i.Ortsname) as Quelle_Beleg,
		s.Id_Stimulus as Id_Stimulus,
		k.Id_Konzept, 
		k.QID,
		AsText(i.Georeferenz) as Geodaten,
		i.Alpenkonvention as Alpenkonvention,
		i.Id_Gemeinde,
		CONCAT(o.Name, getGeoTranslationString(o.Id_Ort)) AS Gemeinde,
		AsText(o.Mittelpunkt) AS Mittelpunkt_Gemeinde,
		IF(o.Geonames = 0, NULL, o.Geonames),
		IF(s.Erhebung = 'CROWD', (SELECT YEAR(Erstellt_Am) FROM va_xxx.Versionen WHERE Erstellt_Am > t.Erfasst_am ORDER BY Erstellt_Am ASC LIMIT 1), bib.Jahr) AS Publikationsjahr,
		NULL AS Erhebungsjahr,
		i.Sprache AS Sprache_Informant,
		IF(d.Name = "no_dialect", NULL, d.Name) as Dialekt_Informant,
		NULL AS Art_Typ,
		NULL AS Id_Typ,
		NULL AS Typ,
		NULL AS Sprache_Typ,
		NULL,
		NULL AS Quelle_Typisierung,
		NULL AS Typ_LIDs,
		NULL as Wortart,
		NULL as Affix,
		NULL as Genus,
		NULL,
		NULL as Basistyp,
		NULL as Sprache_Basistyp,
		NULL AS Base_Type_Unsure,
		NULL as Referenz_Basistyp,
		NULL,
		NULL as Etymon,
		NULL AS Sprache_Etymon,
		NULL AS Bemerkungen,
		IFNULL(a.Nummer, -1) AS Cluster_Id,
		CONCAT('S', t.Id_Token) AS External_Id
	FROM 
		V_Tokens t
		LEFT JOIN VTBL_Token_morph_Typ m USING (Id_Token)
		LEFT JOIN VTBL_Token_phon_Typ p USING (Id_Token)
		LEFT JOIN Informanten i USING (Id_Informant)
		LEFT JOIN Orte o ON o.Id_Ort = i.Id_Gemeinde
		LEFT JOIN Bibliographie bib ON i.Erhebung = bib.Abkuerzung
		LEFT JOIN VTBL_Token_Konzept v3 USING (Id_Token)
		LEFT JOIN Konzepte k USING (Id_Konzept)
		LEFT JOIN Stimuli s USING (Id_Stimulus)
		LEFT JOIN Orte_Uebersetzungen ou USING (Id_Ort)
		LEFT JOIN A_Punkt_Index a ON i.Georeferenz = a.Geodaten
		LEFT JOIN dialects d ON Id_Dialekt = Id_Dialect
	WHERE
		m.Id_morph_Typ IS NULL AND p.Id_phon_Typ IS NULL
		AND (Grammatikalisch IS NULL OR Grammatikalisch = 0) AND
		i.Georeferenz IS NOT NULL AND i.Georeferenz != '' AND GeometryType(i.Georeferenz) = 'POINT' AND i.Id_Gemeinde IS NOT NULL
		
	UNION ALL

	-- morph. Type Groups
	SELECT
		(SELECT max(Id_Token) from tokens) + t.Id_Tokengruppe AS Id_Beleg,
		IF(t.IPA = '' OR t.IPA IS NULL OR t.IPA LIKE '%XXX%', IF(t.Original = '' OR t.Original IS NULL OR t.Original LIKE '%XXX%', t.Tokengruppe, t.Original), t.IPA) as Beleg,
		IF(t.IPA = '' OR t.IPA IS NULL OR t.IPA LIKE '%XXX%', IF(t.Original = '' OR t.Original LIKE '%XXX%', 4, 3), IF(VA_IPA, 2, 1)) AS Beleg_Codierung,
		IF(t.Original LIKE '%XXX%', '', t.Original) AS Beleg_Original,
		IF(t.Numerus IS NULL, '', t.Numerus) as Numerus,
		i.Id_Informant,
		CONCAT(s.Erhebung, '#', s.Karte, '#', s.Nummer, '#', IF(LOCATE('@', i.nummer) = 0, i.nummer, SUBSTR(i.nummer, 1, LOCATE('@', i.nummer) - 1)), '#', i.Ortsname) as Quelle_Beleg,
		s.Id_Stimulus as Id_Stimulus,
		ko.Id_Konzept,
		ko.QID,
		AsText(i.Georeferenz) as Geodaten,
		i.Alpenkonvention as Alpenkonvention,
		i.Id_Gemeinde,
		CONCAT(o.Name, getGeoTranslationString(o.Id_Ort)) AS Gemeinde,
		AsText(o.Mittelpunkt) AS Mittelpunkt_Gemeinde,
		IF(o.Geonames = 0, NULL, o.Geonames),
		IF(s.Erhebung = 'CROWD', (SELECT YEAR(Erstellt_Am) FROM va_xxx.Versionen WHERE Erstellt_Am > t.Erfasst_am ORDER BY Erstellt_Am ASC LIMIT 1), bib.Jahr) AS Publikationsjahr,
		NULL AS Erhebungsjahr,
		i.Sprache AS Sprache_Informant,
		IF(d.Name = "no_dialect", NULL, d.Name) as Dialekt_Informant,
		IF(Id_morph_Typ != 4144 AND Id_morph_Typ IS NOT NULL, 'L', NULL) AS Art_Typ,
		IF(Id_morph_Typ = 4144, NULL, Id_morph_Typ) AS Id_Typ,
		IF(Id_morph_Typ = 4144, NULL, k.Orth) AS Typ,
		k.Sprache AS Sprache_Typ,
		r.Referenz,
		k.Quelle AS Quelle_Typisierung,
		(SELECT GROUP_CONCAT(DISTINCT LID ORDER BY Sortier_Rang DESC) FROM lids JOIN Sprachen ON Sprache = Abkuerzung  WHERE lids.Id_morph_Typ = k.Id_morph_Typ) AS Typ_LIDs,
		IF(k.Wortart IS NULL, '', k.Wortart) Wortart,
		IF(k.Affix IS NULL, '', k.Affix) Affix,
		IF(k.Genus IS NULL, '', k.Genus) as Genus,
		b.Id_Basistyp,
		b.Orth as Basistyp,
		b.Sprache as Sprache_Basistyp,
		b.Unsicher AS Base_Type_Unsure,
		br.Referenz as Referenz_Basistyp,
		e.Id_Etymon,
		e.Orth as Etymon,
		e.Sprache AS Sprache_Etymon,
		NULL AS Bemerkungen,
		IFNULL(a.Nummer, -1) AS Cluster_Id,
		CONCAT('G', t.Id_Tokengruppe) AS External_Id
	FROM 
		V_Tokengruppen t
		JOIN VTBL_Tokengruppe_morph_Typ v0 USING (Id_Tokengruppe)
		LEFT JOIN morph_Typen k USING (Id_morph_Typ)
		LEFT JOIN A_Basistypen_Zuordnung b USING (Id_morph_Typ)
		LEFT JOIN VTBL_Basistyp_Etymon v2 USING (Id_Basistyp)
		LEFT JOIN Etyma e USING (Id_Etymon)
		LEFT JOIN Informanten i USING (Id_Informant)
		LEFT JOIN Orte o ON o.Id_Ort = i.Id_Gemeinde
		LEFT JOIN Bibliographie bib ON i.Erhebung = bib.Abkuerzung
		LEFT JOIN VTBL_Tokengruppe_Konzept v3 USING (Id_Tokengruppe)
		LEFT JOIN Konzepte ko USING (Id_Konzept)
		LEFT JOIN Stimuli s USING (Id_Stimulus)
		LEFT JOIN A_Referenzen r USING (Id_morph_Typ)
		LEFT JOIN A_Basistyp_Referenzen br USING (Id_Basistyp)
		LEFT JOIN A_Punkt_Index a ON i.Georeferenz = a.Geodaten
		LEFT JOIN dialects d ON Id_Dialekt = Id_Dialect
	WHERE
		(Grammatikalisch IS NULL OR Grammatikalisch = 0) AND
		i.Georeferenz IS NOT NULL AND i.Georeferenz != '' AND GeometryType(i.Georeferenz) = 'POINT' AND i.Id_Gemeinde IS NOT NULL
	
	UNION ALL
	
	-- Phon. Types Groups
	SELECT
		(SELECT max(Id_Token) from tokens) + t.Id_Tokengruppe AS Id_Beleg,
		IF(t.IPA = '' OR t.IPA IS NULL OR t.IPA LIKE '%XXX%', IF(t.Original = '' OR t.Original IS NULL OR t.Original LIKE '%XXX%', t.Tokengruppe, t.Original), t.IPA) as Beleg,
		IF(t.IPA = '' OR t.IPA IS NULL OR t.IPA LIKE '%XXX%', IF(t.Original = '' OR t.Original LIKE '%XXX%', 4, 3), IF(VA_IPA, 2, 1)) AS Beleg_Codierung,
		IF(t.Original LIKE '%XXX%', '', t.Original) AS Beleg_Original,
		IF(t.Numerus IS NULL, '', t.Numerus) as Numerus,
		i.Id_Informant,
		CONCAT(s.Erhebung, '#', s.Karte, '#', s.Nummer, '#', IF(LOCATE('@', i.nummer) = 0, i.nummer, SUBSTR(i.nummer, 1, LOCATE('@', i.nummer) - 1)), '#', i.Ortsname) as Quelle_Beleg,
		s.Id_Stimulus as Id_Stimulus,
		ko.Id_Konzept,
		ko.QID,
		AsText(i.Georeferenz) as Geodaten,
		i.Alpenkonvention as Alpenkonvention,
		i.Id_Gemeinde,
		CONCAT(o.Name, getGeoTranslationString(o.Id_Ort)) AS Gemeinde,
		AsText(o.Mittelpunkt) AS Mittelpunkt_Gemeinde,
		IF(o.Geonames = 0, NULL, o.Geonames),
		IF(s.Erhebung = 'CROWD', (SELECT YEAR(Erstellt_Am) FROM va_xxx.Versionen WHERE Erstellt_Am > t.Erfasst_am ORDER BY Erstellt_Am ASC LIMIT 1), bib.Jahr) AS Publikationsjahr,
		NULL AS Erhebungsjahr,
		i.Sprache AS Sprache_Informant,
		IF(d.Name = "no_dialect", NULL, d.Name) as Dialekt_Informant,
		'P' AS Art_Typ,
		p.Id_phon_Typ AS Id_Typ,
		IF(p.IPA IS NULL OR p.IPA = '', IF(p.Original IS NULL OR p.Original = '', p.Beta, p.Original), p.IPA) AS Typ,
		'' AS Sprache_Typ,
		NULL AS Referenz,
		p.Quelle AS Quelle_Typisierung,
		NULL AS Typ_LIDs,
		'' as Wortart,
		'' as Affix,
		'' as Genus,
		NULL AS Id_Basistyp,
		NULL AS Basistyp,
		NULL as Sprache_Basistyp,
		NULL AS Base_Type_Unsure,
		NULL as Referenz_Basistyp,
		NULL AS Id_Etymon,
		NULL AS Etymon,
		NULL AS Sprache_Etymon,
		NULL AS Bemerkungen,
		IFNULL(a.Nummer, -1) AS Cluster_Id,
		CONCAT('G', t.Id_Tokengruppe) AS External_Id
	FROM 
		V_Tokengruppen t
		JOIN VTBL_Tokengruppe_phon_Typ vt USING (Id_Tokengruppe)
		LEFT JOIN phon_Typen p USING (Id_phon_Typ)
		LEFT JOIN Informanten i USING (Id_Informant)
		LEFT JOIN Orte o ON o.Id_Ort = i.Id_Gemeinde
		LEFT JOIN Bibliographie bib ON i.Erhebung = bib.Abkuerzung
		LEFT JOIN VTBL_Tokengruppe_Konzept v3 USING (Id_Tokengruppe)
		LEFT JOIN Konzepte ko USING (Id_Konzept)
		LEFT JOIN Stimuli s USING (Id_Stimulus)
		LEFT JOIN A_Punkt_Index a ON i.Georeferenz = a.Geodaten
		LEFT JOIN dialects d ON Id_Dialekt = Id_Dialect
	WHERE
		(Grammatikalisch IS NULL OR Grammatikalisch = 0) AND
		i.Georeferenz IS NOT NULL AND i.Georeferenz != '' AND GeometryType(i.Georeferenz) = 'POINT' AND i.Id_Gemeinde IS NOT NULL
		
	UNION ALL
	
	-- Groups without types
	SELECT
		(SELECT max(Id_Token) from tokens) + t.Id_Tokengruppe AS Id_Beleg,
		IF(t.IPA = '' OR t.IPA IS NULL OR t.IPA LIKE '%XXX%', IF(t.Original = '' OR t.Original IS NULL OR t.Original LIKE '%XXX%', t.Tokengruppe, t.Original), t.IPA) as Beleg,
		IF(t.IPA = '' OR t.IPA IS NULL OR t.IPA LIKE '%XXX%', IF(t.Original = '' OR t.Original LIKE '%XXX%', 4, 3), IF(VA_IPA, 2, 1)) AS Beleg_Codierung,
		IF(t.Original LIKE '%XXX%', '', t.Original) AS Beleg_Original,
		IF(t.Numerus IS NULL, '', t.Numerus) as Numerus,
		i.Id_Informant,
		CONCAT(s.Erhebung, '#', s.Karte, '#', s.Nummer, '#', IF(LOCATE('@', i.nummer) = 0, i.nummer, SUBSTR(i.nummer, 1, LOCATE('@', i.nummer) - 1)), '#', i.Ortsname) as Quelle_Beleg,
		s.Id_Stimulus as Id_Stimulus,
		ko.Id_Konzept,
		ko.QID,
		AsText(i.Georeferenz) as Geodaten,
		i.Alpenkonvention as Alpenkonvention,
		i.Id_Gemeinde,
		CONCAT(o.Name, getGeoTranslationString(o.Id_Ort)) AS Gemeinde,
		AsText(o.Mittelpunkt) AS Mittelpunkt_Gemeinde,
		IF(o.Geonames = 0, NULL, o.Geonames),
		IF(s.Erhebung = 'CROWD', (SELECT YEAR(Erstellt_Am) FROM va_xxx.Versionen WHERE Erstellt_Am > t.Erfasst_am ORDER BY Erstellt_Am ASC LIMIT 1), bib.Jahr) AS Publikationsjahr,
		NULL AS Erhebungsjahr,
		i.Sprache AS Sprache_Informant,
		IF(d.Name = "no_dialect", NULL, d.Name) as Dialekt_Informant,
		NULL AS Art_Typ,
		NULL AS Id_Typ,
		NULL AS Typ,
		NULL AS Sprache_Typ,
		NULL,
		NULL AS Quelle_Typisierung,
		NULL AS Typ_LIDs,
		NULL AS Wortart,
		NULL AS Affix,
		NULL as Genus,
		NULL,
		NULL as Basistyp,
		NULL as Sprache_Basistyp,
		NULL AS Base_Type_Unsure,
		NULL as Referenz_Basistyp,
		NULL,
		NULL as Etymon,
		NULL AS Sprache_Etymon,
		NULL AS Bemerkungen,
		IFNULL(a.Nummer, -1) AS Cluster_Id,
		CONCAT('G', t.Id_Tokengruppe) AS External_Id
	FROM 
		V_Tokengruppen t
		LEFT JOIN VTBL_Tokengruppe_morph_Typ m USING (Id_Tokengruppe)
		LEFT JOIN VTBL_Tokengruppe_phon_Typ p USING (Id_Tokengruppe)
		LEFT JOIN Informanten i USING (Id_Informant)
		LEFT JOIN Orte o ON o.Id_Ort = i.Id_Gemeinde
		LEFT JOIN Bibliographie bib ON i.Erhebung = bib.Abkuerzung
		LEFT JOIN VTBL_Tokengruppe_Konzept v3 USING (Id_Tokengruppe)
		LEFT JOIN Konzepte ko USING (Id_Konzept)
		LEFT JOIN Stimuli s USING (Id_Stimulus)
		LEFT JOIN A_Punkt_Index a ON i.Georeferenz = a.Geodaten
		LEFT JOIN dialects d ON Id_Dialekt = Id_Dialect
	WHERE
		m.Id_morph_Typ IS NULL AND p.Id_phon_Typ IS NULL
		AND (Grammatikalisch IS NULL OR Grammatikalisch = 0) AND
		i.Georeferenz IS NOT NULL AND i.Georeferenz != '' AND GeometryType(i.Georeferenz) = 'POINT' AND i.Id_Gemeinde IS NOT NULL;
		
	START TRANSACTION;
	RENAME TABLE z_ling TO z_ling_old;
	RENAME TABLE z_ling_temp TO z_ling;
	COMMIT;
	
	DROP TABLE z_ling_old;
		
	END$$

DELIMITER ;