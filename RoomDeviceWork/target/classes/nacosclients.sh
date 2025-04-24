#!/bin/bash

#-------------call example--------------
#export NACOS_HOST=localhost
#export NACOS_PORT=8848
#export NAMESPACE_NAME=dev
#export GROUP_NAME=TBOC_GROUP
#sh nacosclients.sh ./test-dev2.yml

#NACOS_HOST=${NACOS_HOST:-"localhost"}
#NACOS_PORT=${NACOS_PORT:-"8848"}
#NAMESPACE_NAME=${NAMESPACE_NAME:-"dev"}
#GROUP_NAME=${GROUP_NAME:-"TBOC_GROUP"}



RESTAPI_NAMESPACE="http://${NACOS_HOST}:8848/nacos/v1/console/namespaces"
RESTAPI_CONFIGS="http://${NACOS_HOST}:8848/nacos/v1/cs/configs"



check_env(){
  local var="${1}"
  if [[ -z ${!var:-} ]]; then
    echo "ERROR: $HOSTNAME the environment variable \"$var\" do not exist!"
    exit 1
  fi
}

checkToolsJq(){
  if [[! type jq > /dev/null 2>&1 ]]; then
    echo "ERROR: $HOSTNAME command jq do not installed!"
    exit 1
  fi
}


checkNamespace(){
  local namespace_name="${1}"
  RESULT=$(curl -s -X GET $RESTAPI_NAMESPACE | jq -r '.data[].namespaceShowName')
  if [[ $RESULT =~ $namespace_name ]]; then
    echo "0"
  else
    echo "1"
  fi
}

addNamespace(){
	local namespace_name="${1}"
	RESULT=$(curl -s -X POST $RESTAPI_NAMESPACE -d "customNamespaceId=${NAMESPACE_ID}&namespaceName=${namespace_name}&username=${NACOS_USER_NAME}&password=${NACOS_PASSWORD}&namespaceDesc=" )
	if [[ $RESULT =~ "true" ]]; then
	  echo "0"
	else
	  echo "1"
	fi
}


getNamespaceId(){
  RESULT=$(curl -s -X GET $RESTAPI_NAMESPACE | jq -r '.data[] | select(.namespaceShowName == "'${NAMESPACE_NAME}'") | .namespace' )
  echo $RESULT
}

hasConfigs(){
  local config_path="${1}"
  filename=${config_path##*/}
  TENANTID=$(getNamespaceId)
  RESULT=$(curl -s -X GET "${RESTAPI_CONFIGS}?group=${GROUP_NAME}&tenant=${TENANTID}&dataId=${CONF_DATA_ID}&username=${NACOS_USER_NAME}&password=${NACOS_PASSWORD}" )
  if [[ $RESULT =~ "config data not exist" ]]; then
    echo "1"
  else
    echo "0"
  fi
}

addConfigs(){
  local config_path="${1}"
  filename=${config_path##*/}
  TENANTID=$(getNamespaceId)
  if [[ -e $config_path ]]; then
    RESULT=$(curl -s -XPOST --header 'Content-Type: application/x-www-form-urlencoded' -d "tenant=${TENANTID}&dataId=${CONF_DATA_ID}" --data-urlencode content@${config_path} "${RESTAPI_CONFIGS}?group=${GROUP_NAME}&type=yaml&username=${NACOS_USER_NAME}&password=${NACOS_PASSWORD}" )
    if [[ $RESULT =~ "true" ]]; then
	    echo "0"
	  else
	    echo "1"
	  fi
	else
	  echo "1"
	fi
}

#
#check_env "NACOS_HOST"
#check_env "NACOS_PORT"
check_env "NAMESPACE_NAME"
check_env "GROUP_NAME"

#
checkToolsJq


if [[ $# -eq 0 ]]; then
  echo "Error: Please Call eg: nacosclients.sh config_file_path"
  exit 1
fi

APP_CONFIG_FILE=${1}
#APP_CONFIG_FILE="./test-dev2.yml"

#
if [ $(checkNamespace ${NAMESPACE_NAME}) -eq 1 ]; then
  #add namespace
  addNamespace ${NAMESPACE_NAME}
else
  echo "namespace \"$NAMESPACE_NAME\" already exist!"
fi

if [[ $(hasConfigs ${APP_CONFIG_FILE}) -eq 1 ]]; then
  echo "add config \"$APP_CONFIG_FILE\" to nacos"
  addConfigs $APP_CONFIG_FILE
else
  echo "config \"$APP_CONFIG_FILE\" alreay exist!"
fi

