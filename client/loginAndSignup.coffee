Template.loginAndSignup.events
  'click .user-modal': (event) ->
    $userModal = $('.user-modal')
    # $userModal.removeClass("is-visible") if $(event.target).is($userModal)

  'click #register-link': ->
    $("#login-box").addClass('hidden')
    $("#register").removeClass('hidden')
    resetWidth()

  'click #go-login': ->
    $('#login-box').removeClass("hidden")
    $('#register').addClass("hidden")
    resetWidth()

  'click #login-button': (event) ->
    event.preventDefault()
    event.stopPropagation()
    email = $("#login-username").val()
    password = $("#login-password").val()
    if email and password
      Meteor.loginWithPassword email, password, (error) ->
        if not error
          $('.user-modal').removeClass('is-visible')
        else
          console.log 'signup', error

  'click #create-account': (event) ->
    event.preventDefault()
    event.stopPropagation()
    username = $("#account-username").val()
    email = $("#account-email").val()
    password = $("#account-password").val()
    if username and email and password
      user =
        username: username
        email: email
        password: password
      Accounts.createUser user, (error) ->
        $('.user-modal').removeClass('is-visible') if not error

resetWidth = ->
  buttonWidth = $('#login-button').width()
  signupWidth = $('#create-account').width()
  width = if buttonWidth > signupWidth
    buttonWidth
  else
    signupWidth
  $('.user-modal input').each (index, $input) ->
    if $(this).width() > width
      $(this).width(width-23)


Template.loginAndSignup.onRendered  ->
  # close modal when clicking the esc keyboard button
  $userModal = $('.user-modal')
  $(document).keyup (event) ->
    # $userModal.removeClass('is-visible') if event.which is 27

  resetWidth()


  bindScreenArretRender = ->
    Meteor.clearInterval(window.arretLogin)
    i = 0
    window.arretLogin = Meteor.setInterval ->
      i++
      if i == 180
        i = 0
      $userModal.css "background", "linear-gradient("+(135+2*i)+"deg, #d7d47c 0%, #72cd99 30%, #5dbee7 70%)"
      $userModal.css "background", "-webkit-linear-gradient("+(-45+2*i)+"deg, #d7d47c 0%, #72cd99 30%, #5dbee7 70%)"
      $userModal.css "background", "-moz-linear-gradient("+(-45+2*i)+"deg, #d7d47c 0%, #72cd99 30%, #5dbee7 70%)"
      $userModal.css "background", "-o-linear-gradient("+(-45+2*i)+"deg, #d7d47c 0%, #72cd99 30%, #5dbee7 70%)"
      $userModal.css "background", "-ms-linear-gradient("+(-45+2*i)+"deg, #d7d47c 0%, #72cd99 30%, #5dbee7 70%)"
    , 90

  vcbValues =
    headerBottomMargin: 20 #px - space between the header and the login form. Connected with .box-container .header top
  verticallyCenterBox = ->
    windowHeight = $(window).height()
    $(".user-modal-container").each ->
      marginValue = 15
      boxHeight = $(this).outerHeight(false)
      if($(this).find('.header').length > 0)
        marginValue += $(this).find('.header').outerHeight(false) + vcbValues.headerBottomMargin
      if (windowHeight > boxHeight)
        marginValue = Math.max((windowHeight - boxHeight)/2, marginValue)
      marginValue += 'px'
      $(this).css
        "margin-top": marginValue
        "margin-bottom": marginValue

  bindScreenArretRender()
  verticallyCenterBox()
  $(window).off('resize', verticallyCenterBox).resize verticallyCenterBox
