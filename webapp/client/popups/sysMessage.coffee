class @SysMessagePopup
  @id = '#sys-message-popup'
  @parent = 'body'
  @activeInstance = null


  constructor: (data = {}) ->
    removeInstanceIfExists $ SysMessagePopup.id
    data.SysMessagePopup = @
    UI.renderWithData Template.sysMessagePopup, data, $(SysMessagePopup.parent)[0]
    SysMessagePopup.activeInstance = @
    @$popup = $ SysMessagePopup.id


  removeInstanceIfExists = ($popup) ->
    $popup.remove() if $popup.length
    SysMessagePopup.activeInstance = null


  show: ->
    @$popup.slideToggle() unless @$popup.is(':visible')
    Meteor.setTimeout =>
      @close()
    , 2000


  close: ->
    @$popup.slideToggle() if @$popup.is(':visible')


Template.sysMessagePopup.helpers
  iconClass: ->
    switch @type
      when 'success' then 'icon-check'
      when 'warning' then 'icon-info'



showMessage = (type, message) ->
  popup = new SysMessagePopup
    type: type
    message: message
  popup.show()

@showSuccessMessage = (message) ->
  showMessage 'success', message

@showWarningMessage = (message) ->
  showMessage 'warning', message
