Meteor.startup ->
  Tracker.autorun ->
    return unless loggedInLocally.get()
    Meteor.subscribe 'sharingData'
    #console.log '#eluck# subscribing sharing data'
