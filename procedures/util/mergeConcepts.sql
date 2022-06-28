DELIMITER $$

DROP PROCEDURE IF EXISTS mergeConcepts$$

CREATE PROCEDURE mergeConcepts (id_old INT UNSIGNED, id_new INT UNSIGNED)
BEGIN
	START TRANSACTION;
	
	DELETE FROM A_Konzept_Tiefen WHERE Id_Konzept = id_old;
	
	-- Tokens
	INSERT IGNORE INTO VTBL_Token_Konzept (Id_Token, Id_Konzept, Unsicher) 
		SELECT Id_Token, id_new, Unsicher FROM VTBL_Token_Konzept WHERE Id_Konzept = id_old;
	DELETE FROM VTBL_Token_Konzept WHERE Id_Konzept = id_old;
	
	-- Tokengruppen
	INSERT IGNORE INTO VTBL_Tokengruppe_Konzept (Id_Tokengruppe, Id_Konzept, Unsicher) 
		SELECT Id_Tokengruppe, id_new, Unsicher FROM VTBL_Tokengruppe_Konzept WHERE Id_Konzept = id_old;
	DELETE FROM VTBL_Tokengruppe_Konzept WHERE Id_Konzept = id_old;
	
	-- Aeusserungen
	INSERT IGNORE INTO VTBL_Aeusserung_Konzept (Id_Aeusserung, Id_Konzept, Unsicher) 
		SELECT Id_Aeusserung, id_new, Unsicher FROM VTBL_Aeusserung_Konzept WHERE Id_Konzept = id_old;
	DELETE FROM VTBL_Aeusserung_Konzept WHERE Id_Konzept = id_old;
	
	-- Medien
	INSERT IGNORE INTO VTBL_Medium_Konzept (Id_Medium, Id_Konzept, Konzeptillustration) 
		SELECT Id_Medium, id_new, Konzeptillustration FROM VTBL_Medium_Konzept WHERE Id_Konzept = id_old;
	DELETE FROM VTBL_Medium_Konzept WHERE Id_Konzept = id_old;

	-- Ueberkonzepte
	DELETE FROM Ueberkonzepte WHERE Id_Konzept = id_old;
	UPDATE Ueberkonzepte SET Id_Ueberkonzept = 707 WHERE Id_Ueberkonzept = id_old;
	CALL buildSubConceptsExtended();
	CALL buildConceptCount();
	
	-- Bedeutungen
	UPDATE Bedeutungen SET Id_Konzept = id_new WHERE Id_Konzept = id_old;
	
	-- Extern
	UPDATE PVA_DRG.VTBL_Lemma_Konzept SET Id_Konzept = id_new WHERE Id_Konzept = id_old;
	
	
	INSERT INTO id_chronik (Id_Entfernt, Id_Behalten) VALUES(CONCAT('C', id_old), CONCAT('C', id_new));

	DELETE FROM Konzepte WHERE Id_Konzept = id_old;
	COMMIT;
END$$

DELIMITER ;