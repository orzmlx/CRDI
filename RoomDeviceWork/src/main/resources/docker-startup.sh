#!/bin/bash
#All rights Reserved, Designed By www.ericsson.com
#date 2021/10/27 15:29
#copyright 2021 www.ericsson.com
set -x
#===========================================================================================
#set environment
#===========================================================================================
#export

#===========================================================================================
# 配置文件非覆盖拷贝
#===========================================================================================
awk 'BEGIN { cmd="cp -ri /opt/app/generator/bak/* /opt/app/generator/conf/ "; print "n" |cmd; }'

#===========================================================================================
# nacos注册
#===========================================================================================
/bin/bash ./nacosclients.sh ./conf/application.yml

#===========================================================================================
# create database
#===========================================================================================
#mysql -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "show databases;"
mysql -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE} DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"
#mysql -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWORD} -D ${MYSQL_DATABASE} -e "SOURCE /opt/app/eniqTool/conf/eniqTool.sql"

#===========================================================================================
#run java jar
#===========================================================================================
exec java ${JAVA_OPTS} -jar /opt/app/generator/generator.jar --spring.config.location=/opt/app/generator/conf/${CONF_FILE_NAME}