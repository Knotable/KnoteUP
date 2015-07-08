Meteor.publish 'sharingData', ->
  console.log 'sharingData userId:', @userId
  return unless @userId
  userCursor = Meteor.users.find @userId
  userHandle = userCursor.observe
    added: (doc) =>
#      console.log 'added doc:', doc
      keys = _.pick doc?.services or {}, 'slack'
      keys._id = doc._id
      @added 'sharing_keys', doc._id, keys
    changed: (doc) =>
      keys = _.pick doc?.services or {}, 'slack'
      keys._id = doc._id
      @changed 'sharing_keys', doc._id, keys
    removed: (doc) =>
      @removed 'sharing_keys', doc._id
  @onStop -> userHandle.stop()
  @ready()
