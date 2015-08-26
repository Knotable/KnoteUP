
Template.pad.helpers
  knotableLink: ->
    UrlHelper.getPadUrlFromId(@_id)



  knotes: ->
    PadsListHelper.getSortedKnotes @_id
