DELIMITER $$

DROP PROCEDURE IF EXISTS buildConceptCount$$

CREATE PROCEDURE `buildConceptCount` ()
BEGIN
   CALL buildSubConceptsExtended();

   DELETE FROM A_Anzahl_Konzept_Belege;

   INSERT INTO A_Anzahl_Konzept_Belege(Id_Konzept,
                                       Id_Ueberkonzept,
                                       Anzahl_Allein,
									   Anzahl_Allein_AK,
                                       Anzahl_Komplett,
                                       Dateiname)
        SELECT k.Id_Konzept,
               ue.Id_Ueberkonzept,
                 (SELECT count(*)
                    FROM VTBL_Token_Konzept
                   WHERE Id_Konzept = k.Id_Konzept)
               + (SELECT count(*)
                    FROM VTBL_Tokengruppe_Konzept
                   WHERE Id_Konzept = k.Id_Konzept)
                  AS Anzahl_Allein,
				  (SELECT count(*)
                    FROM VTBL_Token_Konzept JOIN Tokens USING (Id_Token) JOIN Informanten USING (Id_Informant)
                   WHERE Id_Konzept = k.Id_Konzept AND Alpenkonvention)
               + (SELECT count(*)
                    FROM VTBL_Tokengruppe_Konzept JOIN V_Tokengruppen USING (Id_Tokengruppe) JOIN Informanten USING (Id_Informant)
                   WHERE Id_Konzept = k.Id_Konzept AND Alpenkonvention)
				   AS Anzahl_Allein_AK,
               count(*) AS Anzahl_Kompl,
               Dateiname
          FROM ((SELECT *
                   FROM a_ueberkonzepte_erweitert)
                UNION ALL
                (SELECT Id_Konzept, Id_Konzept AS Id_Ueberkonzept
                   FROM konzepte)) u
               JOIN Konzepte k ON u.Id_Ueberkonzept = k.Id_Konzept
               JOIN (SELECT * FROM vtbl_token_konzept
                     UNION ALL
                     SELECT * FROM vtbl_tokengruppe_konzept) v
                  ON u.Id_Konzept = v.Id_Konzept
               JOIN Ueberkonzepte ue ON k.Id_Konzept = ue.Id_Konzept
               LEFT JOIN VTBL_Medium_Konzept vmk
                  ON Konzeptillustration AND k.Id_Konzept = vmk.Id_Konzept
               LEFT JOIN Medien USING (Id_Medium)
      GROUP BY u.Id_Ueberkonzept
      HAVING COUNT(*) > 0;

END$$

DELIMITER ;