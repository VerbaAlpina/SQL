DELIMITER $$

DROP TRIGGER IF EXISTS local_url_bib_insert$$
DROP TRIGGER IF EXISTS local_url_bib_update$$
DROP TRIGGER IF EXISTS local_url_personen_insert$$
DROP TRIGGER IF EXISTS local_url_personen_update$$
DROP TRIGGER IF EXISTS local_url_kp_insert$$
DROP TRIGGER IF EXISTS local_url_kp_update$$
DROP TRIGGER IF EXISTS local_url_vortraege_insert$$
DROP TRIGGER IF EXISTS local_url_vortraege_update$$


CREATE TRIGGER local_url_bib_insert BEFORE INSERT ON Bibliographie
	FOR EACH ROW
	BEGIN
		IF NEW.Download_URL LIKE 'https://www.verba-alpina.gwi.uni-muenchen.de/%' THEN
			SET NEW.Download_URL = CONCAT('va/', SUBSTRING(NEW.Download_URL, 46));
		END IF;
		IF NEW.Download_URL LIKE 'https://doi.org/10.5282/verba-alpina%' THEN
			set @message = "Bitte keine DOI-Links auf VerbaAlpina selbst verwenden!";
			signal sqlstate '45000' set MESSAGE_TEXT = @message;
		END IF;
	END;
$$

CREATE TRIGGER local_url_bib_update BEFORE UPDATE ON Bibliographie
	FOR EACH ROW
	BEGIN
		IF NEW.Download_URL LIKE 'https://www.verba-alpina.gwi.uni-muenchen.de/%' THEN
			SET NEW.Download_URL = CONCAT('va/', SUBSTRING(NEW.Download_URL, 46));
		END IF;
		IF NEW.Download_URL LIKE 'https://doi.org/10.5282/verba-alpina%' THEN
			set @message = "Bitte keine DOI-Links auf VerbaAlpina selbst verwenden!";
			signal sqlstate '45000' set MESSAGE_TEXT = @message;
		END IF;
	END;
$$

CREATE TRIGGER local_url_personen_insert BEFORE INSERT ON Personen
	FOR EACH ROW
	BEGIN
		IF NEW.Link LIKE 'https://www.verba-alpina.gwi.uni-muenchen.de/%' THEN
			SET NEW.Link = CONCAT('va/', SUBSTRING(NEW.Link, 46));
		END IF;
		IF NEW.Link LIKE 'https://doi.org/10.5282/verba-alpina%' THEN
			set @message = "Bitte keine DOI-Links auf VerbaAlpina selbst verwenden!";
			signal sqlstate '45000' set MESSAGE_TEXT = @message;
		END IF;
	END;
$$

CREATE TRIGGER local_url_personen_update BEFORE UPDATE ON Personen
	FOR EACH ROW
	BEGIN
		IF NEW.Link LIKE 'https://www.verba-alpina.gwi.uni-muenchen.de/%' THEN
			SET NEW.Link = CONCAT('va/', SUBSTRING(NEW.Link, 46));
		END IF;
		IF NEW.Link LIKE 'https://doi.org/10.5282/verba-alpina%' THEN
			set @message = "Bitte keine DOI-Links auf VerbaAlpina selbst verwenden!";
			signal sqlstate '45000' set MESSAGE_TEXT = @message;
		END IF;
	END;
$$

CREATE TRIGGER local_url_kp_insert BEFORE INSERT ON Kooperationspartner
	FOR EACH ROW
	BEGIN
		IF NEW.Link LIKE 'https://www.verba-alpina.gwi.uni-muenchen.de/%' THEN
			SET NEW.Link = CONCAT('va/', SUBSTRING(NEW.Link, 46));
		END IF;
		IF NEW.Link LIKE 'https://doi.org/10.5282/verba-alpina%' THEN
			set @message = "Bitte keine DOI-Links auf VerbaAlpina selbst verwenden!";
			signal sqlstate '45000' set MESSAGE_TEXT = @message;
		END IF;
	END;
$$

CREATE TRIGGER local_url_kp_update BEFORE UPDATE ON Kooperationspartner
	FOR EACH ROW
	BEGIN
		IF NEW.Link LIKE 'https://www.verba-alpina.gwi.uni-muenchen.de/%' THEN
			SET NEW.Link = CONCAT('va/', SUBSTRING(NEW.Link, 46));
		END IF;
		IF NEW.Link LIKE 'https://doi.org/10.5282/verba-alpina%' THEN
			set @message = "Bitte keine DOI-Links auf VerbaAlpina selbst verwenden!";
			signal sqlstate '45000' set MESSAGE_TEXT = @message;
		END IF;
	END;
$$

CREATE TRIGGER local_url_vortraege_insert BEFORE INSERT ON Vortraege
	FOR EACH ROW
	BEGIN
		IF NEW.URL1 LIKE 'https://www.verba-alpina.gwi.uni-muenchen.de/%' THEN
			SET NEW.URL1 = CONCAT('va/', SUBSTRING(NEW.URL1, 46));
		END IF;
		IF NEW.URL2 LIKE 'https://www.verba-alpina.gwi.uni-muenchen.de/%' THEN
			SET NEW.URL2 = CONCAT('va/', SUBSTRING(NEW.URL2, 46));
		END IF;
		IF NEW.URL3 LIKE 'https://www.verba-alpina.gwi.uni-muenchen.de/%' THEN
			SET NEW.URL3 = CONCAT('va/', SUBSTRING(NEW.URL3, 46));
		END IF;
		
		IF NEW.URL1 LIKE 'https://doi.org/10.5282/verba-alpina%' OR NEW.URL2 LIKE 'https://doi.org/10.5282/verba-alpina%' OR NEW.URL3 LIKE 'https://doi.org/10.5282/verba-alpina%' THEN
			set @message = "Bitte keine DOI-Links auf VerbaAlpina selbst verwenden!";
			signal sqlstate '45000' set MESSAGE_TEXT = @message;
		END IF;
	END;
$$

CREATE TRIGGER local_url_vortraege_update BEFORE UPDATE ON Vortraege
	FOR EACH ROW
	BEGIN
		IF NEW.URL1 LIKE 'https://www.verba-alpina.gwi.uni-muenchen.de/%' THEN
			SET NEW.URL1 = CONCAT('va/', SUBSTRING(NEW.URL1, 46));
		END IF;
		IF NEW.URL2 LIKE 'https://www.verba-alpina.gwi.uni-muenchen.de/%' THEN
			SET NEW.URL2 = CONCAT('va/', SUBSTRING(NEW.URL2, 46));
		END IF;
		IF NEW.URL3 LIKE 'https://www.verba-alpina.gwi.uni-muenchen.de/%' THEN
			SET NEW.URL3 = CONCAT('va/', SUBSTRING(NEW.URL3, 46));
		END IF;
		
		IF NEW.URL1 LIKE 'https://doi.org/10.5282/verba-alpina%' OR NEW.URL2 LIKE 'https://doi.org/10.5282/verba-alpina%' OR NEW.URL3 LIKE 'https://doi.org/10.5282/verba-alpina%' THEN
			set @message = "Bitte keine DOI-Links auf VerbaAlpina selbst verwenden!";
			signal sqlstate '45000' set MESSAGE_TEXT = @message;
		END IF;
	END;
$$

DELIMITER ;