Template.knote.onRendered ->
  template = @
  knote = @data
  knoteId = @data._id
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

  'mouseenter .knote': (e, template) ->
    $(e.currentTarget).find('.knote-date').show()
    template.$(".knote-actions").removeClass("invisible")


  'mouseleave .knote': (e, template) ->
    $(e.currentTarget).find('.knote-date').hide()
    console.log(template.$(".knote-body").prop('contenteditable'))
    unless template.$(".buttons").is(':visible') or template.data.archived
      template.$(".knote-actions").addClass("invisible")


  'click i.archive': (e, template) ->
    knoteId = template.data._id
    topicId = template.data.topic_id
    Knotes.update knoteId, $set: archived: true


  'click i.restore': (e, template) ->
    knoteId = template.data._id
    topicId = template.data.topic_id
    Knotes.update knoteId, $set: archived: false


  'click i.edit-knote': (e, template) ->
    template.$('.buttons').removeClass("hidden")
    template.$(".knote-actions").removeClass("invisible")
    template.$(".knote-title").prop('contenteditable', true).focus()
    template.$('.knote').addClass 'in-edit'
    template.$(".knote-body").prop('contenteditable', true)


  'click i.share-knote': (e, template) ->
    e.stopPropagation()
    knoteId = template.data._id
    topicId = template.data.topic_id
    title = template.$(".knote-title").val()
    text = template.$(".knote-body").text()
    new SharePopup(
      knoteId: knoteId
      title: title
      text: text
    ).show()


  'click .btn-cancel': (e, template) ->
    template.$(".buttons").addClass("hidden")
    template.$(".knote-actions").addClass("invisible")
    template.$(".knote-title").prop('contenteditable', false).html(@title or '')
    template.$(".knote-body").prop('contenteditable', false).html(@htmlBody or @body or '')
    template.$('.knote').removeClass 'in-edit'


  "click .btn-save": (e, template) ->
    template.$(".buttons").addClass("hidden")
    template.$(".knote-actions").addClass("invisible")
    template.$('.knote').removeClass 'in-edit'

    $title = template.$(".knote-title")
    title =$title.html()
    $title.prop('contenteditable', false)

    $body = template.$(".knote-body")
    body = $body.html()
    $body.prop('contenteditable', false)

    knoteId = template.data._id

    knoteTitle = template.data.title
    knoteBody = template.data.htmlBody
    if title isnt knoteTitle or body isnt knoteBody
      KnoteHelper.formatAndSave(template)


  'keydown .knote-title': (event, template) ->
    PadsListHelper.moveFocusToBodyIfNecessary(event, template)


  'keyup .knote-title': (event, template) ->
    PadsListHelper.listenToTitleInput event, template


  'click .icon-chat': (e) ->
    knote = $(e.currentTarget).closest('.knote')
    composePopup = knote.find('.knote-compose-popup-cn')
    composePopup.slideToggle()
    setTimeout ->
      composePopup.find('.reply-message-textarea').focus()
    , 500


  'dblclick .knote-body,.knote-title': (e, t) ->
    t.$('.edit-knote').click()


  'mouseup .knote-body, mouseup .knote-title': (e) ->
    if $(e.currentTarget).parents('.knote').hasClass('in-edit') and HighLighter.hasSelection()
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


  contenteditableBody: ->
    body = @htmlBody or @body or ''
    "<div class='knote-body compose-area file-container highlight-color-link-color message_text'>#{body}</div>"



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
