#!/usr/bin/env bash
commit_hash=`cat /conf/knoteup.commit`
sed_command='s/SED_COMMIT_TAG/'$commit_hash'/g;'
if [[ $ROLE"" ]] ; then
  knoteup_config=/conf/$DOMAIN_LONG-$ROLE.json
else
  knoteup_config=/conf/$DOMAIN_LONG.json
fi

#settings consumed by node.js and meteor
export METEOR_SETTINGS=`sed $sed_command $knoteup_config`
export ROOT_URL='http://'$DOMAIN_LONG
export PORT=80
hostname $HOSTNAME

cd /built_app

forever start                     \
  -a                              \
  -l /logs/forever.log            \
  -e /logs/forever.error          \
  main.js                      && \
  tail -f /logs/forever.log
