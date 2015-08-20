@CHAR_LIMITATION_IN_KNOTE_TITLE = 150



@PadsListHelper =
  storeEditedContent: (editKnote) ->
    amplify.store "knote", editKnote



  restoreEditedContent: ->
    storedKnote = amplify.store("knote")
    return if _.isEmpty storedKnote
    $(".new-knote-title").html(storedKnote.title)
    $(".new-knote-body").html(storedKnote.body).show() unless _.isEmpty(storedKnote.body)



  resetEditedContent: ->
    amplify.store 'knote', null



  getSortedKnotes: (padId) ->
    {
      unarchived: knotesRepository.find({topic_id: padId, archived: false}, {sort: {order: 1, timestamp: -1} }).fetch()
      archived: knotesRepository.find({topic_id: padId, archived: true, is_fake: $ne: true}, {sort: {order: 1, timestamp: -1} }).fetch()
    }



  listenToTitlePaste: (jQueryEvent, templateInstance) ->
    AppHelper.pasteAsPlainTextEventHandler(jQueryEvent)
    currentText = $(jQueryEvent.currentTarget).text()
    content = PadsListHelper.splitKnoteTitle(currentText)
    if content.bodyText
      body = templateInstance.find('.knote-body')
      PadsListHelper.insertContentIntoTitleAndBody(jQueryEvent.currentTarget, body, content)



  listenToTitleInput: (jQueryEvent, templateInstance) ->
    unless jQueryEvent.metaKey or jQueryEvent.ctrlKey
      titleText = $(jQueryEvent.currentTarget).text()
      content = PadsListHelper.splitKnoteTitle titleText
      if content.bodyText
        body = templateInstance.find('.new-knote-body, .knote-body')
        PadsListHelper.insertContentIntoTitleAndBody jQueryEvent.currentTarget, body, content



  splitKnoteTitle: (text) ->
    if _.size(text) > CHAR_LIMITATION_IN_KNOTE_TITLE
      result =
        titleText: text.substr(0, CHAR_LIMITATION_IN_KNOTE_TITLE)
        bodyText: text.substr(CHAR_LIMITATION_IN_KNOTE_TITLE)
    else
      result = titleText: text
    result



  insertContentIntoTitleAndBody: (titleElement, bodyElement, content) ->
    cursor = SelectionTextHelper.getSelectionData()
    $(titleElement).text(content.titleText)
    SelectionTextHelper.setCursorAt(cursor.pos, titleElement)
    if bodyElement
      $(bodyElement).prepend(content.bodyText).show()
      if cursor.pos > content.titleText.length
        $(bodyElement).focus()
        SelectionTextHelper.setCursorAt(content.bodyText.length, bodyElement)



  moveFocusToBodyIfNecessary: (jQueryEvent, templateInstance) ->
    return if (jQueryEvent.shiftKey or jQueryEvent.ctrlKey) and jQueryEvent.keyCode is 13
    if jQueryEvent.keyCode is 13 or jQueryEvent.keyCode is 10
      jQueryEvent.preventDefault()
      text = $(jQueryEvent.currentTarget).text()
      templateInstance.$('.new-knote-body, .knote-body').removeClass('hidden').show().focus() unless _.isEmpty(text)
      return false



  getNewKnoteOrder: () =>
    messages = $('.latest-knotes .knote')
    if messages.length
      messages.sort (message1, message2) ->
        return $(message1).data('order') - $(message2).data('order')
      $(messages[0]).data('order') - 1
    else
      -1


  leftSideMessage: (template, type) ->
    return if !template.knotes
    unarchived = template.knotes.unarchived.length
    archived = template.knotes.archived.length
    total = unarchived + archived
    half = total / 2
    if total == 1
      text = "That's a start"
      image = "one"
    if total > 1
      text = "Yawn. Too easy."
      image = "more-one"
    if total > 3
      text = "Not bad."
      image = "more-three"
      if total > 5
        text = "Let's get cracking!"
        image = "more-five"
      if total > 8
        text = "Wow. Busy!"
        image = "more-eight"
      if archived >= half
        text = "In the zone."
        image = "half"
      if archived == (total - 1)
        text = "So...close."
        image = "one-more"
      if total > 3 and unarchived == 0
        text = "Great job!"
        image = "success"
    if moment().endOf('day').fromNow() < 8 && unarchived > 3
      text = "Its getting late!"
      image = "sleepy"
    if type == "image"
      return image
    if type == "text"
      return text



  initKnoteDraggable: ->
    options =
      items: '.knote'
      cancel: '.in-edit'
      cursorAt:
        top: 0
        left: 0
      scrollSensitivity: 100
      handle: '.knote-header'
      placeholder: 'knote-placeholder'
      forcePlaceholderSize: true
      helper: 'clone'
      appendTo: '.pad'
      update: (e, ui) ->
        PadsListHelper.updateOrder(ui.item)
        #TopicsHelper.trackKnoteDraggingEvent(entityId)
      start: (e, ui) ->
        ui.item.addClass('sorting')
        Session.set('isKnoteDroppabe', true)
      stop: (e, ui) ->
        ui.item.removeClass('sorting')
        Session.set('isKnoteDroppabe', false)

    $container = $(".unarchived-knotes")
    $container
      .sortable(options)



  updateOrder: (card) ->
    knote = Knotes.findOne card.data('id')
    $messages = card.parents('.unarchived-knotes').find('.knote')
    cards = _.map $messages, (ele)-> id: $(ele).data('id'), collection: 'knotes'
    PadsListHelper.updateOrderForManualSortEx(knote.topic_id, cards, knote._id)



  updateOrderForManualSortEx: (topic_id, cards, targetId, container = 'main') ->
    topic = Pads.findOne topic_id
    throw new Meteor.Error 500, "Topic not exist with " + topic_id  unless topic?
    return if cards.length is 0
    order = -cards.length
    _.each cards, (c)->
      updateOption =
        order: order++
      if c.id is targetId
        updateOption.containerName = container
      switch c.collection
        when 'knotes'
          Knotes.update({_id: c.id}, {$set: updateOption})
        when 'date_events'
          DateEvents.update({_id: c.id}, {$set: updateOption})



  getTextFromHtml: (html) ->
    $('<div>').append(html).text()
