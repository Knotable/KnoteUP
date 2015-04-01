Router.route '/', ->
  this.render('knotePad')

Router.route '/p/:padId',
  name: 'knotePad'
  template: 'knotePad'
  data: ->
    padId = @params.padId
    knoteQuery = topic_id: padId
    knoteOption = {sort: order: 1}
    return {
      pad: Pads.findOne padId || {}
      knotes: Knotes.find knoteQuery, knoteOption
    }
  waitOn: ->
    Meteor.remoteConnection.subscribe 'topic', @params.padId
    Meteor.remoteConnection.subscribe 'allRestKnotesByTopicId', @params.padId
    Meteor.remoteConnection.subscribe 'userAccount'
