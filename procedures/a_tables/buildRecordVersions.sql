DELIMITER $$

DROP PROCEDURE IF EXISTS buildRecordVersions$$

CREATE PROCEDURE buildRecordVersions (vnum CHAR(3), debug BOOLEAN)
BEGIN
	DECLARE num INT UNSIGNED;
	DECLARE num_row INT UNSIGNED;
	DECLARE num_field INT UNSIGNED;
	DECLARE i INT UNSIGNED;
	
	DROP TEMPORARY TABLE IF EXISTS all_versions;
	IF vnum IS NULL THEN
		CREATE TEMPORARY TABLE all_versions AS SELECT DISTINCT Nummer FROM va_xxx.Versionen WHERE Website ORDER BY Nummer ASC;
	ELSE
		CREATE TEMPORARY TABLE all_versions AS SELECT vnum AS Nummer;
	END IF;
	
	SELECT count(*) FROM all_versions INTO @cv;
	
	SET i = 0;
	WHILE i < @cv DO
		SELECT CONCAT('va_', Nummer) AS Nummer FROM all_versions LIMIT i, 1 INTO @db;
		SELECT @db;
		
		DROP TEMPORARY TABLE IF EXISTS changes;
		CREATE TEMPORARY TABLE changes (Id VARCHAR(10) PRIMARY KEY, Changed BOOLEAN) ENGINE=Memory;
	
		IF @db = 'va_161' THEN
			DELETE FROM va_161.A_Versionen;
			INSERT INTO va_161.A_Versionen (Id, Changed, Version) SELECT DISTINCT External_Id, 1, 1 FROM va_161.z_ling;
			INSERT INTO va_161.A_Versionen (Id, Changed, Version) SELECT DISTINCT CONCAT("C", Id_Concept), 1, 1 FROM va_161.z_ling WHERE Id_Concept IS NOT NULL;
			INSERT INTO va_161.A_Versionen (Id, Changed, Version) SELECT DISTINCT CONCAT("A", Id_Community), 1, 1 FROM va_161.z_ling WHERE Id_Community IS NOT NULL;
			INSERT INTO va_161.A_Versionen (Id, Changed, Version) SELECT DISTINCT CONCAT("L", Id_Type), 1, 1 FROM va_161.z_ling WHERE Type_Kind = 'L' AND Source_Typing = 'VA' AND Id_Type IS NOT NULL;
		ELSE
			SELECT prev_version(@db) INTO @prev;

			DROP TEMPORARY TABLE IF EXISTS records_new;
			DROP TEMPORARY TABLE IF EXISTS records_old;
			DROP TEMPORARY TABLE IF EXISTS field_names;
			DROP TEMPORARY TABLE IF EXISTS all_ids;
			
			IF debug = 1 THEN
				DROP TEMPORARY TABLE IF EXISTS fields_changed;
				CREATE TEMPORARY TABLE fields_changed (fname VARCHAR(100) PRIMARY KEY, fnum INT unsigned) ENGINE=MEMORY;
			END IF;

			-- Use only fields contained in both versions to avoid problems if an older table is not yet up to date
			CREATE TEMPORARY TABLE field_names ENGINE=Memory
			SELECT DISTINCT column_name FROM
				(SELECT column_name from information_schema.columns WHERE table_schema = @prev and table_name = 'z_ling') o
				INNER JOIN
				(SELECT column_name from information_schema.columns WHERE table_schema = @db and table_name = 'z_ling') n
				USING (column_name)
			WHERE column_name NOT IN ('Id_Instance', 'Cluster_Id', 'External_Id');
				
			SELECT count(*) FROM field_names INTO @num_fields;
			
			SET @query = CONCAT('CREATE TEMPORARY TABLE all_ids ENGINE=Memory SELECT DISTINCT External_Id, Id_Instance FROM ', @db, '.z_ling');
			PREPARE stmt FROM @query;
			EXECUTE stmt;
			
			SET num = 0;
			SELECT count(*) FROM all_ids INTO @num_ids;
			
			WHILE num < @num_ids DO
				IF num > 0 AND MOD(num, 100) = 0 THEN
					SELECT CONCAT(num, "/", @num_ids) AS progress;
				END IF;
			
				SELECT External_Id, Id_Instance FROM all_ids LIMIT num, 1 INTO @ceid, @ciid;
	
				SET @different = 0;
				
				SET @query = CONCAT('CREATE TEMPORARY TABLE records_new ENGINE=MEMORY SELECT * FROM ', @db, '.z_ling WHERE Id_Instance = @ciid');
				PREPARE stmt FROM @query;
				EXECUTE stmt;
				SELECT count(*) from records_new INTO @num_rows;
				
				SET @query = CONCAT('CREATE TEMPORARY TABLE records_old ENGINE=MEMORY SELECT * FROM ', @prev, '.z_ling WHERE External_Id = "', @ceid, '"');
				PREPARE stmt FROM @query;
				EXECUTE stmt;
				SELECT count(*) from records_old INTO @num_rows_old;
				
				IF @num_rows != @num_rows_old THEN
					SET @different = 1;
					
					IF debug = 1 THEN
						INSERT INTO fields_changed VALUES ('NUMBER', 1) ON DUPLICATE KEY UPDATE fnum = fnum + 1;
					END IF;
				ELSE
					SET num_row = 0;

					record_loop: WHILE num_row < @num_rows DO
						SET num_field = 0;
						WHILE num_field < @num_fields DO
							SELECT column_name FROM field_names LIMIT num_field, 1 INTO @cfield;
							
							SET @query = CONCAT('SELECT ', @cfield, ' FROM records_old LIMIT ', num_row, ', 1 INTO @val_old');
							PREPARE stmt FROM @query;
							EXECUTE stmt;
							
							SET @query = CONCAT('SELECT ', @cfield, ' FROM records_new LIMIT ', num_row, ', 1 INTO @val_new');
							PREPARE stmt FROM @query;
							EXECUTE stmt;

							IF @val_old IS NULL AND @val_new IS NOT NULL THEN
								SET @different = 1;
								
								IF debug = 1 THEN
									INSERT INTO fields_changed VALUES (@cfield, 1) ON DUPLICATE KEY UPDATE fnum = fnum + 1;
								END IF;
								
								LEAVE record_loop;
							END IF;
							
							IF @val_new IS NULL AND @val_old IS NOT NULL THEN
								SET @different = 1;
								
								IF debug = 1 THEN
									INSERT INTO fields_changed VALUES (@cfield, 1) ON DUPLICATE KEY UPDATE fnum = fnum + 1;
								END IF;
								
								LEAVE record_loop;
							END IF;
							
							IF @val_new != @val_old THEN
								SET @different = 1;
								
								IF debug = 1 THEN
									INSERT INTO fields_changed VALUES (@cfield, 1) ON DUPLICATE KEY UPDATE fnum = fnum + 1;
								END IF;
								
								LEAVE record_loop;
							END IF;

							SET num_field = num_field + 1;
						END WHILE;
						
						SET num_row = num_row + 1;
					END WHILE record_loop;
				END IF;

				DROP TEMPORARY TABLE records_old;
				

				INSERT INTO changes VALUES (@ceid, @different);
				
				IF @different THEN
					SET @query = CONCAT('INSERT IGNORE INTO changes SELECT DISTINCT CONCAT("C", Id_Concept), 1 FROM records_new WHERE Id_Instance = @ciid');
					PREPARE stmt FROM @query;
					EXECUTE stmt;
					
					SET @query = CONCAT('INSERT IGNORE INTO changes SELECT DISTINCT CONCAT("A", Id_Community), 1 FROM records_new WHERE Id_Instance = @ciid');
					PREPARE stmt FROM @query;
					EXECUTE stmt;
					
					SET @query = CONCAT('INSERT IGNORE INTO changes SELECT DISTINCT CONCAT("L", Id_Type), 1 FROM records_new WHERE Id_Instance = @ciid AND Type_Kind = "L" AND Source_Typing = "VA"');
					PREPARE stmt FROM @query;
					EXECUTE stmt;
				END IF;
				
				DROP TEMPORARY TABLE records_new;
		
				SET num = num + 1;
			END WHILE;
			
			DROP TEMPORARY TABLE field_names;
			DROP TEMPORARY TABLE all_ids;
			
			SELECT 'Compute version numbers';
			
			DELETE FROM changes WHERE Id = ''; -- Inserted for null values for e.g. concepts
			
			SET @query = CONCAT('INSERT IGNORE INTO changes SELECT DISTINCT CONCAT("C", Id_Concept), 0 FROM ', @db, '.z_ling WHERE Id_Concept IS NOT NULL');
			PREPARE stmt FROM @query;
			EXECUTE stmt;
			
			SET @query = CONCAT('INSERT IGNORE INTO changes SELECT DISTINCT CONCAT("A", Id_Community), 0 FROM ', @db, '.z_ling WHERE Id_Community IS NOT NULL');
			PREPARE stmt FROM @query;
			EXECUTE stmt;
			
			SET @query = CONCAT('INSERT IGNORE INTO changes SELECT DISTINCT CONCAT("L", Id_Type), 0 FROM ', @db, '.z_ling WHERE Type_Kind = "L" AND Source_Typing = "VA" AND Id_Type IS NOT NULL');
			PREPARE stmt FROM @query;
			EXECUTE stmt;
			
			SET @query = CONCAT('DELETE FROM ', @db, '.A_Versionen');
			PREPARE stmt FROM @query;
			EXECUTE stmt;
			
			SET @query = CONCAT('INSERT INTO ', @db, '.A_Versionen SELECT Id, Changed, IFNULL((SELECT Version FROM ', @prev, '.A_Versionen v_old WHERE v_old.Id = changes.Id), 0) + IF(Changed, 1, 0) FROM changes');
			PREPARE stmt FROM @query;
			EXECUTE stmt;			
			
			DROP TEMPORARY TABLE changes;
			
			IF debug = 1 THEN
				SELECT * FROM fields_changed;
				DROP TEMPORARY TABLE fields_changed;
			END IF;
		END IF;
		
		SET i = i + 1;
	END WHILE;
		
	DROP TEMPORARY TABLE all_versions;
	
END$$

DELIMITER ;