#!/usr/bin/env bash

eval `docker-machine env dev`

docker pull registry.knotable.com:443/knoteup-staging
docker tag -f registry.knotable.com:443/knoteup-staging registry.knotable.com:443/knoteup-production
docker push registry.knotable.com:443/knoteup-production
