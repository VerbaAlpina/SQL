DELIMITER $$

DROP PROCEDURE IF EXISTS zgeo$$

CREATE PROCEDURE zgeo ()
BEGIN
   DROP TEMPORARY TABLE IF EXISTS cat_names;

   CREATE TEMPORARY TABLE cat_names AS
		SELECT Id_Kategorie, GetLegendName(Id_Kategorie) AS Kategorie_Name, SUM(IF(GeometryType(Geodaten) != 'POLYGON' AND GeometryType(Geodaten) != 'MULTIPOLYGON', 1, 0)) AS No_Polygons
		FROM Orte_Kategorien JOIN Orte USING (Id_Kategorie)
		GROUP BY Id_Kategorie;

	DROP TABLE IF EXISTS z_geo_temp;
	
	CREATE TABLE `z_geo_temp` (
	  `Id_Geo` int(10) unsigned NOT NULL,
	  `Id_Category` int(10) unsigned NOT NULL,
	  `Category_Level_1` varchar(100) NOT NULL,
	  `Category_Level_2` varchar(100) NOT NULL,
	  `Category_Level_3` varchar(100) NOT NULL,
	  `Category_Level_4` varchar(100) NOT NULL,
	  `Category_Level_5` varchar(100) NOT NULL,
	  `Category_Name` varchar(200) NOT NULL,
	  `Name` varchar(100) NOT NULL,
	  `Description` text NOT NULL,
	  `Geo_Data` geometry NOT NULL,
	  `Geonames_Id` int(10) unsigned,
	  `Center` point DEFAULT NULL,
	  `Epsilon` float(5,4) NOT NULL,
	  `Author` varchar(100) NOT NULL,
	  `Import_Date` timestamp NULL DEFAULT NULL,
	  `Alpine_Convention` tinyint(1) NOT NULL,
	  `Remark` varchar(500) DEFAULT NULL,
	  `Tags` varchar(500) DEFAULT NULL,
	  `Cluster_Id` int(10) NOT NULL DEFAULT '0',
	  `ContainsTranslations` tinyint(1) NOT NULL DEFAULT '0',
	  `Map_Category` enum('None','A','E') NOT NULL DEFAULT 'None',
	  KEY `Id_Category` (`Id_Category`),
	  KEY `Cluster_Id` (`Cluster_Id`),
	  KEY `ideps` (`Id_Geo`,`Epsilon`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;
		
   INSERT INTO z_geo_temp
      (  SELECT Id_Ort,
                Id_Kategorie,
                Ebene_1,
                Ebene_2,
                Ebene_3,
                Ebene_4,
                Ebene_5,
                Kategorie_Name,
                CONCAT(Name, getGeoTranslationString(Id_Ort)) AS Name,
                Beschreibung,
                p.Geodaten,
				Geonames,
				p.Mittelpunkt,
				p.Epsilon,
                Autor,
                Importiert_Am,
                Alpenkonvention,
                '',
                IFNULL(CONCAT("{",
                       GROUP_CONCAT(CONCAT('"',
                                           Tag,
                                           '":"',
                                           Wert,
                                           '"')),
                       "}"), '{}')
                   AS Tags,
				IFNULL(a.Nummer, -1) AS Cluster_Id,
				Name COLLATE utf8_bin LIKE '%Ue[%]%' OR Beschreibung COLLATE utf8_bin LIKE '%Ue[%]%' OR getGeoTranslationString(Id_Ort) != '' AS ContainsTranslations,
				IF (Anzeige, IF(No_Polygons = 0, 'A', 'E'), 'None') AS Map_Category
           FROM Orte_Kategorien
                JOIN Orte o USING (Id_Kategorie)
                JOIN cat_names USING (Id_Kategorie)
				LEFT JOIN A_Punkt_Index a USING (Geodaten)
                LEFT JOIN Orte_Tags USING (Id_Ort)
				LEFT JOIN (SELECT Id_Ort, Geodaten, Mittelpunkt, Epsilon FROM Polygone_Vereinfacht UNION ALL SELECT Id_Ort, Geodaten, Mittelpunkt, 0 FROM Orte) p USING (Id_Ort)
       GROUP BY Id_Ort, Epsilon);

   DROP TEMPORARY TABLE cat_names;
   
   	START TRANSACTION;
	RENAME TABLE z_geo TO z_geo_old;
	RENAME TABLE z_geo_temp TO z_geo;
	COMMIT;
	
	DROP TABLE z_geo_old;
END$$

DELIMITER ;