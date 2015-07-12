#!/usr/bin/env bash

if [ -z $1"" ] ; then
  echo "Build number is not set, running knoteup-local"
  knoteup_tag=knoteup-local
else
  echo "Running build $1"
  knoteup_tag=knoteup:$1
fi

eval `boot2docker shellinit`
mkdir ~/knotable-var

docker rm -f knoteup-mongo &> /dev/null
docker run --name knoteup-mongo -d mongo:2.6 mongod --smallfiles

docker rm -f webapp &> /dev/null
docker run -d                                     \
    --name webapp                                 \
    -e DOMAIN_LONG=localhost.com                  \
    -e DOMAIN_SHORT=localhost.com                 \
    -e MONGO_URL='mongodb://knoteup-mongo'        \
    -e HOSTNAME=localhost.com                     \
    -p 5000:80                                    \
    --link knoteup-mongo:knoteup-mongo            \
    -v ~/knotable-var:/logs                       \
    registry.knotable.com:443/$knoteup_tag

docker rm -f knoteup-nginx &> /dev/null
docker run -d                                     \
      --name knoteup-nginx                        \
      -e DOMAIN_LONG=localhost.com                \
      -e DOMAIN_SHORT=localhost.com               \
      -p 4000:80                                  \
      --link webapp:webapp                        \
      registry.knotable.com:443/instance-nginx

echo "

  To see how this build works, open in browser

       http://`boot2docker ip`:4000


  To stop the whole thing, use the following command:

       eval \`boot2docker shellinit\` && docker rm -f \`docker ps -aq\`


  Server logs can be found in ~/knotable-var directory
"
