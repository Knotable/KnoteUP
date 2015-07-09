class @SharePopup
  @id = '#share-popup'
  @parent = 'body'
  @activeInstance = null


  constructor: (data = {}) ->
    removeInstanceIfExists $ SharePopup.id
    UI.renderWithData Template.sharePopup, data, $(SharePopup.parent)[0]
    SharePopup.activeInstance = @
    @$popup = $ SharePopup.id


  removeInstanceIfExists = ($popup) ->
    $popup.remove() if $popup.length
    SharePopup.activeInstance = null


  show: ->
    @$popup.lightbox_me
      centered: true
