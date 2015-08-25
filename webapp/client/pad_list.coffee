Template.pad_list.onRendered ->
  $knotes = $('.currentDatePad .knote')
  Session.set 'knotesNum', $knotes.length

  $title = @$(".new-knote-title")
  PadsListHelper.restoreEditedContent()
  @$('.post-button').attr('disabled', false) if $title.text().length

  latestPad = @data.latestPad
  if latestPad
    $('#header .redirect-to-knotable').attr 'href', UrlHelper.getPadUrlFromId(latestPad._id)

  @find('.currentDatePad .knote-list')?._uihooks = AnimationHooks.moveKnote

  unless window.isMobile
    PadsListHelper.initKnoteDraggable()
  $('#compose-popup').on 'keydown', KnoteHelper.processSavingOnCtrlEnterAction.bind(KnoteHelper, @$('.post-button'))


  @$('.padList').off('scroll').on 'scroll', _.throttle(PadsListHelper.scrollAction, 200)


Template.pad_list.helpers
  username: ->
    Meteor.user()?.username



  leftText: ->
    return PadsListHelper.leftSideMessage @, "text"



  leftImage: ->
    return PadsListHelper.leftSideMessage @, "image"



  composePlaceholder: ->
    knotesNum = Session.get 'knotesNum'
    placeholderNum = PadsListHelper.knotesNumToText(knotesNum)
    return "What's the " + placeholderNum + " thing you need to do today?"



Template.pad_list.events

  'keydown .new-knote-title': (event, template) ->
    PadsListHelper.moveFocusToBodyIfNecessary(event, template)



  'keyup .new-knote-title': (event, template) ->
    PadsListHelper.listenToTitleInput event, template
    title = $(event.currentTarget).text()
    length = title.length
    $postButton = template.$('.post-button')
    if length > 0
      $postButton.attr('disabled', false)
    else
      $postButton.attr('disabled', true)
    PadsListHelper.resetEditedContent()



  'paste .new-knote-title': PadsListHelper.listenToTitlePaste



  'paste #message-textarea': AppHelper.pasteAsPlainTextEventHandler



  'click .post-button': (e, template) ->
    $postButton = $(e.currentTarget).attr('disabled', true)
    subject = $("#header .subject").text()
    $newTitle = template.$(".new-knote-title")
    $newBody = template.$(".new-knote-body")
    title = $newTitle.text()
    body = $newBody.html()

    if not Meteor.userId()
      editKnote =
        title: title
        body: body
      PadsListHelper.storeEditedContent editKnote
      Session.set 'modal', 'login'
    else
      requiredKnoteParameters =
        subject: subject
        body: body
        topic_id: template.data?.latestPad?._id
      optionalKnoteParameters = title: title
      knotesRepository.insertKnote(requiredKnoteParameters, optionalKnoteParameters)
      $newBody.html('').hide()
      $newTitle.html('').focus()
      $('#header .share-pad').show()
      PadsListHelper.resetEditedContent()
    $postButton.attr('disabled', false)



Template.contentEditable.helpers
  attributes: ->
    unless _.has(@, 'contentEditable') or _.has(@, 'contenteditable')
      @['contentEditable'] = false
    return _.omit @, 'value'



  encodedValue: ->
    new Spacebars.SafeString(@value or "")
