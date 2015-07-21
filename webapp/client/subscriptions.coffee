Meteor.startup ->
  Tracker.autorun ->
    return unless loggedInLocally.get()
    Meteor.subscribe 'sharingData'

  Tracker.autorun ->
    user = Contacts.findOne()
    if user
      $('title').text('Knoteup - ' + user.username)
