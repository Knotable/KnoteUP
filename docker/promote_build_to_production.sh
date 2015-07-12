#!/usr/bin/env bash
if [ -z $1"" ] ; then
  echo "Build number is not set"
  exit
fi

eval `boot2docker shellinit`

docker pull registry.knotable.com:443/knoteup:$1
docker tag -f registry.knotable.com:443/knoteup:$1 registry.knotable.com:443/knoteup-production
docker push registry.knotable.com:443/knoteup-production
