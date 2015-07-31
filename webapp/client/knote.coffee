Template.knote.events

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
    PadsListHelper.setKnotesRankForPad topicId, knoteId, true
    Knotes.update knoteId, $set: archived: true


  'click i.restore': (e, template) ->
    knoteId = template.data._id
    topicId = template.data.topic_id
    PadsListHelper.setKnotesRankForPad topicId, knoteId, false
    Knotes.update knoteId, $set: archived: false


  'click i.edit-knote': (e, template) ->
    template.$('.buttons').removeClass("hidden")
    template.$(".knote-actions").removeClass("invisible")
    template.$(".knote-title").prop('contenteditable', true).focus()
    if template.$(".knote-body").text().length
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


  "click .btn-save": (e, template) ->
    template.$(".buttons").addClass("hidden")
    template.$(".knote-actions").addClass("invisible")

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
      updateOptions =
        $set:
          title: title
          htmlBody: body
      Knotes.update knoteId, updateOptions


  'keydown .knote-title': (event, template) ->
    PadsListHelper.moveFocusToBodyIfNecessary(event, template)


  'keyup .knote-title': (event, template) ->
    PadsListHelper.listenToTitleInput event, template



Template.knote.helpers
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
