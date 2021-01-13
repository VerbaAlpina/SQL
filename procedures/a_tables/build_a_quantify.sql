DELIMITER $$

DROP PROCEDURE IF EXISTS buildQuantifyTables$$

CREATE PROCEDURE buildQuantifyTables ()
BEGIN

	/* INFORMANTEN */
	DELETE FROM A_Informant_Polygon;
	
	/* Gemeinden */
	INSERT INTO A_Informant_Polygon
		SELECT Id_Informant, 62, IF(Id_Ort IS NULL, 0, Id_Ort) FROM Informanten i LEFT JOIN Orte o ON i.Id_Gemeinde = o.Id_Ort WHERE i.Georeferenz != '' AND i.Georeferenz IS NOT NULL;
	
	/* NUTS-3 */
	INSERT INTO A_Informant_Polygon
		SELECT Id_Informant, 60, IF(Id_Ort IS NULL, 0, Id_Ort) FROM Informanten i LEFT JOIN Orte o ON Id_Kategorie = 60 AND WITHIN(i.Georeferenz, o.Geodaten) AND ST_WITHIN(i.Georeferenz, o.Geodaten) WHERE i.Georeferenz != '' AND i.Georeferenz IS NOT NULL;
	
	/* Sprachgebiete */
	INSERT INTO A_Informant_Polygon
		SELECT Id_Informant, 17, IF(Id_Ort IS NULL, 0, Id_Ort) FROM Informanten i LEFT JOIN Orte o ON Id_Kategorie = 17 AND WITHIN(i.Georeferenz, o.Geodaten) AND ST_WITHIN(i.Georeferenz, o.Geodaten) WHERE i.Georeferenz != '' AND i.Georeferenz IS NOT NULL;
	
	/* Alpenkonvention */
	INSERT INTO A_Informant_Polygon
		SELECT Id_Informant, 1, IF(Id_Ort IS NULL, 0, Id_Ort) FROM Informanten i LEFT JOIN Orte o ON Id_Kategorie = 1 AND i.Alpenkonvention WHERE i.Georeferenz != '' AND i.Georeferenz IS NOT NULL;
		
	/* Nationalstaaten */
	INSERT INTO A_Informant_Polygon
		SELECT Id_Informant, 63, 
		CASE Wert 
			WHEN 'ita' THEN 181097
			WHEN 'fra' THEN 181098
			WHEN 'aut' THEN 181099
			WHEN 'che' THEN 181100
			WHEN 'deu' THEN 181101
			WHEN 'mon' THEN 181102
			WHEN 'lie' THEN 181103
			WHEN 'svn' THEN 181104
			WHEN 'bih' THEN 181105
			WHEN 'hrv' THEN 181106
			WHEN 'hun' THEN 181107
			WHEN 'cze' THEN 181108
			WHEN 'svk' THEN 181109
			ELSE 0
		END
		FROM Informanten i JOIN A_Informant_Polygon USING (Id_Informant) JOIN Orte_Tags ON Id_Ort = Id_Polygon WHERE Id_Kategorie = 62 AND Tag = 'LAND';
		
	/* ORTE */
	
	DROP TEMPORARY TABLE IF EXISTS Ort_Ids;
	CREATE TEMPORARY TABLE Ort_Ids (Id_Ort INT unsigned) ENGINE = MEMORY;
	
	INSERT INTO Ort_Ids 
		SELECT Id_Ort 
		FROM Orte 
		WHERE ST_GeometryType(Geodaten) = 'POINT' AND (Quant_Datum IS NULL OR Quant_Datum < Geaendert_Am)
		LIMIT 30000;
	
	DELETE A_Ort_Polygon FROM A_Ort_Polygon LEFT JOIN Orte USING (Id_Ort) WHERE Id_Ort IN (SELECT * FROM Ort_Ids) OR Orte.Id_Ort IS NULL;
	
	/* Gemeinden */
	INSERT INTO A_Ort_Polygon
		SELECT o1.Id_Ort, 62, IF(o2.Id_Ort IS NULL, 0, o2.Id_Ort) FROM Orte o1 LEFT JOIN Orte o2 ON WITHIN(o1.Geodaten, o2.Geodaten) AND ST_WITHIN(o1.Geodaten, o2.Geodaten) AND o2.Id_Kategorie = 62 WHERE o1.Id_Ort IN (SELECT * FROM Ort_Ids);
		
	/* NUTS-3 */
	INSERT INTO A_Ort_Polygon
		SELECT o1.Id_Ort, 60, IF(o2.Id_Ort IS NULL, 0, o2.Id_Ort) FROM Orte o1 LEFT JOIN Orte o2 ON WITHIN(o1.Geodaten, o2.Geodaten) AND ST_WITHIN(o1.Geodaten, o2.Geodaten) AND o2.Id_Kategorie = 60 WHERE o1.Id_Ort IN (SELECT * FROM Ort_Ids);
	
	/* Sprachgebiete */
	INSERT INTO A_Ort_Polygon
		SELECT o1.Id_Ort, 17, IF(o2.Id_Ort IS NULL, 0, o2.Id_Ort) FROM Orte o1 LEFT JOIN Orte o2 ON WITHIN(o1.Geodaten, o2.Geodaten) AND ST_WITHIN(o1.Geodaten, o2.Geodaten) AND o2.Id_Kategorie = 17 WHERE o1.Id_Ort IN (SELECT * FROM Ort_Ids);
		
	/* Alpenkonvention */
	INSERT INTO A_Ort_Polygon
		SELECT o1.Id_Ort, 1, IF(o2.Id_Ort IS NULL, 0, o2.Id_Ort) FROM Orte o1 LEFT JOIN Orte o2 ON o2.Id_Kategorie = 1 AND o1.Alpenkonvention WHERE o1.Id_Ort IN (SELECT * FROM Ort_Ids);
		
	/* Nationalstaaten */
	INSERT INTO A_Ort_Polygon
		SELECT o1.Id_Ort, 63, IF(o2.Id_Ort IS NULL, 0, o2.Id_Ort) FROM Orte o1 LEFT JOIN Orte o2 ON WITHIN(o1.Geodaten, o2.Geodaten) AND ST_WITHIN(o1.Geodaten, o2.Geodaten) AND o2.Id_Kategorie = 63 WHERE o1.Id_Ort IN (SELECT * FROM Ort_Ids);
		
	UPDATE Orte SET Quant_Datum = NOW() WHERE Id_Ort IN (SELECT * FROM Ort_Ids);
END$$

DELIMITER ;