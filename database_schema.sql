SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE SCHEMA IF NOT EXISTS `dance_with_me` DEFAULT CHARACTER SET utf8 ;
USE `dance_with_me` ;

-- -----------------------------------------------------
-- Table `dance_with_me`.`users`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `dance_with_me`.`users` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `password` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_bin',
  `email` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_bin' NULL DEFAULT NULL ,
  `first_name` VARCHAR(45) CHARACTER SET 'utf8' COLLATE 'utf8_bin',
  `last_name` VARCHAR(45) CHARACTER SET 'utf8' COLLATE 'utf8_bin',
  `birthday` DATE,
  `date` DATETIME,
  `confirm_code` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_bin' NULL DEFAULT NULL ,
  `confirmed` VARCHAR(45) CHARACTER SET 'utf8' COLLATE 'utf8_bin' NULL DEFAULT NULL ,
  `about` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_bin' NULL DEFAULT NULL ,
  `gender` TINYINT(1) NOT NULL DEFAULT '0' ,
  `fb_id` BIGINT NOT NULL,
  `full_name` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_bin',
  `locale` VARCHAR(32) CHARACTER SET 'utf8' COLLATE 'utf8_bin',
  `timezone` INT(11),
  `profile_link` VARCHAR(256) CHARACTER SET 'utf8' COLLATE 'utf8_bin',
  `created` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ,
  `last_login` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ,

  PRIMARY KEY (`id`) )
ENGINE = InnoDB
AUTO_INCREMENT = 1
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_bin
COMMENT = 'Store basic information about users';


CREATE  TABLE IF NOT EXISTS `dance_with_me`.`category` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `name` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_bin' NOT NULL ,
  `description` VARCHAR(512) CHARACTER SET 'utf8' COLLATE 'utf8_bin' NULL DEFAULT NULL ,
  `created` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ,
  `updated` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ,
  PRIMARY KEY (`id`) ,
  UNIQUE INDEX `id_UNIQUE` (`id` ASC) )
ENGINE = InnoDB
AUTO_INCREMENT = 1
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_bin
COMMENT = 'Categories of the positions';

CREATE  TABLE IF NOT EXISTS `dance_with_me`.`position` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `name` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_bin' NOT NULL ,
  `description` VARCHAR(512) CHARACTER SET 'utf8' COLLATE 'utf8_bin' NULL DEFAULT NULL ,
  `user_id` INT(11) NOT NULL ,
  `category_id` INT(11) NOT NULL ,
  `created` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ,
  `updated` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ,
  PRIMARY KEY (`id`) ,
  UNIQUE INDEX `id_UNIQUE` (`id` ASC) )
ENGINE = InnoDB
AUTO_INCREMENT = 1
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_bin
COMMENT = 'Positions';

-- -----------------------------------------------------
-- Table `dance_with_me`.`p_photo`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `dance_with_me`.`p_photo` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `user_id` INT(11) NOT NULL ,
  `photo` LONGBLOB NOT NULL ,
  `position_id` INT(11) NOT NULL,
  PRIMARY KEY (`id`) ,
  INDEX `id_idx` (`id` ASC) )
ENGINE = InnoDB
AUTO_INCREMENT = 1
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_bin
COMMENT = 'Positions photos' ;

-- -----------------------------------------------------
-- Table `dance_with_me`.`u_information_reg`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `dance_with_me`.`u_information_reg` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `headline` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_bin' NOT NULL ,
  `description` VARCHAR(512) CHARACTER SET 'utf8' COLLATE 'utf8_bin' NULL DEFAULT NULL ,
  `options` TINYINT(1) NULL DEFAULT NULL COMMENT 'Does there exist answers for this question?\nIn u_information_answers_reg' ,
  `order_by` INT(11) NOT NULL ,
  PRIMARY KEY (`id`) ,
  UNIQUE INDEX `id_UNIQUE` (`id` ASC) )
ENGINE = InnoDB
AUTO_INCREMENT = 4
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_bin
COMMENT = 'Categories of information (questions). Eg. What\'s your favou /* comment truncated */ /* /* comment truncated */ /* /* comment truncated */ /*rite color?*/*/*/';


-- -----------------------------------------------------
-- Table `dance_with_me`.`u_information`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `dance_with_me`.`u_information` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `user_id` INT(11) NOT NULL ,
  `information_id` INT(11) NOT NULL ,
  `answer` VARCHAR(512) CHARACTER SET 'utf8' COLLATE 'utf8_bin' NOT NULL ,
  `date` DATETIME NOT NULL ,
  `author` INT(11) NULL DEFAULT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `id_idx` (`user_id` ASC) ,
  INDEX `fk_u_information_1_idx` (`information_id` ASC) ,
  CONSTRAINT `fk_u_information_1`
    FOREIGN KEY (`user_id` )
    REFERENCES `dance_with_me`.`users` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_u_information_2`
    FOREIGN KEY (`information_id` )
    REFERENCES `dance_with_me`.`u_information_reg` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
AUTO_INCREMENT = 85
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_bin
COMMENT = 'User information are stored here';


-- -----------------------------------------------------
-- Table `dance_with_me`.`u_information_answers`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `dance_with_me`.`u_information_answers` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `information_id` INT(11) NOT NULL ,
  `answer` VARCHAR(128) CHARACTER SET 'utf8' COLLATE 'utf8_bin' NOT NULL ,
  PRIMARY KEY (`id`) ,
  UNIQUE INDEX `id_UNIQUE` (`id` ASC, `information_id` ASC) ,
  INDEX `id_idx` (`information_id` ASC) ,
  CONSTRAINT `fk_u_information_answers_1`
    FOREIGN KEY (`information_id` )
    REFERENCES `dance_with_me`.`u_information_reg` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
AUTO_INCREMENT = 4
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_bin
COMMENT = 'Options for questions about users';


-- -----------------------------------------------------
-- Table `dance_with_me`.`u_photo`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `dance_with_me`.`u_photo` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `user_id` INT(11) NOT NULL ,
  `photo` LONGBLOB NOT NULL ,
  `profile_pic` TINYINT(1) NOT NULL DEFAULT '0' ,
  PRIMARY KEY (`id`) ,
  INDEX `id_idx` (`user_id` ASC) ,
  CONSTRAINT `a_3`
    FOREIGN KEY (`user_id` )
    REFERENCES `dance_with_me`.`users` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
AUTO_INCREMENT = 16
DEFAULT CHARACTER SET = utf8
COMMENT = 'Profile photo of a user';

USE `dance_with_me` ;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
