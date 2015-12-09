#!/usr/bin/env bash

if [ -z $1"" ] ; then
  echo "Build number is not set, running knoteup-local"
  knoteup_tag=knoteup-local
else
  echo "Running build $1"
  knoteup_tag=knoteup:$1
fi



# set up docker-machine for Mac
if [ "$(uname)" == "Darwin" ]; then
  eval `docker-machine env dev`
fi



#set up sudo for Linux
sudo=sudo
if [ "$(uname)" == "Darwin" ]; then
  sudo=
fi


mkdir ~/knotable-var

$sudo docker rm -f knoteup-mongo &> /dev/null
$sudo docker run --name knoteup-mongo -d mongo:2.6 mongod --smallfiles

$sudo docker rm -f webapp &> /dev/null
$sudo docker run -d                                     \
    --name webapp                                 \
    -e DOMAIN_LONG=localhost.com                  \
    -e DOMAIN_SHORT=localhost.com                 \
    -e MONGO_URL='mongodb://knoteup-mongo'        \
    -e HOSTNAME=localhost.com                     \
    -p 5000:80                                    \
    --link knoteup-mongo:knoteup-mongo            \
    -v ~/knotable-var:/logs                       \
    registry.knotable.com:443/$knoteup_tag

$sudo docker rm -f knoteup-nginx &> /dev/null
$sudo docker run -d                                     \
      --name knoteup-nginx                        \
      -e DOMAIN_LONG=localhost.com                \
      -e DOMAIN_SHORT=localhost.com               \
      -p 4000:80                                  \
      --link webapp:webapp                        \
      registry.knotable.com:443/instance-nginx



if [ "$(uname)" == "Darwin" ]; then
  echo "
    To see how this build works, open in browser

         http://`docker-machine ip dev`:$port


    To stop the whole thing, use the following command:

         eval \`docker-machine env dev\` && docker rm -f \`docker ps -aq\`


    Server logs can be found in ~/knotable-var directory
  "
else
  echo "
    To see how this build works, open in browser

         http://localhost:$port


    To stop the whole thing, use the following command:

         sudo docker rm -f \`sudo docker ps -aq\`


    Server logs can be found in ~/knotable-var directory
  "
fi
