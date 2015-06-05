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
