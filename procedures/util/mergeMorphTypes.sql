DELIMITER $$

DROP PROCEDURE IF EXISTS mergeMorphTypes$$

CREATE PROCEDURE mergeMorphTypes (id_old INT UNSIGNED, id_new INT UNSIGNED)
BEGIN
	DECLARE i INT UNSIGNED;

	START TRANSACTION;
	
	DELETE FROM A_Basistypen_Zuordnung WHERE Id_morph_Typ = id_old;
	DELETE FROM A_Referenzen WHERE Id_morph_Typ = id_old;
	
	-- Bilder
	INSERT IGNORE INTO VTBL_Medium_Typ (Id_morph_Typ, Id_Medium) 
		SELECT id_new, Id_Medium FROM VTBL_Medium_Typ WHERE Id_morph_Typ = id_old;
	DELETE FROM VTBL_Medium_Typ WHERE Id_morph_Typ = id_old;
	
	-- Basistypen
	INSERT IGNORE INTO VTBL_morph_Basistyp (Id_morph_Typ, Id_Basistyp, Quelle, Angelegt_Von, Angelegt_Am, Unsicher) 
		SELECT id_new, Id_Basistyp, Quelle, Angelegt_Von, Angelegt_Am, Unsicher FROM VTBL_morph_Basistyp WHERE Id_morph_Typ = id_old;
	DELETE FROM VTBL_morph_Basistyp WHERE Id_morph_Typ = id_old;
	
	-- Bestandteile
	DELETE FROM VTBL_morph_Typ_Bestandteile WHERE Id_morph_Typ = id_old;
	
	INSERT IGNORE INTO VTBL_morph_Typ_Bestandteile (Id_morph_Typ, Id_Bestandteil) 
		SELECT Id_morph_Typ, id_new FROM VTBL_morph_Typ_Bestandteile WHERE Id_Bestandteil = id_old;
	DELETE FROM VTBL_morph_Typ_Bestandteile WHERE Id_Bestandteil = id_old;
	
	-- Lemmata
	INSERT IGNORE INTO VTBL_morph_Typ_Lemma (Id_morph_Typ, Id_Lemma, Quelle, Angelegt_Von, Angelegt_Am) 
		SELECT id_new, Id_Lemma, Quelle, Angelegt_Von, Angelegt_Am FROM VTBL_morph_Typ_Lemma WHERE Id_morph_Typ = id_old;
	DELETE FROM VTBL_morph_Typ_Lemma WHERE Id_morph_Typ = id_old;
		
	-- Typisierungen Tokengruppen
	INSERT IGNORE INTO VTBL_Tokengruppe_morph_Typ (Id_morph_Typ, Id_Tokengruppe, Angelegt_Von, Angelegt_Am) 
		SELECT id_new, Id_Tokengruppe, Angelegt_Von, Angelegt_Am FROM VTBL_Tokengruppe_morph_Typ WHERE Id_morph_Typ = id_old;
	DELETE FROM VTBL_Tokengruppe_morph_Typ WHERE Id_morph_Typ = id_old;
	
	-- Typisierungen Tokens
	INSERT IGNORE INTO VTBL_Token_morph_Typ (Id_morph_Typ, Id_Token, Angelegt_Von, Angelegt_Am) 
		SELECT id_new, Id_Token, Angelegt_Von, Angelegt_Am FROM VTBL_Token_morph_Typ WHERE Id_morph_Typ = id_old;
	DELETE FROM VTBL_Token_morph_Typ WHERE Id_morph_Typ = id_old;
	
	INSERT INTO id_chronik (Id_Entfernt, Id_Behalten) VALUES(CONCAT('L', id_old), CONCAT('L', id_new));

	DELETE FROM morph_Typen WHERE Id_morph_Typ = id_old;
	COMMIT;
END$$

DELIMITER ;