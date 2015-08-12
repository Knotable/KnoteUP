@UsersHelper =
  getUserEmail: (user) ->
    user = Meteor.user() unless user
    return unless user
    user.emails?[0]?.address || user.services?.google?.email || user.services?.github?.email


  
  getContactsInSeq: (account = null) ->
    UsersHelper.getSortedContactsCursor(account).fetch()



  getSortedContactsCursor: (account = null) ->
    account = AppHelper.currentAccount() unless account
    return unless account?._id
    myEmails = Meteor.users.find({_id: {$in: account.user_ids}}).map (user) -> UsersHelper.getUserEmail user
    myEmails = _.chain(myEmails).compact().uniq().value()
    excludedContactEmails = EXAMPLE_CONTACTS.concat myEmails
    sortedContactsCursor = Contacts.find({
      account_id: account._id
      type: 'other'
      emails: {$nin: excludedContactEmails}
      position: {$exists: 1}
      deleted: {$ne: 'deleted'}
      is_account_deleted: {$ne: true}
      removed: {$ne: 'removed'}
    }, {
      sort:
        position: -1
        total_topics: -1
        fullname: 1
    })
    contactsHasPos = sortedContactsCursor.fetch()
    contactsNoPos = Contacts.find({
      account_id: account._id
      type: 'other'
      emails: {$nin: excludedContactEmails}
      position: {$exists: 0}
      deleted: {$ne: 'deleted'}
      is_account_deleted: {$ne: true}
    }, {
      sort:
        fullname: 1
        total_topics: -1
    }).fetch()

    contactsHasPos = _.filter contactsHasPos, (c) ->
      if _.isNumber c.position
        return true
      else
        contactsNoPos.unshift c
        return false

    # fix contacts' position field
    if contactsNoPos.length
      if contactsHasPos.length
        nextPos = contactsHasPos[contactsHasPos.length - 1].position - 1
      else
        nextPos = contactsNoPos.length
      _.each contactsNoPos, (c) ->
        c.position = nextPos
        Contacts.update({_id: c._id},{$set : {position: nextPos}})
        nextPos--

    sortedContactsCursor


  # include regiester email address and google oauth email address
  userEmails: ->
    loginedAccount = UserAccounts.findOne({'user_ids': Meteor.userId()})
    return [] unless loginedAccount
    emails = Meteor.users.find({_id: {$in: loginedAccount.user_ids}}).map (user) ->
      user.emails?[0].address || user.services?.google?.email
    emailsInContact = AppHelper.currentContact()?.emails;
    _.each emailsInContact, (e) ->
      emails.push e
    _.uniq emails
