@CHAR_LIMITATION_IN_KNOTE_TITLE = 150



@PadsListHelper =
  storeEditedContent: (editKnote) ->
    amplify.store "knote", editKnote



  restoreEditedContent: ->
    storedKnote = amplify.store("knote")
    return if _.isEmpty storedKnote
    $(".new-knote-title").val(storedKnote.title)
    $(".new-knote-body").html(storedKnote.body)



  resetEditedContent: ->
    amplify.store 'knote', null



  getSortedKnotes: (padId) ->
    {
      unarchived: Knotes.find({topic_id: padId, archived: false}, {sort: {order: 1, timestamp: -1} }).fetch()
      archived: Knotes.find({topic_id: padId, archived: true}, {sort: {order: 1, timestamp: -1} }).fetch()
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
    return false if jQueryEvent.shiftKey and jQueryEvent.keyCode is 13
    if jQueryEvent.keyCode is 13 or jQueryEvent.keyCode is 10
      jQueryEvent.preventDefault()
      text = $(jQueryEvent.currentTarget).text()
      templateInstance.$('.new-knote-body,.knote-body').show().focus() unless _.isEmpty(text)
      return false



  getNewKnoteOrder: () =>
    messages = $('.latest-knotes .knote')
    if messages.length
      messages.sort (message1, message2) ->
        return $(message1).data('order') - $(message2).data('order')
      $(messages[0]).data('order') - 1
    else
      -1



  initKnoteDraggable: ->
    options =
      items: '.knote'
      cancel: '.in-edit'
      cursorAt:
        top: 0
        left: -300
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
