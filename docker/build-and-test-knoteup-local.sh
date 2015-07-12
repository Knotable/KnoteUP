#!/usr/bin/env bash

if [ "$(uname)" != "Darwin" ]; then
  echo "Linux is not supported yet. Aborting..."
  exit
fi


#smart workdir handling :)
root_directory=`git rev-parse --show-toplevel 2>/dev/null`
if [ -z $root_directory"" ] ; then
  echo "

      You are not in a knoteup project directory.
      Please cd into it and run this script again.
      Aborting...

  "
  exit
fi

if [ ! `pwd` == $root_directory ] ; then
  echo "changing to root directory: $root_directory"
  cd $root_directory
fi


#check whether the repo is clean
#if [ "`git status -s`" ] ; then
#  echo "
#    The repository is not clean.
#    Please make sure you committed all your changes and run this script again.
#    Aborting...
#
#  "
#  exit
#fi


echo "

  If this is the first time you've run this it may take some time to download and set up all the dependencies.
  Subsequent builds will be faster.


"

#check docker stuff
source docker/boot2docker_setup.sh
if [ $result"" == "Failure" ] ; then exit ; fi



#pull the latest images from registry
docker pull registry.knotable.com:443/knoteup:latest 2>/dev/null
docker pull registry.knotable.com:443/meteord-webapp 2>/dev/null


#ensure that we have enough space for the new image
availableBoot2DockerSpace=`boot2docker ssh "df -P" | grep /mnt/sda1$ | awk '{print $4}'`
if [ $availableBoot2DockerSpace"" -lt 2000000 ] ; then
  echo "
    Warning!

    boot2docker VM drive has low space. Please remove old or unused docker images or just run:

        boot2docker delete && boot2docker init && boot2docker start && eval \`boot2docker shellinit\`

    and restart the script.
  "
  exit
fi


#get its build number
knoteup_build=`docker inspect --format='{{json .Config.Env}}' registry.knotable.com:443/knoteup:latest | sed -n -e 's/^.*KNOTEUP_BUILD=//p' | sed -n -e 's/".*//p'`
if [[ $knoteup_build"" ]] ; then
  if [ "$knoteup_build" -eq "$knoteup_build" ] 2>/dev/null ; then
    #set and is a number
    knoteup_build=$(( $knoteup_build + 1 ))
  else
    #set but is not a number
    knoteup_build=1
  fi
else
  #not set
  knoteup_build=1
fi
echo "KNOTEUP_BUILD=$knoteup_build"

#prepare Dockerfile - set KNOTEUP_BUILD environment variable
cp docker/Dockerfile.template docker/Dockerfile.$knoteup_build
sed -i "" "s/KNOTEUP_BUILD_NUMBER/$knoteup_build/g" docker/Dockerfile.$knoteup_build

git rev-parse HEAD > conf/knoteup.commit
docker rmi -f registry.knotable.com:443/knoteup-local
docker build -t registry.knotable.com:443/knoteup-local -f docker/Dockerfile.$knoteup_build ./
rm conf/knoteup.commit
rm docker/Dockerfile.$knoteup_build


if [ $1"" == "--notest" ]
  then exit
fi

docker/localhost_run_knoteup.sh
