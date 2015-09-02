

Template.pad_list.onRendered ->
  $knotes = $('.currentDatePad .knote')
  Session.set 'knotesNum', $knotes.length
  latestPad = @data.latestPad
  if latestPad
    $('#header .redirect-to-knotable').attr 'href', UrlHelper.getPadUrlFromId(latestPad._id)

  archivedKnotes = document.querySelectorAll('.archived-knotes')
  [].forEach.call(archivedKnotes, (knotes) ->
    knotes._uihooks =
      insertElement: (node, next) ->
        $(node).insertBefore(next)
        Deps.afterFlush(->
          knote = Knotes.findOne $(node).data('id')
          PadsListHelper.updateOrder(knote.topic_id)
        )
      removeElement: (node) ->
        topic_id = $(node).data('topicId')
        console.log($(node).data('archived'))
        $(node).remove()
        PadsListHelper.updateOrder(topic_id)
    )

  unless window.isMobile
    PadsListHelper.initKnoteDraggable()

  @$('.padList').off('scroll').on 'scroll', _.throttle(PadsListHelper.scrollAction, 200)

  Session.set 'modal', 'welcome'


Template.pad_list.helpers
  username: ->
    Meteor.user()?.username



  leftText: ->
    return PadsListHelper.leftSideMessage @, "text"



  leftImage: ->
    return PadsListHelper.leftSideMessage @, "image"



Template.contentEditable.helpers
  attributes: ->
    unless _.has(@, 'contentEditable') or _.has(@, 'contenteditable')
      @['contentEditable'] = false
    return _.omit @, 'value'



  encodedValue: ->
    new Spacebars.SafeString(@value or "")
