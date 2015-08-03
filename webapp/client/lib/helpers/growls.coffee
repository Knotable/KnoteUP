###
  # https://github.com/ifightcrime/bootstrap-growl
  # Available Options
  $.bootstrapGrowl("another message, yay!", {
    ele: 'body', // which element to append to
    type: 'info', // (null, 'info', 'danger', 'success')
    offset: {from: 'top', amount: 20}, // 'top', or 'bottom'
    align: 'right', // ('left', 'right', or 'center')
    width: 250, // (integer, or 'auto')
    delay: 4000, // Time while the message will be displayed. It's not equivalent to the *demo* timeOut!
    allow_dismiss: true, // If true then will display a cross to close the popup.
    stackup_spacing: 10 // spacing between consecutively stacked growls.
  });
###



@showTooltipBootstrapGrowl = (message, options = {}, cleanOldGrowl) ->
  options.type = "tooltip"
  showBootstrapGrowl message, options, cleanOldGrowl



@showErrorBootstrapGrowl = (message, options = {}, cleanOldGrowl) ->
  options.type = "error"
  showBootstrapGrowl message, options, cleanOldGrowl



@showBootstrapGrowl = (message, options = {}, cleanOldGrowl = false) ->
  removeBootstrapGrowl() if cleanOldGrowl
  growlId = "growl-id-#{Random.id()}"
  options.type = (options.type or "info") + " #{growlId}"
  $item = $.bootstrapGrowl message, options
  $item.css("right", options.right) if options.right
  $item.css("left", options.left) if options.left
  $item.css("top", options.top || 45)
  $item.addClass(options.cssClass) if options.cssClass
  $item



@removeBootstrapGrowl = (delay = 0 ) ->
  if $('div.bootstrap-growl').length > 0
    if delay != 0
      setTimeout (->
        $('div.bootstrap-growl').not('.skip-removing').remove()
      ), delay
    else
      $('div.bootstrap-growl').not('.skip-removing').remove()