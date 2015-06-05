Template.knote.events


  'mouseenter .knote': (e) ->
    $(e.currentTarget).find('.knote-date').show()



  'mouseleave .knote': (e) ->
    $(e.currentTarget).find('.knote-date').hide()


Template.knote.helpers
  contact: ->
    Contacts.findOne({emails: @from})




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
