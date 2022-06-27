DELIMITER $$

DROP PROCEDURE IF EXISTS mergeBaseTypes$$

CREATE PROCEDURE mergeBaseTypes (id_old INT UNSIGNED, id_new INT UNSIGNED)
BEGIN
	DECLARE i INT UNSIGNED;

	START TRANSACTION;
	
	DELETE FROM A_Basistypen_Zuordnung WHERE Id_Basistyp = id_old;
	DELETE FROM A_Basistyp_Referenzen WHERE Id_Basistyp = id_old;
	
	-- Basistypen
	INSERT IGNORE INTO VTBL_morph_Basistyp (Id_morph_Typ, Id_Basistyp, Quelle, Angelegt_Von, Angelegt_Am, Unsicher) 
		SELECT Id_morph_Typ, id_new, Quelle, Angelegt_Von, Angelegt_Am, Unsicher FROM VTBL_morph_Basistyp WHERE Id_Basistyp = id_old;
	DELETE FROM VTBL_morph_Basistyp WHERE Id_Basistyp = id_old;

	-- Lemmata
	INSERT IGNORE INTO VTBL_Basistyp_Lemma (Id_Basistyp, Id_Lemma, Angelegt_Von, Angelegt_Am) 
		SELECT id_new, Id_Lemma, Angelegt_Von, Angelegt_Am FROM VTBL_Basistyp_Lemma WHERE Id_Basistyp = id_old;
	DELETE FROM VTBL_Basistyp_Lemma WHERE Id_Basistyp = id_old;
		
	-- Etyma
	INSERT IGNORE INTO VTBL_Basistyp_Etymon (Id_Basistyp, Id_Etymon, Angelegt_Am) 
		SELECT id_new, Id_Etymon, Angelegt_Am FROM VTBL_Basistyp_Etymon WHERE Id_Basistyp = id_old;
	DELETE FROM VTBL_Basistyp_Etymon WHERE Id_Basistyp = id_old;
	
	INSERT INTO id_chronik (Id_Entfernt, Id_Behalten) VALUES(CONCAT('B', id_old), CONCAT('B', id_new));

	DELETE FROM Basistypen WHERE Id_Basistyp = id_old;
	COMMIT;
END$$

DELIMITER ;