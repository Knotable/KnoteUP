@loginToken = 'loginToken'
@meteorLoginToken = 'Meteor.loginToken'

Accounts.onLogin ->
  if localStorage[meteorLoginToken]
    amplify.store loginToken, localStorage[meteorLoginToken]



resetLoginToken = ->
  timer = Meteor.setInterval ->

    localStorage[meteorLoginToken] = amplify.store loginToken if amplify.store loginToken

    Meteor.clearInterval(timer) if localStorage[meteorLoginToken]
  , 200


Accounts.onLoginFailure resetLoginToken


resetLoginToken()


