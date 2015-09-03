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
    # Collapse any open menus
    collapseElements(e)

  'click a[href]': (e) ->
    # Force all URLs to open in external browser on mobile device
    if Meteor.isCordova
      e.preventDefault()
      platform = device.platform.toLowerCase()
      $link = $(e.target).closest('a[href]')
      if $link.length > 0
        url = $link.attr('href')
        switch platform
          when 'ios'
            window.open url, '_system'
          when 'android'
            navigator.app.loadUrl url, {openExternal: true}
