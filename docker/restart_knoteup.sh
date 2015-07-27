#!/usr/bin/env bash
cd ~/.ssh

# ==== uncomment lines with servers to be restarted ==== #

#frontendIP_1=knoteup.com

key=dev.pem


echo "
  Restarting frontend instance: $frontendIP_1
"
ssh -i $key ubuntu@$frontendIP_1 bash -c '              \
  echo "Please do not remove this command "         ;   \
  echo "Shutting down..."                           ;   \
  sudo docker stop knoteup-nginx                    ;   \
  sudo docker stop webapp                           ;   \
  sleep 2                                           ;   \
  echo "Starting..."                                ;   \
  sudo docker start webapp                          &&  \
  sudo docker start knoteup-nginx                   &&  \
  echo "
            Tailing log... Press CTRL+C after making sure that the server is running

  "                                                 ;   \
  tail -f /knotable-var/forever.log
'
