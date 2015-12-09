#!/usr/bin/env bash



# Request docker software installation
if [ ! `which docker-machine` ] ; then
  echo "
    Please download and install docker-toolbox from official source (not brew):

    https://www.docker.com/docker-toolbox

    Aborting..."
  export result='Failure'
  exit
fi



# Ensure vm (dev) exist and running
vm_status=`docker-machine status dev`
if [ $vm_status"" != "Running" ] ; then
  if [ $vm_status"" == "Stopped" ] ; then
    echo "Starting VM - dev"
    docker-machine start dev
  else
    echo "Creating new VM dev"
    docker-machine create --driver virtualbox dev
    if [ `docker-machine status dev`"" != "Running" ] ; then
      echo " docker-machine create Failed, Aborting..."
      export result='Failure'
      exit
    fi
  fi
fi



# Ensure that we can sign in our registry
eval "$(docker-machine env dev)"
echo "Logging in..."
docker login -u knotable -p d0ckerP^55 -e knotable@m.eluck.me registry.knotable.com:443 2>/dev/null
rc=$?
if [[ $rc != 0 ]] ; then
  echo "Login failed, Trying to update certificates..."
  docker-machine ssh dev "sudo mkdir -p /var/lib/boot2docker/certs/"
  docker-machine ssh dev "sudo wget registry.knotable.com/certs/cert.pem -O /var/lib/boot2docker/certs/registry.knotable.com:443.pem"

  echo "Restarting VM dev"
  docker-machine restart dev

  # Try to log in once more
  echo "Logging in once more..."
  docker login -u knotable -p d0ckerP^55 -e knotable@m.eluck.me registry.knotable.com:443 2>/dev/null
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
