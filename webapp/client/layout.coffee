@collapseElements = (e) ->
  $settings = $('#setting-dropdown')
  $share = $('.share-pad-dropdown')
  $sysMessage = $('#sys-message-popup')
  $target = $(e.target)
  unless $target.is('.right-header-item .account-avatar')
    if $settings.is(':visible')
      $settings.slideToggle()
  unless $target.is('.share-pad-btn')
    if $share.is(':visible')
      $visible = $share.filter(':visible')
      $visible.slideToggle()
  unless $target.is('.unconfirmed')
    if $sysMessage.is(':visible')
      SysMessagePopup.activeInstance.close()


Template.layout.events

  'click #container': (e) ->
    collapseElements(e)
