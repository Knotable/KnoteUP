#!/usr/bin/env bash



# Smart workdir handling :)
root_directory=`git rev-parse --show-toplevel 2>/dev/null`
if [ -z $root_directory"" ] ; then
  echo -e "\nYou are not in a knoteup project directory."
  echo    "Please cd into it and run this script again."
  echo -e "Aborting...\n"
  exit
fi



if [ ! `pwd` == $root_directory ] ; then
  echo -e "\nChanging to root directory: $root_directory"
  cd $root_directory
fi



# Check whether the repo is clean
if [ "`git status -s`" ] ; then
  echo -e "\nThe repository is not clean."
  echo "Please make sure you committed all your changes and run this script again."
  echo -e "Aborting...\n"
  exit
fi



echo -e "\nIf this is the first time you've run this,"
echo    "it may take some time to download and set up all the dependencies."
echo -e "Subsequent builds will be faster.\n\n"



#set up sudo for Linux
sudo='sudo'
if [ "$(uname)" == "Darwin" ]; then
  sudo=
fi



#set up environment for Mac and Linux
if [ "$(uname)" == "Darwin" ]; then
  #check docker stuff
  source docker/docker_machine_setup.sh
  if [ $result"" == "Failure" ] ; then exit ; fi
else
  $sudo docker login -u knotable -p d0ckerP^55 -e knotable@m.eluck.me registry.knotable.com:443
fi



#pull the latest images from registry
$sudo docker pull registry.knotable.com:443/meteord-webapp 2>/dev/null
$sudo docker pull registry.knotable.com:443/knoteup:latest 2>/dev/null



# Ensure that we have enough space for the new image
if [ "$(uname)" == "Darwin" ]; then
  availableVmSpace=`docker-machine ssh dev "df -P" | grep /mnt/sda1$ | awk '{print $4}'`
  if [ $availableVmSpace"" -lt 2000000 ] ; then
    echo -e "\nWarning!"
    echo    "Low space in dev docker-machine. Please remove old or unused docker images,"
    echo -e "Or just run: 'docker-machine rm dev' and run this script again.\n"
    exit
  fi
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
if [ "$(uname)" == "Darwin" ]; then
  sed -i "" "s/KNOTEUP_BUILD_NUMBER/$knoteup_build/g" docker/Dockerfile.$knoteup_build
else
  sed -i "s/KNOTEUP_BUILD_NUMBER/$knoteup_build/g" docker/Dockerfile.$knoteup_build
fi



git rev-parse HEAD > conf/knoteup.commit
$sudo docker rmi -f registry.knotable.com:443/knoteup-local 2>/dev/null
$sudo docker build -t registry.knotable.com:443/knoteup-local -f docker/Dockerfile.$knoteup_build ./
rm conf/knoteup.commit
rm docker/Dockerfile.$knoteup_build


if [ $1"" == "--notest" ]
  then exit
fi
docker/localhost_run_knoteup_new.sh
