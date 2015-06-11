@QuickKnotesRank = new Mongo.Collection 'QuickKnotesRank'


QuickKnotesRank.allow
  insert: -> true
  update: -> true
  remove: -> true




if Meteor.isServer
  Meteor.publish 'QuickknotesRank', ->
    QuickKnotesRank.find()
