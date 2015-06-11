@PadsListHelper =
  storeEditedContent: (editKnote) ->
    amplify.store "knote", editKnote


  restoreEditedContent: ->
    storedKnote = amplify.store("knote")
    return if _.isEmpty storedKnote
    $(".new-knote-title").val(storedKnote.title)
    $(".new-knote-body").html(storedKnote.body)

  resetEditedContent: ->
    amplify.store 'knote', null


  sortKnotesOrder: (knotes) ->
    return knotes if _.isEmpty knotes
    quickRank = QuickKnotesRank.findOne padId: knotes[0].topic_id
    if quickRank
      _.each knotes, (knote) ->
        knoteId = knote._id
        knote.quickRank = if knote.archived
          quickRank.knoteIds.archived?.indexOf knoteId
        else
          quickRank.knoteIds.unarchived?.indexOf knoteId
      knotes = _.sortBy knotes, (knote) -> [knote.archived, knote.quickRank, knote.order]
      subjects = _.map knotes, (knote) -> knote.title
      console.log 'knote order', subjects.join(' ')
    return knotes


  setKnotesRankForPad: (padId, knoteId, isArchived) ->
    knotesRank = QuickKnotesRank.findOne(padId: padId)
    if knotesRank
      knoteIds = knotesRank.knoteIds
      if isArchived
        knoteIds.archived.push knoteId
        knoteIds.unarchived = _.reject knoteIds.unarchived, (id) -> id is knoteId
      else
        knoteIds.unarchived.push knoteId
        knoteIds.archived = _.reject knoteIds.archived, (id) -> id is knoteId
      knoteIds.archived = _.uniq knoteIds.archived
      knoteIds.unarchived = _.uniq knoteIds.unarchived
      QuickKnotesRank.update knotesRank._id, $set: knoteIds: knoteIds
    else
      knoteIds =
        archived: []
        unarchived: []
      knotes = Knotes.find(topic_id: padId,
        sort: archived: 1, order: 1
        fields: archived: 1
      ).fetch()
      if knotes.length
        _.each knotes, (knote) ->
          return if knote._id is knoteId
          if knote.archived
            knoteIds.archived.push knote._id
          else
            knoteIds.unarchived.push knote._id
      if isArchived
        knoteIds.archived.push knoteId
      else
        knoteIds.unarchived.push knoteId
      QuickKnotesRank.insert padId: padId, knoteIds: knoteIds
