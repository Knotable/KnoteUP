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
      @markCheckingSlackConnectionDone
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
    @template.$('#checking-slack-connection').addClass('hidden')
    return done() if credentialsStatusObject.ok
    #we have to show login link explicitly because chrome doesn't allow opening new windows
    #now withing an event handler thread
    @template.$('#authorize-slack-for-knotable').removeClass('hidden')
    knoteupConnection.setUserId null
    pollUntilLoggedIn = =>
      console.log '#eluck# pollUntilLoggedIn userId:', knoteupConnection.userId()
      return done() if knoteupConnection.userId()
      return done @slackLoginError if @slackLoginError
      setTimeout pollUntilLoggedIn, 200
    pollUntilLoggedIn()


  getListOfSlackChannelsAndPopulateSelect: (done) =>
    $('#authorize-slack-for-knotable .animate-spin').addClass('hidden')
    $('#authorize-slack-for-knotable .everythings-ok').removeClass('hidden')
    Meteor.call 'getListOfSlackChannels', (error, result) =>
      done error if error
      console.log '#eluck# getListOfSlackChannels result:', result
      done 'getListOfSlackChannels - not ok' unless result.ok
      $select = @template.$('#channels-list')
      $select.append "<option value='#{channel.id}'>#{channel.name}</option>" for channel in result.channels
      $select.selectric()
      done()


  markCheckingSlackConnectionDone: (done) =>
    @template.$('#authorize-slack-for-knotable').addClass('hidden')
    @template.$('#choose-slack-channel').removeClass('hidden')
    @template.$('#checking-slack-connection .everythings-ok').removeClass('hidden')
    done()


  processFirstStepErrors: (error) =>
    return console.log 'SlackWorks.onFirstStep.processFirstStepErrors teardown' if error == 'teardown'
    console.error 'SlackWorks.onFirstStep.processFirstStepErrors errors:', error if error




Template.sharePopup.onRendered ->
  @data.slackWorks = new SlackWorks @
  @data.slackWorks.run()



Template.sharePopup.events
  'click #authorize-slack-for-knotable-link': (e, template) ->
    $('#authorize-slack-for-knotable .animate-spin').removeClass('hidden')
    e.preventDefault()
    loginWithSlackLocally (error) ->
      template.data.slackWorks.slackLoginError = 'slack login error: ' + error if error
