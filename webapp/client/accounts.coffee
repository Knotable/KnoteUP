# A Meteor global variable
@autoLoginEnabled = false


@loggedInLocally = new ReactiveVar false
@loggedInKnotable = new ReactiveVar false

Meteor.startup ->
  Tracker.autorun -> loggedInLocally.set Boolean knoteupConnection.userId()
  Tracker.autorun -> loggedInKnotable.set Boolean knotableConnection.userId()


# Key names to use in localStorage
loginTokenKey = ".loginToken"
loginTokenExpiresKey = ".loginTokenExpires"
userIdKey = ".userId"


unstoreLoginToken = ->
  Meteor._localStorage.removeItem 'Meteor' + userIdKey
  Meteor._localStorage.removeItem 'Meteor' + loginTokenKey
  Meteor._localStorage.removeItem 'Meteor' + loginTokenExpiresKey


makeClientLoggedOut = ->
  unstoreLoginToken()
  knoteupConnection.setUserId null
  knoteupConnection.onReconnect = null


Meteor.startup ->
  knoteupConnection.logout = ->
    knoteupConnection.apply 'logout', [], {wait: true}, ->
      makeClientLoggedOut()



@SlackLogin =
  locally: (done) ->
    Accounts.connection = knoteupConnection
    Meteor.loginWithSlack {
      requestPermissions: [
        'read', 'post', 'identify', 'client'
        ]
    },
    (error) ->
      Accounts.connection = knotableConnection
      console.error 'loginWithSlack error:', error if error
      saveSlackCredentialsOnKnotable() unless error
      Meteor.defer ->
        for key in [loginTokenKey, loginTokenExpiresKey, userIdKey]
          #intercept Meteor keys
          amplify.store 'Local' + key, localStorage['Meteor' + key] if localStorage['Meteor' + key]
          #set Knotable keys because they could have been overriden
          ensureSetLocalStorage 'Meteor' + key, amplify.store 'Knotable' + key
      done error


  credentials: undefined



saveSlackCredentialsOnKnotable = ->
  knoteupConnection.call 'getMySlackCredentials', (error, result) ->
    return console.error 'getMySlackCredentials error:', error if error
    return console.error 'getMySlackCredentials no credentials got' unless result
    knotableConnection.call 'updateSlackCredentials', result.id, result.accessToken
    SlackLogin.credentials = result




ensureSetLocalStorage = (localStorageKey, value) ->
  maintainFor = 5000
  maintainedFor = 0
  timeout = 200
  check = ->
    if localStorage[localStorageKey] == value
      maintainedFor += timeout
      return if maintainedFor >= maintainFor
    else
      localStorage[localStorageKey] = value
    setTimeout check, timeout
  check()



@logout = ->
  Meteor.logout()
  for key in [loginTokenKey, loginTokenExpiresKey, userIdKey]
    amplify.store 'Local' + key, null
    amplify.store 'Knotable' + key, null




Tracker.autorun ->
  if loggedInKnotable.get()
    for key in [loginTokenKey, loginTokenExpiresKey, userIdKey]
      amplify.store 'Knotable' + key, localStorage['Meteor' + key] if localStorage['Meteor' + key]
  else
    for key in [loginTokenKey, loginTokenExpiresKey, userIdKey]
      ensureSetLocalStorage 'Meteor' + key, amplify.store 'Knotable' + key
