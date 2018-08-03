#!/bin/bash
#
# add kvp's to etcd cluster from csv file
# Author: David Granqvist, Stratsys AB
# Last updated: 2018-08-03  

##################################################
# Iterate over csv file and update etcd cluster with kvp's from file
# Globals: 
#   None
# Arguments: 
#   etcd cluster ip and port on the following form [ip:port]
#   path to csv file
#   etcd username
#   etcd password
# Returns:
#   None
##################################################
function add_etcd_keys(){
    etcd_address=$1
    csv_file_path=$2
    etcd_username=$3
    etcd_password=$4
    prefix=$5

    # printf "\nargument #1 is : $etcd_address\n"
    # printf "argument #2 is : $csv_file_path\n"
    # printf "argument #3 is : $etcd_username\n"
    # printf "argument #4 is : $etcd_password\n"
    # printf "argument #5 is : $prefix\n"

    printf "\nGenerating access token ...\n"
    etcd_token=$(get_auth_token $etcd_address $etcd_username $etcd_password)
    read_and_put_kvps_from_csv $csv_file_path $etcd_token $prefix
    printf "\nDone!"
   }

##################################################
# Get etcd token for auth
# Globals: 
#   None
# Arguments: 
#   etcd cluster ip and port on the following form [ip:port]
#   etcd username
#   etcd password
# Returns:
#   etcd auth token
##################################################
function get_auth_token(){
  etcd_address=$1
  etcd_username=$2
  etcd_password=$3

  etcd_token=$(
    echo curl -X POST -L "http://"${etcd_address}"/v3/auth/authenticate " -d "'{\"name\": \"${etcd_username}\", \"password\": \"${etcd_password}\"}'" | 
    bash | 
    grep -o '\([a-z,A-Z]\{16\}\.[0-9]\{2,3\}\)'
  )
  echo $etcd_token
}

##################################################
# Iterate over csv file and update etcd cluster with kvp's from file
# Globals: 
#   None
# Arguments: 
#   path to csv file
#   etcd auth token
#   prefix used to prepend key with (application/[application name]/configs/[config name]/[Environment]/[companycode])
# Returns:
#   None
##################################################
function read_and_put_kvps_from_csv(){
  csv_file_path=$1
  etcd_token=$2
  prefix=$3

  cat "${csv_file_path}.txt" | while read line
    do
      printf "\n"
      key=$(echo $line | cut -d ',' -f1)
      value=$(echo $line | cut -d ',' -f2)
      put_kvp $key $value $etcd_token $prefix
    done
}

##################################################
# Put kvp in etcd_cluster
# Globals: 
#   None
# Arguments: 
#   key
#   value
#   etcd auth token
#   prefix for prepending key
# Returns:
#   None
##################################################
function put_kvp(){
  key=$1
  value=$2
  etcd_token=$3
  prefix=$4

  key_with_prefix_encoded=$(echo "${prefix}/${key}" | base64)
  value_encoded=$(echo "${value}" | base64)

  printf "pushing kvp: key=\"${prefix}/${key}\", value=\"${value}\"\n"

  # put value in etcd cluster
  echo curl -X POST -L "http://${etcd_address}/v3/kv/put "  -H "'Authorization : ${etcd_token}' " -d "'{\"key\": \"${key_with_prefix_encoded}\", \"value\": \"${value_encoded}\"}'" | bash > /dev/null
  
  # get value from key
  # echo curl -X POST -L "http://${etcd_address}/v3/kv/range " -H "'Authorization : ${etcd_token}' " -d "'{\"key\":  \"${key_with_prefix_encoded}\"}'" |
  # bash |
  # grep -o '\"value\":\"\([a-z,A-Z,0-9,=,+,\]\{0,20\}\)\"\{1\}' |
  # cut -d '"' -f4 |
  # base64 --decode
}

function usage() {
  printf "Usage: add_etcd_keys [ options ... ] <etcdAddress> <PathToCsvFile> <etcdUsername> <etcdPassword> <prefix> \n"
  printf "All arguments are required!\n"
  exit 2
} 2>/dev/null

function main(){
  while [ $# -gt 0 ]; do
    case $1 in
    (-h|--help) usage 2>&1;;
    (*) break;;
    esac
  done

  if [[ ( -z "$1" ) || ( -z "$2" ) || ( -z "$3" ) || ( -z "$4") || ( -z "$5" ) ]]
  then 
    printf " **** No arguments are allowed to be empty!! ****\n"
    usage
    exit "Nope"
  else 
    add_etcd_keys "${@:1:5}"
  fi
}

main "$@"

