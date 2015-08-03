Meteor.startup ->
  Tracker.autorun ->
    user = AppHelper.currentContact()
    return unless user
    $('title').text('Knoteup - ' + user.username)
