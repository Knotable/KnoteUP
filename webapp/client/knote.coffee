Template.pomodoro.onRendered ->
  $time = @.$('.pomodoro-time')
  $pomodoro = @.$('.pomodoro')
  $pageTitle = $('title')
  $favicon = $('#favicon')

  $(pomodoroHelper).on 'stop', ->
    user = AppHelper.currentContact()
    if user
      $pageTitle.text('Knoteup - ' + user.username)
    else
      $pageTitle.text('Knoteup')
    $favicon?.attr('href', '/favicon.ico')

  $(pomodoroHelper).on 'flushing', (event, time)->
    $time.text(time)
    $pageTitle.text("Knoteup - #{time}")
    $pomodoro?.toggleClass('animate')
    if $pomodoro?.hasClass('animate')
      $favicon.attr('href', '/tomato-red.ico')
    else
      $favicon.attr('href', '/tomato.ico')

  $(pomodoroHelper).on 'running', (event, time)->
    $time?.text(time)
    $pageTitle?.text("Knoteup - #{time}")
    $favicon.attr('href', '/tomato-red.ico')
    $pomodoro?.addClass('animate')

  pomodoroHelper.startPomodoro(@data._id)



Template.pomodoro.onDestroyed ->
  pomodoroHelper.stopPomodoro()



Template.knote.onCreated ->
  @controller =
    isEditing: new ReactiveVar(false)



Template.knote.onRendered ->
  template = @
  knote = @data
  @autorun =>
    if @controller.isEditing.get()
      $(@find '.knote-title').focus()

  if knote.requiresPostProcessing
    Meteor.setTimeout ->
      KnoteHelper.formatAndSave template
    , 1000



Template.knote.events
  'click img.thumb': (e, t) ->
    e.preventDefault()
    e.stopPropagation()
    imgUrl = $(e.currentTarget).parents('.embedded-link').attr 'href'
    showImagePopup(url: imgUrl) if imgUrl


  'click .archive': (e, t) ->
    if not @isPosting and not @isFailed
      Knotes.update @_id, {$set: {archived: true}, $unset: {pomodoro: '' }}
      Meteor.setTimeout ->
        PadsListHelper.updateOrder(t, "archived")
      , 500



  'click .restore': (e, t) ->
    Knotes.update @_id, $set: archived: false
    Meteor.setTimeout ->
      PadsListHelper.updateOrder(t, "archived")
    , 500



  'click .edit-knote': (e, template) ->
    if not @isPosting and not @isFailed
      template.controller.isEditing.set(true)



  'click .share-knote': (e, template) ->
    e.stopPropagation()
    title = template.$(".knote-title").val()
    text = template.$(".knote-body").text()
    new SharePopup(
      knoteId: @_id
      title: title
      text: text
    ).show()



  'click .btn-cancel': (e, template) ->
    template.controller?.isEditing.set(false)
    template.$('.knote-actions').show()



  "click .btn-save": (e, template) ->
    title = template.$(".knote-title").html()
    body = template.$(".knote-body").html()
    template.$('.knote-actions').show()
    if title isnt @title or body isnt @htmlBody
      KnoteHelper.formatAndSave template, (err) ->
        showErrorBootstrapGrowl(err.reason) if err?.error is "validationError"
    else
      template.controller.isEditing.set(false)



  'paste .knote-title': PadsListHelper.listenToTitlePaste



  'paste .knote-body': AppHelper.pasteAsPlainTextEventHandler



  'keydown .knote-title': (event, template) ->
    PadsListHelper.moveFocusToBodyIfNecessary(event, template)



  'keyup .knote-title': (event, template) ->
    PadsListHelper.listenToTitleInput event, template



  'click .icon-chat': (e) ->
    knote = $(e.currentTarget).closest('.knote')
    composePopup = knote.find('.knote-compose-popup-cn')
    actions = knote.find('.knote-actions')
    actions.hide()
    knote.find('.pomodoro-container')?.hide()
    composePopup.slideToggle()
    setTimeout ->
      composePopup.find('.reply-message-textarea').focus()
    , 500



  'dblclick .knote-content': (e, template) ->
    if not @isPosting and not @isFailed
      template.controller?.isEditing.set(true)



  'keydown .knote': (e, template) ->
    KnoteHelper.processSavingOnCtrlEnterAction(template.$('.btn-save'), e)



  'click .re-post-knote': (e) ->
    $button = $(e.currentTarget).prop('disabled', true)
    originalText = $button.val()
    $button.val('Retrying...')
    promise = knotesRepository.repostKnote(@_id)
    promise.always ->
      $button.prop('disabled', false).val(originalText)



  'click .delete_file_ico': (e, t) ->
    $thumbBox = $(e.target).parents('.thumb-box')
    if $thumbBox.length
      $thumbBox.hide().addClass('file-archiving')


  'click .delete-knote': (e, t) ->
    KnoteHelper.deleteKnote @_id
    Meteor.setTimeout ->
      PadsListHelper.updateOrder(t, "archived")
    , 500



  'click .pomodoro': (e, t)->
    pomodoroHelper.clickOnTomato(t.data._id)


