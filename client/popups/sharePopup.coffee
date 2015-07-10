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



class @SharePopupStaticReference
  @id = '#share-popup-static-reference'
  @parent = 'body'
  @activeInstance = null


  constructor: (data = {}) ->
    removeInstanceIfExists $ SharePopupStaticReference.id
    UI.renderWithData Template.sharePopupStaticReference, data, $(SharePopupStaticReference.parent)[0]
    SharePopupStaticReference.activeInstance = @
    @$popup = $ SharePopupStaticReference.id


  removeInstanceIfExists = ($popup) ->
    $popup.remove() if $popup.length
    SharePopupStaticReference.activeInstance = null


  show: ->
    @$popup.lightbox_me
      centered: true