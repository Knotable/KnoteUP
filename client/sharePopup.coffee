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
      @waitForChannelToBeSelected
      @markChannelSelectionDoneAndHideCheckingConnection
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
      return done() if knoteupConnection.userId()
      return done @slackLoginError if @slackLoginError
      setTimeout pollUntilLoggedIn, 200
    pollUntilLoggedIn()


  getListOfSlackChannelsAndPopulateSelect: (done) =>
    Meteor.call 'getListOfSlackChannels', (error, result) =>
      done error if error
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


  waitForChannelToBeSelected: (done) =>
    @template.$('#channels-list').on 'change', -> done()


  markChannelSelectionDoneAndHideCheckingConnection: (done) =>
    @template.$('#choose-slack-channel .everythings-ok').removeClass('hidden')
    @template.$('#share-ok').removeClass('hidden')
    done()


  processFirstStepErrors: (error) =>
    return console.log 'SlackWorks.onFirstStep.processFirstStepErrors teardown' if error == 'teardown'
    if error
      console.error 'SlackWorks.onFirstStep.processFirstStepErrors errors:', error
      @showError()


  post: (title, text) =>
    @template.$('#share-ok').addClass('hidden')
    @template.$('#share-cancel').prop('disabled', 'disabled')
    @template.$('#channels-list').closest('.selectric-wrapper').addClass('selectric-disabled')
    @template.$('#slack-popup-posting').removeClass('hidden')
    channelId = @template.$('#channels-list').val()
    Meteor.call 'postOnSlack', title, text, channelId, (error, result) =>
      if error
        console.error 'SlackWorks.post error:', error
        return @showError 'Unable to post on Slack'
      @showSuccess()


  showSuccess: =>
    @template.$('#slack-popup-posting-message').text 'Successfully shared the record on Slack'
    @template.$('#slack-popup-posting .animate-spin').addClass('hidden')
    @template.$('#slack-popup-posting .everythings-ok').removeClass('hidden')
    @template.$('#share-ok').addClass('hidden')
    @template.$('#share-cancel').prop('disabled', false)
    @template.$('#share-cancel .share-popup-button-content').text('Close')


  showError: (text) =>
    text = 'An error occured while sharing the knote on Slack'
    @template.$('#slack-popup-posting-message').text text
    @template.$('#slack-popup-posting .animate-spin').addClass('hidden')
    @template.$('#share-ok').addClass('hidden')
    @template.$('#share-cancel').prop('disabled', false)
    @template.$('#share-cancel .share-popup-button-content').text('Close')




Template.sharePopup.onRendered ->
  @data.slackWorks = new SlackWorks @
  @data.slackWorks.run()



Template.sharePopup.events
  'click #authorize-slack-for-knotable-link': (e, template) ->
    e.preventDefault()
    $spinner = template.$('#checking-slack-connection .animate-spin').removeClass('invisible')
    template.$('#checking-slack-connection-text').removeClass('hidden')
    template.$('#checking-slack-connection-authorize-link').addClass('hidden')
    $spinner.removeClass('animate-spin')
    loginWithSlackLocally (error) ->
      template.data.slackWorks.slackLoginError = 'slack login error: ' + error if error
      template.data.slackWorks.teardown = true
      template.data.sharePopup.close()
    Meteor.defer -> $spinner.addClass('animate-spin')


  'click #share-cancel': (e, template) ->
    template.data.slackWorks.teardown = true
    template.data.sharePopup.close()


  'click #share-ok': (e, template) ->
    template.data.slackWorks.post template.data.title, template.data.text
