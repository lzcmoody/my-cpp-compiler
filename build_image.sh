#!/bin/bash
# -*- mode: shell-script ; -*-
# build_image.sh: build cpp compiler image
# author: lu charles
# 
echo -e "\n************************************"
echo -e "**** Welcome use build_image.sh ****"
echo -e "************************************\n"
echo -e "\nStart to build c++ compiler image..........\n"

# eg: parse "packages" from "default_package_dir=packages;"
function get_value() {
    INPUT=$1;
    local _name=${INPUT##*=}
    echo ${_name%%;*}
}

# eg: parse "default_package_dir" from "default_package_dir=packages;"
function get_key() {
    INPUT=$1;
    echo ${INPUT%%=*}
}

# eg: parse target_name from "/xx/xx/target_name"
function get_name_from_url() {
    URL=$1;
    local _name=${URL##*/}
    echo ${_name}
}

function parse_conf_section_item_value() {
    INIFILE=$1; SECTION=$2; ITEM_KEY=$3
    local _result=`sh parse_ini.sh -S $SECTION -V $ITEM_KEY $INIFILE`
    local _value=$(get_value $_result)
    echo ${_value}
}

declare -A dependence_map
function parse_dependence_section_items_2_map() {
    INIFILE=$1;
    local _items=`sh parse_ini.sh -S "dependence" $INIFILE`
    OLD_IFS="$IFS"
    IFS=";"
    local array=($_items)
    for item in ${array[@]}
    do
        local _key=$(get_key $item)
        local _value=$(get_value $item)
        dependence_map[$_key]=$_value
    done
}

declare -A install_map
function parse_install_section_items_2_map() {
    INIFILE=$1;
    local _items=`sh parse_ini.sh -S "install" $INIFILE`
    OLD_IFS="$IFS"
    IFS=";"
    local array=($_items)
    for item in ${array[@]}
    do
        local _key=$(get_key $item)
        local _value=$(get_value $item)
        install_map[$_key]=$_value
    done
}

function download_dependence_always() {
    for key in ${!dependence_map[*]};
    do
        local _url=${dependence_map[$key]}
        wget $_url -p $DEFAULT_PACKAGE_DIR
    done
}

function download_dependence_if_not_present() {
    for key in ${!dependence_map[*]};
    do
        local _url=${dependence_map[$key]}
        local _package_name=$(get_name_from_url $_url)
        if [ ! -f $DEFAULT_PACKAGE_DIR/$_package_name ]; then
            wget $_url -p $DEFAULT_PACKAGE_DIR
        fi
    done
}

function get_docker_copy_package_cmd() {
    for key in ${!dependence_map[*]};
    do
        local _url=${dependence_map[$key]}
        local _package_name=$(get_name_from_url $_url)
        echo "COPY $DEFAULT_PACKAGE_DIR/$_package_name ./"
    done
}

function get_docker_copy_script_cmd() {
    for key in ${!install_map[*]};
    do
        local _script=${install_map[$key]}
        echo "COPY $_script ./"
    done
}

function get_docker_run_script_cmd() {
    for key in ${!install_map[*]};
    do
        local _script=${install_map[$key]}
        local _script_name=$(get_name_from_url $_script)
        echo "RUN sh $_script_name"
    done
}

function build_image() {
    DOCKERFILE=$1
    docker build -t $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_VERSION . -f $DOCKERFILE
}

echo -e "Start parse ini configuration file.........."
##1. PARSE CONFIGURATION
#1)parse global conf
DEFAULT_PACKAGE_DIR=$(parse_conf_section_item_value conf.ini global default_package_dir)
PACKAGE_PULL_POLICY=$(parse_conf_section_item_value conf.ini global package_pull_policy)
echo -e "default_package_dir=$DEFAULT_PACKAGE_DIR, package_pull_policy=$PACKAGE_PULL_POLICY"

#2)parse docker conf
DOCKER_BASE_IMAGE=$(parse_conf_section_item_value conf.ini docker base_image)
DOCKER_IMAGE_NAME=$(parse_conf_section_item_value conf.ini docker image_name)
DOCKER_IMAGE_VERSION=$(parse_conf_section_item_value conf.ini docker image_version)
echo -e "base_image=$DOCKER_BASE_IMAGE, image_name=$DOCKER_IMAGE_NAME, image_version=$DOCKER_IMAGE_VERSION"

#3)parse dependence conf
parse_dependence_section_items_2_map conf.ini
for key in ${!dependence_map[*]};
do
    echo -e "$key=${dependence_map[$key]}"
done

#3)parse install conf
parse_install_section_items_2_map conf.ini
for key in ${!install_map[*]};
do
    echo -e "$key=${install_map[$key]}"
done



echo -e "package pull policy:$PACKAGE_PULL_POLICY\n"
##2. DOWNLOAD DEPENDENCE
if [ $PACKAGE_PULL_POLICY == if_not_present ]; then
    echo -e "if not present download dependence......\n"
    download_dependence_if_not_present
    echo -e "preparation complete!\n"
else
    echo -e "downloading dependence......\n"
    download_dependence_always
    echo -e "preparation complete!\n"
fi

##3. GENERATE_DOCKERFILE
echo -e "start generate Dockerfile......\n"
DOCKER_COPY_PACKAGE_CMD=$(get_docker_copy_package_cmd)
DOCKER_COPY_SCRIPT_CMD=$(get_docker_copy_script_cmd)
DOCKER_RUN_SCRIPT_CMD=$(get_docker_run_script_cmd)
DOCKERFILE="Dockerfile"
cat>$DOCKERFILE<<EOF
FROM $DOCKER_BASE_IMAGE
#1.workdir
workdir /tmp
#2.copy packages to /tmp 
$DOCKER_COPY_PACKAGE_CMD
#3.copy scripts to /tmp
$DOCKER_COPY_SCRIPT_CMD
#4.list packages and scripts for check
RUN echo "list all packages and install scripts"
RUN ls -l .
#5.start install dependence
$DOCKER_RUN_SCRIPT_CMD
EOF

cat $DOCKERFILE

#4. BUILD IMAGE
build_image $DOCKERFILE
echo "c++ compiler image built complete!"
