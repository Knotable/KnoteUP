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


  'click i.archive': ->
    Knotes.update @_id, $set: archived: true



  'click i.restore': ->
    Knotes.update @_id, $set: archived: false



  'click i.edit-knote': (e, template) ->
    template.controller.isEditing.set(true)



  'click i.share-knote': (e, template) ->
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
    template.controller?.isEditing.set(true)



  'mouseup .knote-body, mouseup .knote-title': (e, template) ->
    if template.controller.isEditing.get() and HighLighter.hasSelection()
      HighLighter.init()
      HighLighter.togglePopupHighlightMenu(e)



  'mousedown .knote-body, mousedown .knote-title': (e) ->
    $(document).data('isHighLighting',true)



Template.knote.helpers
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
      contentEditable: controller?.isEditing.get()
      maxlength: CHAR_LIMITATION_IN_KNOTE_TITLE
      placeholder: 'Take knote'
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
      contentEditable: controller?.isEditing.get()
    container = Blaze.toHTMLWithData(Template.contentEditable, data)
    new Spacebars.SafeString(container)



Template.participatorsAvatar.helpers
  participators: ->
    userAccountId = UserAccounts.findOne({user_ids: Meteor.userId()})?._id
    accountIds = _.difference @pad.participator_account_ids, [userAccountId]
    contacts = Contacts.find({belongs_to_account_id: {$in: accountIds}}).fetch()
    userContact = Contacts.findOne({account_id: userAccountId, type: 'me'})
    contacts.push userContact
    return contacts



Template.participatorsAvatar.events
  'click .add-contact': (event, template) ->
    $('.addContactPopup').lightbox_me(centered: true)



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
          template.$('a.btn-close').click()




Template.pomodoro.onRendered ->
  if pomodoro = @data.pomodoro
    pomodoroTime = moment.duration(moment(pomodoro.date).add(25, 'minutes').subtract(new Date())).asSeconds()
    if pomodoroTime > 0
      startPomodoro(@.$('.pomodoro'), @data._id, @.$('.pomodoro-time'), pomodoroTime)
    else
      Knotes.update {_id: @data._id}, {$unset: pomodoro: '' }



Template.pomodoro.helpers
  isYourPomodoro: ->
    @pomodoro?.userId is Meteor.userId()



Template.pomodoro.events
  'click .pomodoro': (e, t)->
    return if Knotes.find({pomodoro: {$exists: true}}).count()
    knoteId = t.data._id
    pomodoro =
      userId: Meteor.userId()
      date: new Date()
    Knotes.update {_id: knoteId}, {$set: pomodoro: pomodoro }
    startPomodoro($(e.target), knoteId, t.$('.pomodoro-time'))



s2Str = (seconds) ->
   sec = seconds % 60
   min = Math.floor(seconds / 60)
   sec = '0' + sec if sec < 10
   return min + ':' + sec



startPomodoro = ($btnStart, knoteId, $pomodoroTime, pomodoroTime = 25*60) ->
  $btnStart.stopTime(knoteId)
  $pomodoroTime?.html(s2Str(pomodoroTime))
  $btnStart.everyTime "1s", knoteId, (timeOut)=>
    $pomodoroTime?.html(s2Str(pomodoroTime - timeOut))
    if timeOut >= pomodoroTime
      $btnStart.stopTime()
      Knotes.update {_id: knoteId}, {$unset: pomodoro: '' }




