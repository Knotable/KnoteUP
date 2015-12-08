#!/usr/bin/env bash
cd ~/.ssh

frontendIP_1=knoteup.com

key=beta.pem


echo "
  Shutting down frontend instances
"
echo "
  $frontendIP_1
"
ssh -i $key ubuntu@$frontendIP_1 bash -c '              \
  echo " "                                          ;   \
  sudo docker rm -f knoteup-mongo                   ;   \
  sudo docker rm -f webapp                          ;   \
  sudo docker rm -f knoteup-nginx
'

echo "
  Running frontend servers
"

echo "
  $frontendIP_1
"
ssh -i $key ubuntu@$frontendIP_1 bash -c '              \
  echo "Logging in..."                              ;   \
  sudo docker login -u knotable -p d0ckerP^55 -e knotable@m.eluck.me registry.knotable.com:443                    &&  \
  sudo docker tag registry.knotable.com:443/knoteup-production registry.knotable.com:443/knoteup-production:old   ;   \
  sudo docker pull registry.knotable.com:443/knoteup-production                                                   &&  \
                                                                                                                      \
  sudo docker pull registry.knotable.com:443/instance-nginx                                                       &&  \
                                                                                                                      \
  sudo docker rm -f knoteup-mongo &>/dev/null                                                                     ;   \
  sleep 2                                                                                                         ;   \
  sudo docker run --name knoteup-mongo -v /var/lib/mongodb:/data/db -d mongo:2.6 mongod --smallfiles              &&  \
                                                        \
  sudo mkdir /knotable-var &>/dev/null              ;   \
  sudo docker rm -f webapp &>/dev/null              ;   \
  sleep 2                                           ;   \
  sudo docker run -d                                    \
      --name webapp                                     \
      --link knoteup-mongo:knoteup-mongo                \
      -e DOMAIN_LONG=knoteup.com                        \
      -e DOMAIN_SHORT=knoteup                           \
      -e HOSTNAME=knoteup.com                           \
      -e MONGO_URL="mongodb://knoteup-mongo/knotepad"   \
      -p 5000:80                                        \
      -v /knotable-var:/logs                            \
      registry.knotable.com:443/knoteup-production  &&  \
                                                        \
  sudo docker rm -f knoteup-nginx &>/dev/null       ;   \
  sleep 2                                           ;   \
  sudo docker run -d                                    \
        --name knoteup-nginx                            \
        -e DOMAIN_LONG=knoteup.com                      \
        -e DOMAIN_SHORT=knoteup                         \
        -p 80:80                                        \
        --link webapp:webapp                            \
        registry.knotable.com:443/instance-nginx    &&  \
                                                        \
  sudo docker rmi -f registry.knotable.com:443/knoteup-production:old                                           ;   \
'

echo "

    Deployment finished

    Check following instances in browser:

    http://$frontendIP_1

"
