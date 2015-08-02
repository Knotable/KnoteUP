Meteor.startup ->
  Tracker.autorun ->
    return unless loggedInLocally.get()
    Meteor.subscribe 'sharingData'

  Tracker.autorun ->
    user = AppHelper.currentContact()
    if user
      $('title').text('Knoteup - ' + user.username)
