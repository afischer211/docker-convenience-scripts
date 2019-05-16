#!/bin/bash
set +ex
#Author: Alexander Fischer

#Convenience script that can help me to easily add labels to an existing
#data volume. The script is mainly useful if you are using named volumes


USAGE="Usage: $0 volume label1 label2 ... labelN"

if [ "$#" == "0" ]; then
	echo "$USAGE"
	exit 1
fi

#First check if the user provided all needed arguments
if [ "$1" = "" ]
then
        echo "Please provide a source volume name"
        exit 1
fi

if [ "$2" = "" ] 
then
        echo "Please provide a list of labels"
        exit 1
fi


#Check if the source volume name does exist
docker volume inspect $1 > /dev/null 2>&1
if [ "$?" != "0" ]
then
        echo "The source volume \"$1\" does not exist"
        exit
fi

#Now check if the destinatin volume name does not yet exist
source_vol=$1
temp_vol=$1_tmp_vol
docker volume inspect $temp_vol > /dev/null 2>&1

if [ "$?" = "0" ]
then
        echo "The temporary destination volume \"$temp_vol\" already exists"
        exit
fi



echo "Creating temporary volume \"$temp_vol\"..."
docker volume create --name $temp_vol  
echo "Copying data from source volume \"$1\" to temporary destination volume \"$temp_vol\"..."
docker run --rm \
           -i \
           -t \
           -v $source_vol:/from:ro \
           -v $temp_vol:/to \
           alpine ash -c "cd /from ; cp -av . /to"

echo "Deleting original source volume \"$source_vol\"..."
docker volume rm $source_vol
echo "Recreating source volume \"$source_vol\" with attached labels..."
cmd_str="docker volume create --name $source_vol "
while (( "$#" )); do
if [ "$2" != "" ]
then
    cmd_str="$cmd_str --label $2 "
fi
shift
done

echo $cmd_str
eval $cmd_str

echo "Copying data from temporary volume \"$temp_vol\" to newly created source volume \"$source_vol\"..."
docker run --rm \
           -i \
           -t \
	   -v $temp_vol:/from:ro \
           -v $source_vol:/to \
           alpine ash -c "cd /from ; cp -av . /to"

echo "Deleting temporary volume \"$temp_vol\"..."
docker volume rm $temp_vol
