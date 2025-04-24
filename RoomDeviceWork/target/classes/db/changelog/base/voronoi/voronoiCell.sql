--liquibase formatted sql
--changeset ericsson:3.2.0-base-voronoi_cell

-- ----------------------------
-- Table structure for voronoi_cell
-- ----------------------------
DROP TABLE IF EXISTS `voronoi_cell`;
CREATE TABLE `voronoi_cell`
(
    `siteName`    varchar(255) NOT NULL,
    `cellName`    varchar(255) NOT NULL,
    `cgi`         varchar(255) NOT NULL,
    `longitude`   float(10,6)   NOT NULL,
    `latitude`    float(10,6)   NOT NULL,
    `voronoi`     int(11) NOT NULL,
    `voronoiType` varchar(30)  NOT NULL,
    `city`        varchar(50)  NOT NULL,
    KEY           `voronoiType` (`voronoiType`) USING BTREE,
    KEY           `city` (`city`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for voronoiCell4Openapi
-- ----------------------------
DROP TABLE IF EXISTS `voronoiCell4Openapi`;
CREATE TABLE `voronoiCell4Openapi`
(
    `siteName`    varchar(255) NOT NULL,
    `cellName`    varchar(255) NOT NULL,
    `cgi`         varchar(255) NOT NULL,
    `longitude`   float(10,6)   NOT NULL,
    `latitude`    float(10,6)   NOT NULL,
    `voronoi`     int(11) NOT NULL,
    `voronoiType` varchar(30)  NOT NULL,
    `city`        varchar(50)  NOT NULL,
    KEY           `voronoiType` (`voronoiType`) USING BTREE,
    KEY           `city` (`city`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;