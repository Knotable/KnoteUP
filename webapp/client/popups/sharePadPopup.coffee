class @SharePadPopup
  @id = '#share-pad-popup'
  @parent = 'body'
  @activeInstance = null


  constructor: (data = {}) ->
    return false unless data.padId
    removeInstanceIfExists $ SharePadPopup.id
    data.SharePadPopup = @
    if data.shareLink
      data.url = UrlHelper.getPadUrlFromId data.padId
    UI.renderWithData Template.sharePadPopup, data, $(SharePadPopup.parent)[0]
    SharePadPopup.activeInstance = @
    @$popup = $ SharePadPopup.id


  removeInstanceIfExists = ($popup) ->
    $popup.remove() if $popup.length
    SharePadPopup.activeInstance = null


  show: ->
    @$popup.lightbox_me
      centered: true


  close: ->
    @$popup.trigger 'close'


showPlaceholder = AppHelper.makeExplicitlyReactiveFunction(true)


Template.sharePadPopup.helpers
  copySupported: ->
    !document.queryCommandSupported?('copy')


  url: ->
    UrlHelper.getPadUrlFromId @padId


  selectedContacts: (e)->
    user = UserAccounts.findOne({user_ids: Meteor.userId()})
    if user
      my_emails = UsersHelper.userEmails()
      topic = Pads.findOne($('#share-pad-popup').data('pad-id'))
      # exclude emails which has already exists in thread
      emails = AppHelper.getParticipatorEmails(topic)
      emails.concat my_emails
      availableContacts = UsersHelper.getContactsInSeq()
      selectedEmails = EJSON.parse(Session.get("SelectedContactsInThreadPopupList") || '[]')
      return [] if not selectedEmails.length
      aContacts = _.clone availableContacts
      availableContacts = _.map selectedEmails, (email)->
         contact = _.find aContacts, (c)-> c.emails[0] is email
         return contact or {email: email}
      return availableContacts
    else
      [] # Guest use
    

  showPlaceholder: ->
    selectedEmails = EJSON.parse(Session.get('SelectedContactsInThreadPopupList') || '[]')
    selectedEmails.length is 0 and showPlaceholder.reactiveGet()



Template.sharePadPopup.onRendered ->
  showPlaceholder(true)
  
  @find('.shared-url')?.select()

  ZeroClipboard.prototype._singleton = null
  ZeroClipboard.setDefaults( { moviePath: '/swf/ZeroClipboard.swf' } )
  clip = new ZeroClipboard()
  clip.glue($(@findAll '.icon-docs'))
  $shareUrl = $(@findAll ".shared-url")
  clip.on "dataRequested", (client, args) ->
    $shareUrl.select()
    client.setText $shareUrl.val()
    $shareUrl.parent().prepend("<span class='copied'>#{$shareUrl.val()}</span>")
    $shareUrl.parent().find('.copied').animate
      opacity: 0
      top: -10
    , 500 , ->
      $(this).remove()


Template.sharePadPopup.events
  'click #shareEmails': (e)->
    $newEmail = $(e.currentTarget).find('#NewEmail')
    $newEmail.focus()
    showPlaceholder(false)


  'click .btn-cancel-share': ->
    SharePadPopup.activeInstance.close()

  'click .shared-url': (e) ->
    e.currentTarget.select()

  'click .btn-share': (e, template) ->
    message = template.$('.share-message').val()
    emails = EJSON.parse(Session.get('SelectedContactsInThreadPopupList') || '[]')
    newEmail = template.$('#NewEmail').val()

    if not _.isEmpty(newEmail) and not AppHelper.isCorrectEmail(newEmail)
      return showWarningMessage 'Please enter valid email address'

    unless emails.length > 0
      return showWarningMessage 'Please enter email address'

    Meteor.remoteConnection.call 'addContactsToThread', template.data.padId, emails, {message: message}, (error, result) ->
      if error
        showWarningMessage 'Add contact to pad failed. Please try again later.'
        console.log 'ERROR: addContactsToThread', error
      else
        SharePadPopup.activeInstance.close()
        showSuccessMessage 'Shared in Knotable.'



Template.search_contacts.rendered = ->
  Session.set("queryContactInAddUserToThraedPopup", '')
  $input = $(@find 'input.newEmail')
  addEmailToSelect = (email) ->
    if AppHelper.isCorrectEmail(email)
      selectedEmails = EJSON.parse(Session.get('SelectedContactsInThreadPopupList') || '[]')
      selectedEmails = _.union(selectedEmails, [email])
      Session.set('SelectedContactsInThreadPopupList', EJSON.stringify(selectedEmails))
      showPlaceholder(true)
      Session.set("queryContactInAddUserToThraedPopup", '')
      $input.val('')

  Meteor.typeahead($input)
  $input.on 'typeahead:selected', (ev, suggestion) ->
    addEmailToSelect(suggestion.value)

  ###
  $input.on 'typeahead:opened', () ->
    dropdown = $input.siblings('.tt-dropdown-menu')
    oauthBtn = dropdown.find '.show-gmail-oauth'
    if Meteor.user()?.services?.google
      oauthBtn.remove() if oauthBtn.length
    else if oauthBtn.length is 0
      $('<div class="show-gmail-oauth">Add your gmail contacts</div>')
        .appendTo(dropdown)
        .on 'click', addGoogleOauth
  ###

  $input.on 'blur', ->
    unless Session.get("queryContactInAddUserToThraedPopup")
      $(this).val('')
      return showPlaceholder(true)
    addEmailToSelect($input.val())

  $input.on 'keydown', (e) ->
    if e.keyCode is 13 or e.keyCode is 32 or e.keyCode is 188
      addEmailToSelect($input.val())
      return false
    else
      return true

  $input.on 'keyup', (e) ->
    $input.autosizeInput()
    Session.set("queryContactInAddUserToThraedPopup", $input.val())

  $input.on 'paste', (e) ->
    Meteor.defer ->
      emails = $.trim($input.val()).split(/\s+/)
      _.each emails, (email) ->
        addEmailToSelect email


Template.search_contacts.__helpers.set "searchContacts", (query, callback)->
    lastEmailPattern = query
    my_emails = UsersHelper.userEmails()
    topic = Pads.findOne($('#share-pad-popup').data('pad-id'))
    # exclude emails which has already exists in thread
    emails = AppHelper.getParticipatorEmails(topic)
    emails.concat my_emails
    selectedEmails = EJSON.parse(Session.get("SelectedContactsInThreadPopupList") || '[]')
    emails = _.union emails, selectedEmails
    callbackHandler = (contacts) =>
      callback _.reject contacts, (c) -> _.contains emails, c.email
    AppHelper.loadSuggestContacts lastEmailPattern, callbackHandler



Template.contactTab.events
  'click .icon-cancel': (e)->
    $selector = $(e.currentTarget).closest('.contact-item')
    email = $selector.attr('data-email')
    selectedEmails = EJSON.parse(Session.get('SelectedContactsInThreadPopupList') || '[]')
    selectedEmails = _.without(selectedEmails, email)
    Session.set('SelectedContactsInThreadPopupList', EJSON.stringify(selectedEmails))
    false



Template.contactTab.helpers
  email: ->
    @emails?[0]?.toLowerCase() or @email?.toLowerCase()
