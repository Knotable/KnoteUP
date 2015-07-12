#!/usr/bin/env bash

#request docker software installation
if [ ! `which boot2docker` ] ; then
  echo "Please install boot2docker from official source (not brew):

  https://github.com/boot2docker/osx-installer/releases

  Aborting..."
  export result='Failure'
  exit
fi


#ensure that boot2docker vm exists and runs
if [ -z "`boot2docker info 2>/dev/null`" ] ; then boot2docker init  ; fi
if [ `boot2docker status`"" != "running" ] ; then boot2docker start ; fi
if [ `boot2docker status`"" != "running" ] ; then
  boot2docker -v delete
  boot2docker -v init
  boot2docker -v start
fi
if [ `boot2docker status`"" != "running" ] ; then
  echo "
    Boot2docker VM init failed. Aborting...
  "
  export result='Failure'
  exit
fi


#ensure that we can sign in our registry
eval `boot2docker shellinit 2>/dev/null`
echo "Logging in..."
docker login -u knotable -p d0ckerP^55 -e knotable@m.eluck.me registry.knotable.com:443
rc=$?
if [[ $rc != 0 ]] ; then
  echo "Login failed, trying to update certificates..."

  #set up registry certificates
  echo "setting up registry certificates"
  curl registry.knotable.com/certs/cert.pem -o ~/.ssh/registry.knotable.com-certificate.pem
  boot2docker ssh "sudo mkdir -p /var/lib/boot2docker/certs/"
  boot2docker ssh "sudo cp /Users/$USER/.ssh/registry.knotable.com-certificate.pem /var/lib/boot2docker/certs/"

  #set up boot2docker init script
  echo "Setting up boot2docker init script"
  mkdir ~/.boot2docker/tmp
  cp docker/boot2docker_bootlocal.sh ~/.boot2docker/tmp/bootlocal.sh
  boot2docker ssh "sudo cp /Users/$USER/.boot2docker/tmp/bootlocal.sh /var/lib/boot2docker/bootlocal.sh"

  #restart boot2docker vm
  echo "Waiting for boot2docker to restart"
  boot2docker stop
  boot2docker stop
  boot2docker start

  #try to log in once more
  eval `boot2docker shellinit 2>/dev/null`
  echo "Logging in..."
  docker login -u knotable -p d0ckerP^55 -e knotable@m.eluck.me registry.knotable.com:443
  rc=$?
  if [[ $rc != 0 ]] ; then
    echo "
      Login failed. Aborting...
    "
    export result='Failure'
    exit
  fi
fi


export result='Success'
