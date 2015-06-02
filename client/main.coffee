@loginToken = 'loginToken'
@meteorLoginToken = 'Meteor.loginToken'

Accounts.onLogin ->
  if localStorage[meteorLoginToken]
    amplify.store loginToken, localStorage[meteorLoginToken]


resetLoginToken = ->
  if amplify.store loginToken
    Meteor.setTimeout ->
      localStorage[meteorLoginToken] = amplify.store loginToken
    , 1000

Accounts.onLoginFailure resetLoginToken

resetLoginToken()
