class @SysMessagePopup
  @id = '#sys-message-popup'
  @parent = 'body'
  @activeInstance = null


  ###
  # data =
  #   type: 'success' || 'warning'
  #   message: 'string' # bold
  #   detail: 'string'  # plain
  #   duration: Number # -1: don't close popup automatically
  #   showOk: Boolean
  ###
  constructor: (data = {}) ->
    removeInstanceIfExists $ SysMessagePopup.id
    data.SysMessagePopup = @
    UI.renderWithData Template.sysMessagePopup, data, $(SysMessagePopup.parent)[0]
    SysMessagePopup.activeInstance = @
    @$popup = $ SysMessagePopup.id
    @options = data


  removeInstanceIfExists = ($popup) ->
    $popup.remove() if $popup.length
    SysMessagePopup.activeInstance = null


  show: ->
    @$popup.slideToggle() unless @$popup.is(':visible')
    unless @options.duration is -1
      Meteor.setTimeout =>
        @close()
      , @options.duration or 2000


  close: ->
    @$popup.slideToggle() if @$popup.is(':visible')


Template.sysMessagePopup.helpers
  iconClass: ->
    switch @type
      when 'success' then 'icon-check'
      when 'warning' then 'icon-info'


Template.sysMessagePopup.events
  'click .ok-btn': ->
    SysMessagePopup.activeInstance.close()



showMessage = (type, message, options) ->
  data =
    type: type
    message: message
  _.extend data, options
  popup = new SysMessagePopup data
  popup.show()

@showSuccessMessage = (message, options) ->
  showMessage 'success', message, options

@showWarningMessage = (message, options) ->
  showMessage 'warning', message, options
