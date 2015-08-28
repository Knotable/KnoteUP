Template.header.onRendered ->
  @data.subject = moment().format "MMM Do"
  if Meteor.isCordova
    $('#header').css('padding-top', '10px')



Template.header.helpers
  currentContact: ->
    AppHelper.currentContact()



  contentEditableSubject: ->
    subject = PadsListHelper.todaySubject()
    attrs = [
      "class='subject'"
    ]
    html = "<div #{attrs.join(' ')}>#{subject}</div>"
    return new Spacebars.SafeString html



Template.header.events
  'click .user': (e) ->
    $('#setting-dropdown').slideToggle()



  'click .show-compose': ->
    $(".padList").animate {scrollTop: 0}, 600
    $('.compose .knote-title').focus()



  'click .logout': ->
    logout()



  'click .login-button': (event, template) ->
    return if Meteor.userId()
    title = $(".compose .knote-title").html()
    body = $(".compose .knote-body").html()
    editKnote =
      title: title
      body: body
    PadsListHelper.storeEditedContent editKnote
    Session.set 'modal', 'login'



Template.share_dropdown.onRendered ->
  sharePadBtn = $(@find '.share-pad')
  isTopHeader = sharePadBtn.parents('#header').length
  if isTopHeader
    if @data._id
      $('#header .redirect-to-knotable').attr 'href', UrlHelper.getPadUrlFromId(@data._id)
    else
      sharePadBtn.hide()



Template.share_dropdown.helpers
  unconfirmed: ->
    return !UsersHelper.isUserEmailConfirmed(Meteor.user())



Template.share_dropdown.events
  'click .share-pad-btn': (e) ->
    btn = $(e.currentTarget)
    if UsersHelper.isUserEmailConfirmed(Meteor.user())
      btn.siblings('.share-pad-dropdown').slideToggle()
    else
      showWarningMessage 'Please confirm your email to use this feature.',
        duration: -1
        showOk: true
        showConfirm: true


  'click .share-invite': (e) ->
    padId = $(e.currentTarget).parents('.share-pad').attr('data-id')
    new SharePadPopup({shareLink: true, padId: padId}).show()



  'click .share-slack': (e) ->
    topicId = $(e.currentTarget).parents('.share-pad').attr('data-id')
    pad = Pads.findOne _id: topicId
    padUrl = UrlHelper.getPadUrlFromId topicId
    knotes = Knotes.find(topic_id: topicId, archived: $ne: true).fetch()
    getKnoteFilesList = (knote) ->
      $knote = $('.knote[data-id="' + knote._id + '"]')
      $files = $knote.find('a[file_id]')
      $titles = $files.map (index, file) -> $(file).attr('title')
      $titles.get().join ', ' or 'knote'
    text = ''
    for knote, i in knotes
      text += (i+1) + '. ' + if knote.title then knote.title + '\n' else getKnoteFilesList(knote) + '\n'
    new SharePopup(
      authorName: pad.subject
      authorLink: padUrl
      title: ''
      text: text
      textLink: '<' + padUrl + '|track my progress>'
    ).show()
