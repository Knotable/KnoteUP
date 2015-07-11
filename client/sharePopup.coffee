class SlackWorks
  constructor: (template) ->
    @template = template


  run: =>
    async.waterfall [
      @onFirstStep
    ],
      @finish


  finish: (errors) =>
    console.error 'SlackWorks.finish errors:', errors if errors


  checkForTeardown: (arrayOfFunctions) =>
    check = => throw 'teardown' if @teardown
    return (_.wrap func, check for func in arrayOfFunctions)


  onFirstStep: (done) =>
    async.waterfall [
      @showCheckingSlackConnection
      @checkWhetherCurrentCredentialsWork
      @goThroughOauthIfNeeded
      @getListOfSlackChannelsAndPopulateSelect
      @showChannelSelectionCard
    ], (error) =>
      @processFirstStepErrors error
      done error


  showCheckingSlackConnection: (done) =>
    @template.$('#checking-slack-connection').removeClass('hidden')
    done()


  checkWhetherCurrentCredentialsWork: (done) =>
    Meteor.call 'checkCurrentSlackCredentials', (error, credentialsStatusObject) ->
      done error if error
      done null, credentialsStatusObject


  goThroughOauthIfNeeded: (credentialsStatusObject, done) =>
    return done() if credentialsStatusObject.ok
    #we have to show login link explicitly because chrome doesn't allow opening new windows
    #now withing an event handler thread
    @template.$('#checking-slack-connection .animate-spin').addClass('invisible')
    @template.$('#checking-slack-connection-text').addClass('hidden')
    @template.$('#checking-slack-connection-authorize-link').removeClass('hidden')
    knoteupConnection.setUserId null
    pollUntilLoggedIn = =>
      console.log '#eluck# pollUntilLoggedIn userId:', knoteupConnection.userId()
      return done() if knoteupConnection.userId()
      return done @slackLoginError if @slackLoginError
      setTimeout pollUntilLoggedIn, 200
    pollUntilLoggedIn()


  getListOfSlackChannelsAndPopulateSelect: (done) =>
    Meteor.call 'getListOfSlackChannels', (error, result) =>
      done error if error
      console.log '#eluck# getListOfSlackChannels result:', result
      done 'getListOfSlackChannels - not ok' unless result.ok
      $select = @template.$('#channels-list')
      $select.append "<option value='#{channel.id}'>#{channel.name}</option>" for channel in result.channels
      $select.selectric()
      done()


  showChannelSelectionCard: (done) =>
    @template.$('#checking-slack-connection .animate-spin').addClass('hidden')
    @template.$('#checking-slack-connection-text').addClass('hidden')
    @template.$('#checking-slack-connection-authorize-link').addClass('hidden')
    @template.$('#checking-slack-connection .everythings-ok').removeClass('hidden')
    @template.$('#slack-connection-is-ok').removeClass('hidden')
    @template.$('#choose-slack-channel').removeClass('hidden')
    done()


  processFirstStepErrors: (error) =>
    return console.log 'SlackWorks.onFirstStep.processFirstStepErrors teardown' if error == 'teardown'
    console.error 'SlackWorks.onFirstStep.processFirstStepErrors errors:', error if error




Template.sharePopup.onRendered ->
  @data.slackWorks = new SlackWorks @
  @data.slackWorks.run()



Template.sharePopup.events
  'click #authorize-slack-for-knotable-link': (e, template) ->
    template.$('#checking-slack-connection .animate-spin').removeClass('invisible')
    template.$('#checking-slack-connection-text').removeClass('hidden')
    template.$('#checking-slack-connection-authorize-link').addClass('hidden')
    e.preventDefault()
    loginWithSlackLocally (error) ->
      template.data.slackWorks.slackLoginError = 'slack login error: ' + error if error
