Meteor.settings.public.remoteHost ?= 'beta.knotable.com'

remoteServerUrl = Meteor.settings.public.remoteHost
Meteor.remoteConnection = DDP.connect(remoteServerUrl)
Accounts.connection = Meteor.remoteConnection


Meteor.users = new Mongo.Collection 'users', connection: Meteor.remoteConnection



@UserAccounts = new Meteor.Collection "user_accounts", connection: Meteor.remoteConnection



@Pads = new Meteor.Collection "topics", connection: Meteor.remoteConnection



@Knotes = new Meteor.Collection "knotes",
  connection: Meteor.remoteConnection
  transform: (knote) ->
    if knote.timestamp
      nowDate = moment()
      knoteDate = moment(knote.timestamp)
      if nowDate.year() isnt knoteDate.year()
        format = 'MMM DD, YYYY [at] ha'
        formatedDate = knoteDate.format(format)
      if nowDate.isSame(knoteDate, 'day')
        formatedDate = knoteDate.format('[today at] ha')
      formatedDate ?= knoteDate.format('MMM DD [at] ha')
      knote.formatedDate = formatedDate || ''

    knote.from = knote.from.address if knote.from and _.isObject knote.from
    return knote




@Contacts = new Meteor.Collection "contacts",
  connection: Meteor.remoteConnection
  transform: (contact) ->
    contact.hasAvatar = if contact.avatar
      true
    else
      false
    name = contact.nickname || contact.fullname || contact.username
    contact.initialName = name[0].toUpperCase()
    return contact
