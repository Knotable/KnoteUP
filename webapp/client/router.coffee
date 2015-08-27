activateUserFilter = ->
  params = @params
  document.title = 'Activation'

  knotableConnection.call 'confirm_email', params.user_id, (err, result) ->
    if err
      console.log err
    Router.go '/'




Router.configure
  loadingTemplate: 'loading'
  layoutTemplate: 'layout'



Router.map ->
  @route "activateToken",
    path: '/activate/:user_id/:token'
    template: 'pad_list'
    onBeforeAction: [ activateUserFilter ]



  @route 'pads',
    path: '/(.*)'
    template: 'pad_list'
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
