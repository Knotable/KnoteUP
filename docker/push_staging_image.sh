#!/usr/bin/env bash

eval `boot2docker shellinit`
knoteup_build=`docker inspect --format='{{json .Config.Env}}' registry.knotable.com:443/knoteup-local | sed -n -e 's/^.*KNOTEUP_BUILD=//p' | sed -n -e 's/".*//p'`

docker tag -f registry.knotable.com:443/knoteup-local registry.knotable.com:443/knoteup-staging
docker tag -f registry.knotable.com:443/knoteup-local registry.knotable.com:443/knoteup:latest
docker tag -f registry.knotable.com:443/knoteup-local registry.knotable.com:443/knoteup:$knoteup_build

docker push registry.knotable.com:443/knoteup-staging
docker push registry.knotable.com:443/knoteup:latest
docker push registry.knotable.com:443/knoteup:$knoteup_build
