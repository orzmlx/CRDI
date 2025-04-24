--liquibase formatted sql
--changeset ericsson:3.2.0-base-siteLteOther

-- ----------------------------
-- Table structure for siteLteOther
-- ----------------------------
DROP TABLE IF EXISTS `siteLteOther`;
CREATE TABLE `siteLteOther` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'id',
  `city` varchar(50) DEFAULT NULL COMMENT 'city',
  `ecgi` varchar(50) DEFAULT NULL COMMENT 'ecgi',
  `eNBId` varchar(30) DEFAULT NULL COMMENT 'eNBId',
  `cellId` varchar(30) DEFAULT NULL COMMENT 'cellId',
  `siteName` varchar(255) DEFAULT NULL COMMENT 'siteName',
  `cellName` varchar(255) DEFAULT NULL COMMENT 'cellName',
  `longitude` float(10,6) DEFAULT NULL COMMENT 'longitude',
  `latitude` float(10,6) DEFAULT NULL COMMENT 'latitude',
  `direction` int(11) DEFAULT NULL COMMENT 'direction',
  `cellType` varchar(30) DEFAULT NULL COMMENT 'cellType',
  `downTilt` int(11) DEFAULT NULL COMMENT 'downTilt',
  `antHeight` int(11) DEFAULT NULL COMMENT 'antHeight',
  `rsi` varchar(30) DEFAULT NULL COMMENT 'rsi',
  `tac` varchar(30) DEFAULT NULL COMMENT 'tac',
  `pci` varchar(30) DEFAULT NULL COMMENT 'pci',
  `earfcn` int(11) DEFAULT NULL COMMENT 'earfcn',
  `duplexMode` varchar(10) DEFAULT NULL COMMENT 'duplexMode',
  `band` varchar(10) DEFAULT NULL COMMENT 'band',
  `channelBandWidth` int(11) DEFAULT NULL COMMENT 'channelBandWidth',
  `operator` varchar(10) DEFAULT NULL COMMENT 'operator',
  `vendor` varchar(30) DEFAULT NULL COMMENT 'vendor',
  `importedDate` date DEFAULT NULL COMMENT 'importedDate',
  `deptId` int(11) DEFAULT NULL COMMENT '部门id',
  `cityCn` varchar(255) DEFAULT NULL COMMENT '城市中文名',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cgi` (`ecgi`) USING BTREE,
  KEY `cellName` (`cellName`) USING BTREE,
  KEY `city` (`city`) USING BTREE,
  KEY `earfcn` (`earfcn`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='友商4G站点信息表';
