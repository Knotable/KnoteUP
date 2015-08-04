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
    knotableConnection.call 'checkCurrentSlackCredentials', (error, credentialsStatusObject) ->
      console.error error if error
      done error if error
      done null, credentialsStatusObject


  goThroughOauthIfNeeded: (credentialsStatusObject, done) =>
    return done() if credentialsStatusObject.ok
    #we have to show login link explicitly because chrome doesn't allow opening new windows
    #now withing an event handler thread
    @template.$('#checking-slack-connection .animate-spin').addClass('invisible')
    @template.$('#checking-slack-connection-text').addClass('hidden')
    @template.$('#checking-slack-connection-authorize-link').removeClass('hidden')
    SlackLogin.credentials = undefined
    pollUntilLoggedIn = =>
      return done() if SlackLogin.credentials
      return done @slackLoginError if @slackLoginError
      setTimeout pollUntilLoggedIn, 200
    pollUntilLoggedIn()


  getListOfSlackChannelsAndPopulateSelect: (done) =>
    knotableConnection.call 'getListOfSlackChannels', (error, result) =>
      done error if error
      done 'getListOfSlackChannels - not ok' unless result.ok
      $select = @template.$('#channels-list')
      $select.append "<option value='#{channel.id}'>#{channel.name}</option>" for channel in result.channels
      $select.selectric()
      $select.on 'change', @saveSelectricChoice
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
    return done() if @restoreSelectricChoice $ '#channels-list'
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


  post: (options) =>
    @template.$('#share-ok').addClass('hidden')
    @template.$('#share-cancel').prop('disabled', 'disabled')
    @template.$('#channels-list').closest('.selectric-wrapper').addClass('selectric-disabled')
    @template.$('#checking-slack-connection').addClass('hidden')
    @template.$('#slack-popup-posting').removeClass('hidden')
    options.channelId = @template.$('#channels-list').val()
    options.baseText = options.text
    options.text = options.text + options.textLink
    knotableConnection.call 'postOnSlack', options, (error, result) =>
      if error
        console.error 'SlackWorks.post error:', error
        return @showError 'Unable to post on Slack'
      @showSuccess(options)
      SharePopup.activeInstance.close()


  showSuccess: (options) =>
    detail = "<p><b>#{options.authorName}</b></p><p>#{options.baseText.replace(/\n/g, '<br>')}</p>"
    showSuccessMessage 'You just posted this to slack #' + $('#channels-list option:selected').text(),
      duration: -1
      detail: detail
      showOk: true


  showError: (text) =>
    text = 'An error occured while sharing the knote on Slack'
    @template.$('#slack-popup-posting-message').text text
    @template.$('#slack-popup-posting .animate-spin').addClass('hidden')
    @template.$('#share-ok').addClass('hidden')
    @template.$('#share-cancel').prop('disabled', false)
    @template.$('#share-cancel .share-popup-button-content').text('Close')


  saveSelectricChoice: (event) =>
    $selectric = $(event.target)
    $wrapper = $selectric.closest('.selectric-wrapper')
    index = $wrapper.find('.selectric-items ul li.selected').data('index')
    $selectedOption = $($wrapper.find('#channels-list option')[index])
    channelId = $selectedOption.prop 'value'
    amplify.store 'lastUsedSlackChannelId', channelId


  restoreSelectricChoice: ($selectric) ->
    channelId = amplify.store 'lastUsedSlackChannelId'
    return unless channelId
    $options = $selectric.find 'option'
    optionIndex = -1
    $options.each (index) -> optionIndex = index if $(this).prop('value') == channelId
    return if optionIndex <= 0
    $selectric.prop('selectedIndex', optionIndex).selectric('refresh')
    return true



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
    SlackLogin.locally (error) ->
      if error
        template.data.slackWorks.slackLoginError = 'slack login error: ' + error
        template.data.slackWorks.teardown = true
        template.data.sharePopup.close()
    Meteor.defer -> $spinner.addClass('animate-spin')


  'click #share-cancel': (e, template) ->
    template.data.slackWorks.teardown = true
    template.data.sharePopup.close()


  'click #share-ok': (e, template) ->
    options = _.pick template.data, 'topicId', 'authorName', 'authorLink', 'knoteId', 'title', 'text', 'textLink'
    template.data.slackWorks.post options
