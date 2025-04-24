--liquibase formatted sql
--changeset ericsson:3.2.0-base-siteDistance

-- ----------------------------
-- Table structure for siteDistance
-- ----------------------------
DROP TABLE IF EXISTS `siteDistance`;
CREATE TABLE `siteDistance`
(
    `id`          bigint(20) NOT NULL AUTO_INCREMENT,
    `key_A`       varchar(255) NOT NULL,
    `longitude_A` float(10,6)   NOT NULL,
    `latitude_A`  float(10,6)   NOT NULL,
    `key_B`       varchar(255) NOT NULL,
    `longitude_B` float(10,6)   NOT NULL,
    `latitude_B`  float(10,6)   NOT NULL,
    `distance`    decimal(10,4) NOT NULL,
    `voronoiType` varchar(30)  NOT NULL,
    `city`        varchar(50)  NOT NULL,
    PRIMARY KEY (`id`),
    KEY           `voronoiType` (`voronoiType`) USING BTREE,
    KEY           `city` (`city`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;