@HIGHLIGHTER_ACTIONS =
  ACTION_QUOTE: "QUOTE"
  ACTION_ANNOTATE: "ANNOTATE"
  ACTION_HIGHLIGHT: "HIGHLIGHT"


@HighLighter =
  cssApplier: undefined
  boldApplier: undefined
  italicApplier: undefined
  popMenu: undefined


  init: ->
    try
      window.rangy.init() unless window.rangy.initialized

      unless @cssApplier
        @cssApplier = window.rangy.createCssClassApplier "highlight",
          tagNames: ["span"]

      unless @boldApplier
        @boldApplier = window.rangy.createCssClassApplier "bold",
          tagNames: ["span"]

      unless @italicApplier
        @italicApplier = window.rangy.createCssClassApplier "italic",
          tagNames: ["span"]

    catch e
      console.log "Highligher init error: ", e



  togglePopupHighlightMenu: (e) ->
    if @hasSelection()
      $menu = $('#sel-text-menu')
      @popupHighlightContextMenu e, $menu, ->
        $menu.data 'status', 'open'



  hasSelection: ->
    selection = window.getSelection().toString()
    if selection.length > 0
      return true
    else
      return false



  popupHighlightContextMenu: (e, menu, openFinishedCallback = null) ->
    #return if activePreviousDraftComment()
    @toggleHighlightText e, menu, rangy
    menu.fadeIn('fast')
    @updatePopupPosition menu, e
    if openFinishedCallback != null
      openFinishedCallback()



  toggleHighlightText: (e, menu, rangy) ->
    window.currentHighlightElement = e.currentTarget
    if HighLighter.cssApplier.isAppliedToSelection()
      $('[data-menu="unhighlight"]', menu).show()
      $('[data-menu="highlight"]', menu).hide()
    else
      $('[data-menu="unhighlight"]', menu).hide()
      $('[data-menu="highlight"]', menu).show()
      selHtml = rangy.getSelection().toHtml()
      if selHtml.indexOf('highlight') >= 0
        $('[data-menu="unhighlight"]', menu).show()



  updatePopupPosition: (menu, e) ->
    pos = @getHighlightPopPos(menu, e)
    menu.css(
      left: pos.left
      top: pos.top
    )



  getHighlightPopPos: (menu, e) ->
    halfMenuWidth = 80
    headerHeight = 110
    boundary = window.getSelection().getRangeAt(0).getBoundingClientRect()
    padsContainer = $('.padList')
    pos = {}
    pos.top = boundary.top + padsContainer.scrollTop() - headerHeight
    pos.left = boundary.right - halfMenuWidth
    return pos



  applyToSelection: (e) ->
    @cssApplier.applyToSelection() unless @cssApplier.isAppliedToSelection()
    #_sel = @saveTOKeyNote window.rangy.getSelection()
    _sel = window.rangy.getSelection()
    _sel.removeAllRanges()
    #HighLighter.triggerToUpdateMessage()



  applyBoldToSelection: (e) ->
    @boldApplier.applyToSelection() unless @boldApplier.isAppliedToSelection()
    _sel = window.rangy.getSelection()
    _sel.removeAllRanges()



  applyItalicToSelection: (e) ->
    @italicApplier.applyToSelection() unless @italicApplier.isAppliedToSelection()
    _sel = window.rangy.getSelection()
    _sel.removeAllRanges()



  undoToSelection: (e) ->
    note = window.rangy.getSelection().toString()
    @cssApplier.undoToSelection()
    $(window.currentHighlightElement).focusout()
    window.rangy.getSelection().removeAllRanges()
    #HighLighter.triggerToUpdateMessage()



  clearFormatToSelection: (e) ->
    note = window.rangy.getSelection().toString()
    @cssApplier.undoToSelection()
    @boldApplier.undoToSelection()
    @italicApplier.undoToSelection()


  # Get text selected and new card for them
  clipSelection: (e) ->
    _sel = @saveAsNewKnote window.rangy.getSelection(), ->
      # the new clip knote may not be shown now,
      # but we can scroll to the bottom of the keynote directly
      keynote = $('#popup-container .key-note-container')
      if keynote.length
        $('.thread').scrollTop keynote.height()
      else
        $('.thread').scrollTop 0

    _sel.removeAllRanges()
    $(window.currentHighlightElement).focusout()



  # Get text selected and split to 2 new cards
  splitSelection: (e) ->
    HighLighter.saveNewKnoteBySpliting()



  saveAsNewKnote: (selection, afterSaveSuccess) ->
    dateCreated = new Date()
    note = selection.toHtml().replace(/data-comments=[\"']\S*[\"']/g,"")
    note = '<div class="quote-text"><i class="fa fa-quote-left" title="This was quoted from another card"></i><div>...' + note + '...</div></div><span class="quote-end">&nbsp;</span><span></span>'
    oldKnoteId = KnoteBaseModel.getActive()?._id
    Meteor.call 'add_knote_by_clipping', oldKnoteId, note, dateCreated.toString(), (err, knoteId) ->
      if err
        console.log 'create clipping knote failed'
      else
        Meteor.defer ->
          KnotableAnalytics.trackEvent eventName: KnotableAnalytics.events.knoteQuoted, relevantPadId: TopicsHelper.currentTopicId(), knoteId: knoteId, oldKnoteId: oldKnoteId
      afterSaveSuccess?()
    return selection



  buildHighlight: (highlight_text) ->
    highlight = null
    knoteId = KnoteBaseModel.getActive()?._id
    knote = Knotes.findOne({_id : knoteId})
    if knote
      highlight = {original_knote_id : knoteId, type: knote.type, highlight_text : highlight_text.trim()}
    return highlight



  getSelectionHtml: ->
    html = ""
    unless typeof window.getSelection is "undefined"
      sel = window.getSelection()
      if sel.rangeCount
        container = document.createElement("div")
        i = 0
        len = sel.rangeCount

        while i < len
          container.appendChild sel.getRangeAt(i).cloneContents()
          ++i
        html = container.innerHTML
    else html = document.selection.createRange().htmlText  if document.selection.type is "Text"  unless typeof document.selection is "undefined"
    return html



  saveNewKnoteBySpliting : ->
    knoteId = KnoteBaseModel.getActive()?._id
    return  unless knoteId
    $container = $("div.message[data-id=\"" + knoteId + "\"]").find("div.knote-content")
    messages = HighLighter.splitHTML($container)
    if messages.length is 2
      dateCreated = new Date()
      i = 1
      while i >= 0
        newMessage = messages[i]
        $textArea = $(newMessage)
        contentHelper.convertLinksToText($textArea)
        if $textArea.hasClass('knote-body')
          newMessage = $textArea.html()
        #console.log "i: " + i
        #console.log "i: " + newMessage
        i--
        #Save new message with originalMessageId, originalType
        Meteor.call 'add_knote_by_splitting', KnoteBaseModel.getActive()?._id, newMessage, dateCreated.toString()
      #Update current message to isSplited
      Meteor.call 'update_original_message_after_splitting', KnoteBaseModel.getActive()?._id



  splitHTML : ($container) ->
    messages = new Array()
    selection = window.getSelection()
    return messages  unless selection
    return messages  if selection.rangeCount is 0
    selectedRange = selection.getRangeAt(0)
    return messages  unless selectedRange
    selectedText = selection.toString()
    isBeginText = $container.text().trim().indexOf(selectedText) is 0
    startContainer = selectedRange.startContainer
    startOffset = selectedRange.startOffset
    endContainer = selectedRange.endContainer
    endOffset = selectedRange.endOffset
    firstMessage = undefined
    secondMessage = undefined

    # If the start container is first child of $container, we will split by endContaner
    if isBeginText
      firstMessage = HighLighter.getSelectionHtml()

      range = document.createRange()
      range.selectNodeContents $container[0]
      range.setStart endContainer, endOffset
      selection = window.getSelection()
      selection.removeAllRanges()
      selection.addRange range
      secondMessage = HighLighter.getSelectionHtml()
    else
      range = document.createRange()
      range.selectNodeContents $container[0]
      range.setStart $container.find(":first-child")[0], 0
      range.setEnd startContainer, startOffset
      selection = window.getSelection()
      selection.removeAllRanges()
      selection.addRange range
      firstMessage = HighLighter.getSelectionHtml()
      range = document.createRange()
      range.selectNodeContents $container[0]
      range.setStart startContainer, startOffset
      selection = window.getSelection()
      selection.removeAllRanges()
      selection.addRange range
      secondMessage = HighLighter.getSelectionHtml()

    selection.removeAllRanges()
    messages.push firstMessage  if firstMessage and $.trim(firstMessage) isnt ""
    messages.push secondMessage  if secondMessage and $.trim(secondMessage) isnt ""
    messages



  triggerToUpdateMessage: ->
    knote = KnoteBaseModel.getActive()
    return unless knote
    $('span.highlight').attr("contenteditable","false")
    controller = KnoteController.getController knote._id
    if controller
      template = controller.template
      controller.save($editor: template.getEditor(), fileIds: template.getFileIds())
      controller.isEditing on
