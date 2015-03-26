Meteor.settings.public.remoteHost ?= 'beta.knotable.com'

remoteServerUrl = Meteor.settings.public.remoteHost
Meteor.remoteConnection = DDP.connect(remoteServerUrl)
Accounts.connection = Meteor.remoteConnection
Meteor.users = new Mongo.Collection 'users', connection: Meteor.remoteConnection

loginToken = 'loginToken'
meteorLoginToken = 'Meteor.loginToken'

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
