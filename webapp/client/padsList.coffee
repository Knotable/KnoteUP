hidePadShareDropdown = ->
  $('.share-pad-dropdown:visible').slideToggle()



todaySubject = ->
  user = AppHelper.currentContact()
  date = moment().format "MMM Do"
  if user
    user.username + '\'s Knoteup for ' + date
  else
    date



moveAnimationHooks =
  moveElement: (node, next) ->
    $node = $(node)
    $next = $(next)
    oldTop = $node.offset().top
    height = $node.outerHeight(true)

    # // find all the elements between next and node
    $inBetween = $next.nextUntil(node)
    if $inBetween.length is 0
      $inBetween = $node.nextUntil(next)
    # // now put node in place
    $node.insertBefore(next);
    # // measure new top
    newTop = $node.offset().top
    # // move node *back* to where it was before
    $node.removeClass('animate')
         .css('top', oldTop - newTop)
    # // push every other element down (or up) to put them back
    $inBetween.removeClass('animate')
              .css('top', oldTop < newTop ? height : -1 * height)
    # // force a redraw
    $node.offset()
    # // reset everything to 0, animated
    $node.addClass('animate').css('top', 0);
    $inBetween.addClass('animate').css('top', 0);



$(document).click ->
  $('#setting-dropdown:visible').slideToggle()
  hidePadShareDropdown()



Template.padsList.onRendered ->
  @data.subject = moment().format "MMM Do"

  $title = @$(".new-knote-title")
  PadsListHelper.restoreEditedContent()
  @$('.post-button').attr('disabled', false) if $title.text().length

  latestPad = @data.latestPad
  if latestPad
    $('#header .redirect-to-knotable').attr 'href', UrlHelper.getPadUrlFromId(latestPad._id)

  sharePadBtn = $('#header .share-pad')

  scrollAction = ->
    currentScroll = $('.padList').scrollTop()

    if currentScroll > 0
      $('#header').addClass('scrolling')
    else
      $('#header').removeClass('scrolling')

    if currentScroll > 180
      $('.show-compose').removeClass("invisible")
    else
      $('.show-compose').addClass("invisible")

    $currentPadItem = $('.padItem').filter( ->
      $pad = $(@)
      top = 80
      $pad.position().top < top
    ).last()

    if $currentPadItem.length
      subject = $currentPadItem.data('subject')
      id = $currentPadItem.data('id')
      sharePadBtn.show()
    else
      subject = todaySubject()
      id = $('#header .title').data('latest-id')
      unless id
        sharePadBtn.hide()
    $('#header .subject').text subject
    $('#header .share-pad').attr 'data-id', id
    $('#header .redirect-to-knotable').attr 'href', UrlHelper.getPadUrlFromId(id)

  @$('.padList').off('scroll').on 'scroll', _.throttle(scrollAction, 200)

  @find('.currentDatePad .knote-list')?._uihooks = moveAnimationHooks

  #unless mobileHelper.isMobile() or SettingsHelper.isReorderingCardsDisabled()
  unless window.isMobile
    PadsListHelper.initKnoteDraggable()
  $('#compose-popup').on 'keydown', KnoteHelper.processSavingOnCtrlEnterAction.bind(KnoteHelper, @$('.post-button'))



Template.padsList.helpers
  currentContact: ->
    AppHelper.currentContact()



  username: ->
    Meteor.user()?.username



  contentEditableSubject: ->
    subject = todaySubject()
    attrs = [
      "class='subject'"
    ]
    html = "<div #{attrs.join(' ')}>#{subject}</div>"
    return new Spacebars.SafeString html



  hasKnotableLoginToken: ->
    hasKnotableLoginToken.get()



  leftText: ->
    return PadsListHelper.leftSideMessage @, "text"



  leftImage: ->
    return PadsListHelper.leftSideMessage @, "image"



Template.padsList.events
  'mouseup #container' :(e)->
    elem = $(document)
    if elem.data('isHighLighting')
      elem.data('isHighLighting',false)
      ###
      HighLighter.init()
      HighLighter.togglePopupHighlightMenu(e)
      ###



  'click .user': (e) ->
    e.stopPropagation()
    hidePadShareDropdown()
    $('#setting-dropdown').slideToggle()



  'click #setting-dropdown': (e) ->
    e.stopPropagation()



  'click .show-compose': ->
    $(".padList").animate {scrollTop: 0}, 600
    $('.new-knote-title').focus()



  'click .logout': ->
    logout()



  'click .login-button': (event, template) ->
    return if Meteor.userId()
    title = template.$(".new-knote-title").html()
    body = template.$(".new-knote-body").html()
    editKnote =
      title: title
      body: body
    PadsListHelper.storeEditedContent editKnote
    Session.set 'modal', 'login'



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



  'click #sel-text-menu button': ->
    return false



  'mousedown #sel-text-menu button': (e) ->
    #keep menu opened after first click on buttons
    $selTextMenu = $(e.currentTarget).closest('div')
    status = $selTextMenu.data('status')
    if status == "trigger"
      $selTextMenu.data('status', "")
      $selTextMenu.fadeOut "fast"
      return false
    $selTextMenu.data('status', "trigger")

    command = $(e.currentTarget).data("menu")
    switch command
      when "bold"
        HighLighter.applyBoldToSelection(e)
      when "italic"
        HighLighter.applyItalicToSelection(e)
      when "highlight"
        HighLighter.applyToSelection(e)
      when "tx"
        HighLighter.clearFormatToSelection(e)
      else
        console.log "can't hold these."

    $selTextMenu.fadeOut "fast"
    return false



Template.padItem.helpers
  knotableLink: ->
    UrlHelper.getPadUrlFromId(@_id)



  knotes: ->
    PadsListHelper.getSortedKnotes @_id



Template.padItem.onRendered ->
  @find('.pad .knote-list')?._uihooks = moveAnimationHooks



Template.sharePadDropdown.onRendered ->
  sharePadBtn = $(@find '.share-pad')
  isTopHeader = sharePadBtn.parents('#header').length
  if isTopHeader
    if @data._id
      $('#header .redirect-to-knotable').attr 'href', UrlHelper.getPadUrlFromId(@data._id)
    else
      sharePadBtn.hide()



Template.sharePadDropdown.events
  'click .share-pad-btn': (e) ->
    e.stopPropagation()
    btn = $(e.currentTarget)
    btn.siblings('.share-pad-dropdown').slideToggle()



  'click .share-invite': (e) ->
    padId = $(e.currentTarget).parents('.share-pad').attr('data-id')
    new SharePadPopup({shareLink: true, padId: padId}).show()



  'click .share-slack': (e) ->
    topicId = $(e.currentTarget).parents('.share-pad').attr('data-id')
    pad = Pads.findOne _id: topicId
    padUrl = UrlHelper.getPadUrlFromId topicId
    knotes = Knotes.find(topic_id: topicId, archived: $ne: true).fetch()
    text = ''
    for knote, i in knotes
      text += (i+1) + '. ' + knote.title + '\n'
    new SharePopup(
      authorName: pad.subject
      authorLink: padUrl
      title: ''
      text: text
      textLink: '<' + padUrl + '|track my progress>'
    ).show()



Template.contentEditable.helpers
  attributes: ->
    unless _.has(@, 'contentEditable') or _.has(@, 'contenteditable')
      @['contentEditable'] = false
    return _.omit @, 'value'



  encodedValue: ->
    new Spacebars.SafeString(@value or "")
