--liquibase formatted sql
--changeset ericsson:3.2.0-base-siteNrOther

-- ----------------------------
-- Table structure for siteNrOther
-- ----------------------------
DROP TABLE IF EXISTS `siteNrOther`;
CREATE TABLE `siteNrOther` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  `city` varchar(50) DEFAULT NULL COMMENT 'city',
  `cgi` varchar(50) DEFAULT NULL COMMENT 'cgi',
  `gNBId` varchar(30) DEFAULT NULL COMMENT 'eNBId',
  `cellLocalId` varchar(30) DEFAULT NULL COMMENT 'cellId',
  `siteName` varchar(255) DEFAULT NULL COMMENT 'siteName',
  `cellName` varchar(255) DEFAULT NULL COMMENT 'cellName',
  `longitude` float(10,6) DEFAULT NULL COMMENT 'longitude',
  `latitude` float(10,6) DEFAULT NULL COMMENT 'latitude',
  `direction` int(11) DEFAULT NULL COMMENT 'direction',
  `cellType` varchar(30) DEFAULT NULL COMMENT 'cellType',
  `downTilt` int(11) DEFAULT NULL COMMENT 'downTilt',
  `antHeight` int(11) DEFAULT NULL COMMENT 'antHeight',
  `rsi` varchar(30) DEFAULT NULL COMMENT 'rsi',
  `formatRSI` varchar(30) DEFAULT NULL COMMENT 'formatRSI',
  `nRTAC` varchar(30) DEFAULT NULL COMMENT 'nRTAC',
  `nRPCI` varchar(30) DEFAULT NULL COMMENT 'nRPCI',
  `ssbFrequency` varchar(30) DEFAULT NULL COMMENT 'ssbFrequency',
  `duplexMode` varchar(10) DEFAULT NULL COMMENT 'duplexMode',
  `band` varchar(10) DEFAULT NULL COMMENT 'band',
  `channelBandWidth` int(11) DEFAULT NULL COMMENT 'channelBandWidth',
  `operator` varchar(10) DEFAULT NULL COMMENT 'operator',
  `vendor` varchar(30) DEFAULT NULL COMMENT 'vendor',
  `importedDate` date DEFAULT NULL COMMENT 'importedDate',
  `deptId` int(11) DEFAULT NULL COMMENT '部门id',
  `cityCn` varchar(255) DEFAULT NULL COMMENT '城市中文名',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ecgi` (`cgi`) USING BTREE,
  KEY `cellName` (`cellName`) USING BTREE,
  KEY `city` (`city`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='友商5G站点信息表';
