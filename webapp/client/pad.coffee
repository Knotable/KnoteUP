
Template.pad.onRendered ->
  @find('.pad .knote-list')?._uihooks = AnimationHooks.moveKnote



Template.pad.helpers
  knotableLink: ->
    UrlHelper.getPadUrlFromId(@_id)



  knotes: ->
    PadsListHelper.getSortedKnotes @_id
