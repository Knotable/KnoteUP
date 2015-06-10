Router.route '/(.*)',
  name: 'pads'
  template: 'padsList'
  data: ->
    option = sort: created_time: -1

    latestPad = Pads.findOne {}, option
    dateOfLatestPad = latestPad?.created_time
    if dateOfLatestPad
      isToday = moment().isSame(moment(dateOfLatestPad), 'day')
      if isToday
        option.skip = 1
        latestPad.knotes = Knotes.find topic_id: latestPad._id,
          sort: archived: 1, order: 1
      else
        latestPad = null

    pads = Pads.find {}, option

    return {
      latestPad: latestPad
      restPads: pads
    }

  waitOn: ->
    if Meteor.userId()
      Meteor.remoteConnection.subscribe 'topicsBySource', 'quick'
      Meteor.remoteConnection.subscribe 'userAccount'
