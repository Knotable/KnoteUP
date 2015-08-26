Template.compose.onRendered ->
  PadsListHelper.restoreEditedContent()
  @$('.post-button').attr('disabled', false) if @$(".new-knote-title").text().length



Template.compose.helpers

  composePlaceholder: ->
    knotesNum = Session.get 'knotesNum'
    placeholderNum = PadsListHelper.knotesNumToText(knotesNum)
    return "What's the " + placeholderNum + " thing you need to do today?"



Template.compose.events

  'keydown .new-knote-title': (e, t) ->
    PadsListHelper.moveFocusToBodyIfNecessary(e, t)
    KnoteHelper.processSavingOnCtrlEnterAction.bind(KnoteHelper, t.$('.post-button'))

  'keydown .new-knote-body': (e, t) ->
    KnoteHelper.processSavingOnCtrlEnterAction.bind(KnoteHelper, t.$('.post-button'))


  'keyup .new-knote-title': (e, t) ->
    PadsListHelper.listenToTitleInput e, t
    KnoteHelper.togglePost(t, $(e.currentTarget).text())
    PadsListHelper.resetEditedContent()



  'paste .new-knote-title': PadsListHelper.listenToTitlePaste



  'paste .new-knote-body': AppHelper.pasteAsPlainTextEventHandler



  'click .post-button': (e, t) ->
    $postButton = $(e.currentTarget)
    $postButton.attr('disabled', true)
    subject = $("#header .subject").text()
    $newTitle = t.$(".new-knote-title")
    $newBody = t.$(".new-knote-body")
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
        topic_id: t.data?.latestPad?._id
      optionalKnoteParameters = title: title
      knotesRepository.insertKnote(requiredKnoteParameters, optionalKnoteParameters)
      $newBody.html('').hide()
      $newTitle.html('').focus()
      $('#header .share-pad').show()
      PadsListHelper.resetEditedContent()
