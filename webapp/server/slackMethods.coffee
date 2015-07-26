Meteor.methods
  getMySlackCredentials: ->
    user = Meteor.user()
    return unless user
    return user.services?.slack
