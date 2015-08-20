class MobileHelper
  isMobile: ->
    Boolean window.isMobile

  isPortrait: ->
    $(window).height() > $(window).width()

@mobileHelper = new MobileHelper