Template.knote.helpers
  isPomodoro: ->
    @pomodoro and not @pomodoro.pauseTime



  dateNewFormat: ->
    return '' unless @date
    nowDate = moment()
    knoteDate = moment(@date)
    if nowDate.year() isnt knoteDate.year()
      format = 'MMM DD, YYYY [at] ha'
      return knoteDate.format(format)
    if nowDate.isSame(knoteDate, 'day')
      return knoteDate.format('[today at] ha')
    return knoteDate.format('MMM DD [at] ha')



  contact: ->
    Contacts.findOne({emails: @from})



  isEditing: ->
    Template.instance()?.controller?.isEditing.get()



  invisibleClass: ->
    'invisible' unless @archived or Template.instance()?.controller?.isEditing.get()



  # This implementation prevents contentEditable duplicating text issue
  # https://github.com/meteor/meteor/issues/1964
  knoteTitleEditableContainer: ->
    controller = Template.instance()?.controller
    data =
      value: @title
      class: 'knote-title editKnote'
      contentEditable: if @archived then false else controller?.isEditing.get()
      maxlength: CHAR_LIMITATION_IN_KNOTE_TITLE
      placeholder: 'What needs to be done?'
      tabindex: 16
    data.class += ' hidden' if not controller?.isEditing.get() and _.isEmpty(PadsListHelper.getTextFromHtml(@title))
    container = Blaze.toHTMLWithData(Template.contentEditable, data)
    new Spacebars.SafeString(container)



  # This implementation prevents contentEditable duplicating text issue
  # https://github.com/meteor/meteor/issues/1964
  knoteBodyEditableContainer: ->
    controller = Template.instance()?.controller
    body = @htmlBody or @body or ''
    htmlClasses = 'knote-body compose-area file-container highlight-color-link-color message_text'
    htmlClasses += " hidden" if _.isEmpty(PadsListHelper.getTextFromHtml(body))
    data =
      class: htmlClasses
      value: body
      contentEditable: if @archived then false else controller?.isEditing.get()
    container = Blaze.toHTMLWithData(Template.contentEditable, data)
    new Spacebars.SafeString(container)



  isPostingOrFailed: ->
    @isPosting or @isFailed




Template.addContactPopupBox.events
  'click .add-new-users': (event, template) ->
    emails = template.$('.emails').val()
    emails = emails.split(',')
    emails = _.select emails, (email) ->
      email.match(/[\w-]+@([\w-]+\.)+[\w-]+/)
    emails = _.map emails, (email) -> $.trim(email)
    if emails.length
      Meteor.remoteConnection.call 'addContactsToThread', template.data.pad._id, emails, (error, result) ->
        if error
          console.log 'ERROR: addContactsToThread', error
        else
          template.$('.icon-cancel').click()
