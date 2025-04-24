--liquibase formatted sql
--changeset ericsson:3.2.0-base-NrToLte

-- ----------------------------
-- Table structure for NrToLte
-- ----------------------------
DROP TABLE IF EXISTS `NrToLte`;
CREATE TABLE `NrToLte`
(
    `siteName`      varchar(255)   NOT NULL,
    `cellName`      varchar(255)   NOT NULL,
    `cgi`           varchar(255)   NOT NULL,
    `voronoi`       int(11) NOT NULL,
    `siteNameNeigh` varchar(255)   NOT NULL,
    `cellNameNeigh` varchar(255)   NOT NULL,
    `cgiNeigh`      varchar(255)   NOT NULL,
    `voronoiNeigh`  int(11) NOT NULL,
    `distance`      decimal(10, 4) NOT NULL,
    `tier`          int(11) NOT NULL,
    `voronoiType`   varchar(30)    NOT NULL,
    `city`          varchar(50)    NOT NULL,
    `date`          date           NOT NULL,
    KEY             `voronoiType` (`voronoiType`) USING BTREE,
    KEY             `city` (`city`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;