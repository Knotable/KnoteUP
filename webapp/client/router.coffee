Router.configure
  loadingTemplate: 'loading'

Router.route '/(.*)',
  name: 'pads'
  template: 'padsList'
  layoutTemplate: 'layout'
  data: ->
    S3Credentials.requestCredentials()

    option = sort: created_time: -1

    latestPad = Pads.findOne {}, option
    dateOfLatestPad = latestPad?.created_time
    if dateOfLatestPad
      isToday = moment().isSame(moment(dateOfLatestPad), 'day')
      if isToday
        option.skip = 1
        latestPad.knotes = PadsListHelper.getSortedKnotes latestPad._id
      else
        latestPad = null

    pads = Pads.find {}, option

    return {
      latestPad: latestPad or {}
      restPads: pads
    }

  waitOn: ->
    if Meteor.userId()
      [
        Meteor.remoteConnection.subscribe 'topicsBySource', 'quick'
        Meteor.remoteConnection.subscribe 'userAccount'
        Meteor.remoteConnection.subscribe 'contactById'
      ]
