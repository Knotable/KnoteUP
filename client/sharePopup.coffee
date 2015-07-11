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
    async.waterfall @checkForTeardown [
      @showCheckingSlackConnection
      @checkWhetherCurrentCredentialsWork
      @goThroughOauthIfNeeded
      @getListOfSlackChannelsAndPopulateSelect
      @markCheckingSlackConnectionDone
    ], (error) ->
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
    @loginWithSlackLocally (error) ->
      return done 'slack login error: ' + error if error
      done()


  getListOfSlackChannelsAndPopulateSelect: (done) =>
    Meteor.call 'getListOfSlackChannels', (error, channels) =>
      done error if error
      console.log '#eluck# getListOfSlackChannels result:', channels
      $select = @template.$('#channels-list')
      $select.append "<option value='#{channel.id}'>#{channel.name}</option>" for channel in channels
      $select.selectric()
      done()


  markCheckingSlackConnectionDone: (done) =>
    @template.$('#checking-slack-connection .animate-spin').addClass('hidden')
    @template.$('#checking-slack-connection .everythings-ok').removeClass('hidden')
    done()


  processFirstStepErrors: (error) =>
    return console.log 'SlackWorks.onFirstStep.processFirstStepErrors teardown' if error == 'teardown'
    console.error 'SlackWorks.onFirstStep.processFirstStepErrors errors:', error if error




Template.sharePopup.onRendered ->
  @data.slackWorks = new SlackWorks @
  @data.slackWorks.run()
