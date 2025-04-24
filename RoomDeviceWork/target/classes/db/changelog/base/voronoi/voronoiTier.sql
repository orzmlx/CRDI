--liquibase formatted sql
--changeset ericsson:3.2.0-base-voronoi_tier

-- ----------------------------
-- Table structure for voronoi_tier
-- ----------------------------
DROP TABLE IF EXISTS `voronoi_tier`;
CREATE TABLE `voronoi_tier`
(
    `voronoi`      int(11) NOT NULL,
    `voronoiNeigh` int(11) NOT NULL,
    `tier`         int(11) NOT NULL,
    `voronoiType`  varchar(30) NOT NULL,
    `city`         varchar(50) NOT NULL,
    KEY            `voronoiType` (`voronoiType`) USING BTREE,
    KEY            `city` (`city`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for voronoiTier4Openapi
-- ----------------------------
DROP TABLE IF EXISTS `voronoiTier4Openapi`;
CREATE TABLE `voronoiTier4Openapi`
(
    `voronoi`      int(11) NOT NULL,
    `voronoiNeigh` int(11) NOT NULL,
    `tier`         int(11) NOT NULL,
    `voronoiType`  varchar(30) NOT NULL,
    `city`         varchar(50) NOT NULL,
    KEY            `voronoiType` (`voronoiType`) USING BTREE,
    KEY            `city` (`city`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;