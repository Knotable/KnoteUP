Template.compose.onRendered ->
  PadsListHelper.restoreEditedContent()
  @$('.post-button').attr('disabled', false) if @$(".knote-title").text().length
  $('#compose-popup').on 'keydown', KnoteHelper.processSavingOnCtrlEnterAction.bind(KnoteHelper, @$('.post-button'))



Template.compose.helpers

  composePlaceholder: ->
    knotesNum = Session.get 'knotesNum'
    placeholderNum = PadsListHelper.knotesNumToText(knotesNum)
    return "What's the " + placeholderNum + " thing you need to do today?"



Template.compose.events

  'keydown .knote-title': (e, t) ->
    PadsListHelper.moveFocusToBodyIfNecessary(e, t)



  'keyup .knote-title': (e, t) ->
    PadsListHelper.listenToTitleInput e, t
    KnoteHelper.togglePost(t, $(e.currentTarget).text())
    PadsListHelper.resetEditedContent()



  'paste .knote-title': PadsListHelper.listenToTitlePaste



  'paste .knote-body': AppHelper.pasteAsPlainTextEventHandler



  'click .post-button': (e, t) ->
    $postButton = $(e.currentTarget)
    $postButton.attr('disabled', true)
    subject = $("#header .subject").text()
    $newTitle = t.$(".knote-title")
    $newBody = t.$(".knote-body")
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
