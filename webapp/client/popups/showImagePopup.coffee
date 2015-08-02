class @ShowImagePopup
  @id = '#show-image-popup'
  @parent = 'body'
  @activeInstance = null


  constructor: (data = {}) ->
    removeInstanceIfExists $ ShowImagePopup.id
    data.sharePopup = @
    UI.renderWithData Template.showImagePopup, data, $(ShowImagePopup.parent)[0]
    ShowImagePopup.activeInstance = @
    @$popup = $ ShowImagePopup.id


  removeInstanceIfExists = ($popup) ->
    $popup.remove() if $popup.length
    ShowImagePopup.activeInstance = null


  show: ->
    @$popup.lightbox_me
      centered: true


  close: ->
    @$popup.trigger 'close'

Template.showImagePopup.events
  'click div': ->
    ShowImagePopup.activeInstance.close()

@showImagePopup = (url) ->
  (new ShowImagePopup url).show()
