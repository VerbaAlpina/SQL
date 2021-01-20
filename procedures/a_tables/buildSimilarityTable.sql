DELIMITER $$

DROP PROCEDURE IF EXISTS buildSimilarityTable$$

CREATE PROCEDURE buildSimilarityTable ()
BEGIN
	DECLARE i INT DEFAULT 0;

	DELETE FROM a_orte_aehnlichkeiten;
	
	DROP TEMPORARY TABLE IF EXISTS pairs;
	DROP TEMPORARY TABLE IF EXISTS cpairs;
	DROP TEMPORARY TABLE IF EXISTS comms;
	
	-- Create distinct type-concept pairs
	CREATE TEMPORARY TABLE pairs (
		Id_Gemeinde INT unsigned, 
		Id_morph_Typ INT unsigned, 
		Id_Konzept INT unsigned,
		INDEX compl(Id_Gemeinde, Id_morph_Typ, Id_Konzept),
		INDEX mk(Id_morph_Typ, Id_Konzept),
		INDEX com(Id_Gemeinde) 
	) ENGINE=MEMORY;

	SET @min_pairs = 10;

	INSERT INTO pairs
		SELECT DISTINCT Id_Gemeinde, m.Id_morph_Typ, Id_Konzept
		FROM 
			Tokens t
			JOIN Informanten i USING (Id_Informant)
			JOIN VTBL_Token_morph_Typ vm USING (Id_Token)
			JOIN morph_Typen m ON m.Id_morph_Typ = vm.Id_morph_Typ AND Quelle = 'VA'
			JOIN VTBL_Token_Konzept USING (Id_Token)
		WHERE Id_Gemeinde IS NOT NULL;
		
	-- SELECT Id_Konzept, Id_morph_Typ FROM pairs WHERE Id_Gemeinde = 60211;
	-- SELECT Id_Konzept, Id_morph_Typ FROM pairs WHERE Id_Gemeinde = 61228;
			
	CREATE TEMPORARY TABLE comms (
		Id_Gemeinde INT unsigned, 
		INDEX gem (Id_Gemeinde)
	) ENGINE=MEMORY;
	
	INSERT INTO comms
		SELECT Id_Gemeinde 
		FROM pairs
		GROUP BY Id_Gemeinde
		HAVING count(*) >= @min_pairs;
		
	DELETE FROM pairs WHERE Id_Gemeinde NOT IN (SELECT Id_Gemeinde FROM comms);
					
	SELECT count(*) FROM comms INTO @num;		

	CREATE TEMPORARY TABLE cpairs (
			Id_morph_Typ INT unsigned,
			Id_Konzept INT unsigned,
			INDEX mk(Id_morph_Typ, Id_Konzept)
		) ENGINE=MEMORY;	
					
	SET i = 0;
	WHILE i < @num DO
		SELECT Id_Gemeinde FROM comms LIMIT i,1 INTO @ccomm;
		SELECT CONCAT('Community 1: ', @ccomm);

		INSERT INTO cpairs
			SELECT Id_morph_Typ, Id_Konzept FROM pairs WHERE Id_Gemeinde = @ccomm;
	
		INSERT INTO a_orte_aehnlichkeiten (Id_Ort_1, Id_Ort_2, Aehnlichkeit)
			SELECT @ccomm, Id_Gemeinde, CAST(SUM(IF(c.Id_morph_Typ = p.Id_morph_Typ, 1, 0)) AS DECIMAL) / count(DISTINCT p.Id_Konzept, p.Id_morph_Typ)
			FROM pairs p JOIN cpairs c ON p.Id_Konzept = c.Id_Konzept
			WHERE Id_Gemeinde != @ccomm
			GROUP BY Id_Gemeinde;
			
		
		DELETE FROM cpairs;
		
		SET i = i + 1;
	END WHILE;
	
	DROP TEMPORARY TABLE cpairs;
	DROP TEMPORARY TABLE pairs;
	
END$$

DELIMITER ;