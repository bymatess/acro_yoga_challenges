CREATE DATABASE  IF NOT EXISTS `dance_with_me` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `dance_with_me`;
-- MySQL dump 10.13  Distrib 5.7.18, for Linux (x86_64)
--
-- Host: 127.0.0.1    Database: dance_with_me
-- ------------------------------------------------------
-- Server version	5.7.18-0ubuntu0.16.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `accepted_challenge`
--

DROP TABLE IF EXISTS `accepted_challenge`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `accepted_challenge` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `position_id` int(11) NOT NULL,
  `accepted` datetime DEFAULT NULL,
  `completed` datetime DEFAULT NULL,
  `deleted` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `id_idx` (`user_id`),
  KEY `fk_u_posiiton_1_idx` (`position_id`),
  CONSTRAINT `fk_u_position_2` FOREIGN KEY (`position_id`) REFERENCES `position` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_u_user_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='matrix for user - position';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `category`
--

DROP TABLE IF EXISTS `category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `category` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) COLLATE utf8_bin NOT NULL,
  `description` varchar(512) COLLATE utf8_bin DEFAULT NULL,
  `created` datetime NOT NULL ,
  `updated` datetime NOT NULL ,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Categories of the poses';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `category`
--

LOCK TABLES `category` WRITE;
/*!40000 ALTER TABLE `category` DISABLE KEYS */;
INSERT INTO `category` VALUES 
(1,'L-base pose','Static pose while the Base is on its back','2017-03-16 19:26:19','2017-03-16 19:26:19'),
(2,'L-base washing machine','Transition from one pose back to the same pose','2017-03-16 19:26:19','2017-03-16 19:26:19'),
(3,'Standing','Positions where the Base is standing','2017-03-26 12:52:15','2017-03-26 12:52:15'),
(4,'Counter-balance','Balancing act in two people','2017-03-26 12:52:15','2017-03-26 12:52:15'),
(5,'Flow','More poses and transitions combined in a flow','2017-03-26 12:52:15','2017-03-26 12:52:15'),
(6,'3 people','Stunts in 3 people','2017-03-26 12:52:15','2017-03-26 12:52:15'),
(7,'Groups','Stunts in more than 3 people','2017-03-26 12:52:15','2017-03-26 12:52:15'),
(8,'Other','Not fitting in any category','2017-03-26 12:52:15','2017-03-26 12:52:15'),
(9,'Places','Share your crazy places where you do AcroYoga :-)','2017-03-26 12:52:15','2017-03-26 12:52:15');
/*!40000 ALTER TABLE `category` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fb_users`
--

DROP TABLE IF EXISTS `fb_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fb_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fb_id` bigint(20) NOT NULL,
  `email` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `first_name` varchar(45) COLLATE utf8_bin DEFAULT NULL,
  `last_name` varchar(45) COLLATE utf8_bin DEFAULT NULL,
  `full_name` varchar(128) COLLATE utf8_bin NOT NULL,
  `locale` varchar(32) COLLATE utf8_bin DEFAULT NULL,
  `timezone` int(11) DEFAULT NULL,
  `profile_link` varchar(256) COLLATE utf8_bin DEFAULT NULL,
  `gender` tinyint(1) NOT NULL DEFAULT '0',
  `created` datetime NOT NULL ,
  `last_login` datetime NOT NULL ,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Store basic information about users';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `p_photo`
--

DROP TABLE IF EXISTS `p_photo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `p_photo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `photo` longblob NOT NULL,
  `position_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `id_idx` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Positions photos';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `position`
--

DROP TABLE IF EXISTS `position`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `position` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) COLLATE utf8_bin NOT NULL,
  `description` varchar(512) COLLATE utf8_bin DEFAULT NULL,
  `user_id` int(11) NOT NULL,
  `category_id` int(11) NOT NULL,
  `created` datetime NOT NULL ,
  `updated` datetime NOT NULL ,
  `video_link` varchar(1024) COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `user_id` (`user_id`),
  KEY `category_id` (`category_id`),
  CONSTRAINT `position_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `position_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `category` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Positions';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `u_information`
--

DROP TABLE IF EXISTS `u_information`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `u_information` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `information_id` int(11) NOT NULL,
  `answer` varchar(512) COLLATE utf8_bin NOT NULL,
  `date` datetime NOT NULL,
  `author` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `id_idx` (`user_id`),
  KEY `fk_u_information_1_idx` (`information_id`),
  CONSTRAINT `fk_u_information_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_u_information_2` FOREIGN KEY (`information_id`) REFERENCES `u_information_reg` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='User information are stored here';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `u_information_answers`
--

DROP TABLE IF EXISTS `u_information_answers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `u_information_answers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `information_id` int(11) NOT NULL,
  `answer` varchar(128) COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`,`information_id`),
  KEY `id_idx` (`information_id`),
  CONSTRAINT `fk_u_information_answers_1` FOREIGN KEY (`information_id`) REFERENCES `u_information_reg` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Options for questions about users';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `u_information_reg`
--

DROP TABLE IF EXISTS `u_information_reg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `u_information_reg` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `headline` varchar(128) COLLATE utf8_bin NOT NULL,
  `description` varchar(512) COLLATE utf8_bin DEFAULT NULL,
  `options` tinyint(1) DEFAULT NULL COMMENT 'Does there exist answers for this question?\nIn u_information_answers_reg',
  `order_by` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Categories of information (questions). Eg. What''s your favou /* comment truncated */ /* /* comment truncated */ /* /* comment truncated */ /*rite color?*/*/*/';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `u_photo`
--

DROP TABLE IF EXISTS `u_photo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `u_photo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `photo` longblob NOT NULL,
  `profile_pic` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `id_idx` (`user_id`),
  CONSTRAINT `a_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8 COMMENT='Profile photo of a user';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `password` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `email` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `first_name` varchar(45) COLLATE utf8_bin DEFAULT NULL,
  `last_name` varchar(45) COLLATE utf8_bin DEFAULT NULL,
  `birthday` date DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `confirm_code` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `confirmed` varchar(45) COLLATE utf8_bin DEFAULT NULL,
  `about` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `gender` tinyint(1) NOT NULL DEFAULT '0',
  `fb_id` bigint(20) NOT NULL,
  `full_name` varchar(128) COLLATE utf8_bin DEFAULT NULL,
  `locale` varchar(32) COLLATE utf8_bin DEFAULT NULL,
  `timezone` int(11) DEFAULT NULL,
  `profile_link` varchar(256) COLLATE utf8_bin DEFAULT NULL,
  `created` datetime NOT NULL ,
  `last_login` datetime NOT NULL ,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Store basic information about users';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping events for database 'dance_with_me'
--

--
-- Dumping routines for database 'dance_with_me'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-06-10 20:08:34
