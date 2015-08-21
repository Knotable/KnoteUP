@collapseElements = (e) ->
  $settings = $('#setting-dropdown')
  $share = $('.share-pad-dropdown')
  $target = $(e.target)
  unless $target.is('.right-header-item .account-avatar')
    if $settings.is(':visible')
      $settings.slideToggle()
  unless $target.is('.share-pad-btn')
    if $share.is(':visible')
      $visible = $share.filter(':visible')
      $visible.slideToggle()


Template.layout.events

  'click #container': (e) ->
    collapseElements(e)
