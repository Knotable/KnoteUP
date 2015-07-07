Meteor.startup ->
  configureSlackLogin()



configureSlackLogin = ->
  return console.error 'slack login settings not found' unless Meteor.settings.slack?.clientId and
    Meteor.settings.slack?.clientSecret

  ServiceConfiguration = Package['service-configuration'].ServiceConfiguration;
  ServiceConfiguration.configurations.remove service: 'slack'
  ServiceConfiguration.configurations.insert
    service: 'slack'
    clientId: Meteor.settings.slack.clientId
    secret: Meteor.settings.slack.clientSecret
#    loginStyle: 'close'



Accounts.registerLoginHandler (options) ->
  console.log '#eluck# login handler - started', arguments
  return undefined if !options.oauth;
