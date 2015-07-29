enableAccountCreation = ->
  $('#create-account').addClass 'disabled'

disableAccountCreation = ->
  $('#create-account').removeClass 'disabled'

registerEventHandler = (type, options = {}) ->
  if type
    message = switch type
      when 'duplicateName' then 'That username is taken. Please choose another.'
      when 'invalidPassword' then 'Your password must be at least 6 characters.'
      when 'invalidUsername' then 'Invalid username! Please try again.'
      when 'invalidEmail' then 'Invalid email address! Please try again.'
      when 'formIsNotFilled' then 'Please fill out all the boxes!'
      when 'duplicateEmail' then 'There is a user with this email address already.'
      else
        isSuccess = true
        'Check your email to confirm your account'
  else if options.type is 'error'
    message = options.desc

  $msg = $('#register .form-message')
  unless isSuccess
    $msg.addClass 'error'
  else
    $msg.removeClass 'error'

  $msg.removeClass('invisible').text message

logIn = (email, password, callback) ->
  Meteor.loginWithPassword email, password, (error) ->
    unless error
      $('.user-modal').removeClass('is-visible')
      PadsListHelper.restoreEditedContent()
    else
      console.log 'login error', error
      callback?(error)

validRegisterInfo = (info) ->
  if !info.username || !info.email || !info.password
    return 'formIsNotFilled'
  unless AppHelper.isValidUsername(info.username)
    return 'invalidUsername'
  unless AppHelper.isCorrectEmail(info.email)
    return 'invalidEmail'
  unless AppHelper.isValidPassword(info.password)
    return 'invalidPassword'
  return null

regist = (username, email, password) ->
  disableAccountCreation()
  form = $('#register-form')

  user =
    username: $.trim(username)
    email: $.trim(email)
    password: $.trim(password)

  if errorType = validRegisterInfo user
    return registerEventHandler errorType

  user.is_register = true
  user.fullname = user.email.substring(0, user.email.indexOf('@'))

  form.addClass 'processing'
  knotableConnection.call 'checkUsernameExist', user.username, (error, alreadyUsed) =>
    if error? || alreadyUsed
      form.removeClass 'processing'
      return registerEventHandler('duplicateName')

    knotableConnection.call 'createAccount', user, null, false, false, (err, result) =>
      form.removeClass 'processing'
      if err
        return registerEventHandler null, {type: 'error', desc: err.reason}

      knotableConnection.call('update_contact_gravatar_status', result.userId)

      logIn user.email, user.password, (err) ->
        registerEventHandler null, {type: 'error', desc: err.reason} if err



Template.loginAndSignup.events
  'click .user-modal': (event) ->
    $userModal = $('.user-modal')
    $userModal.removeClass("is-visible") if $(event.target).is($userModal)

  'click #register-link': ->
    $("#login-box").addClass('hidden')
    $("#register").removeClass('hidden')
    resetWidth()

  'click #go-login': ->
    $('#login-box').removeClass("hidden")
    $('#register').addClass("hidden")
    resetWidth()

  'click #login-button': (event, template) ->
    event.preventDefault()
    event.stopPropagation()
    email = $("#login-username").val()
    password = $("#login-password").val()
    if email and password
      logIn email, password, (error) ->
        if error
          console.log 'login error', error
          template.$('#login-form .form-message.invisible').removeClass('invisible').text(error.reason)

  'click #create-account': (event) ->
    event.preventDefault()
    event.stopPropagation()
    return if $(event.currentTarget).hasClass 'disabled'
    username = $("#account-username").val()
    email = $("#account-email").val()
    password = $("#account-password").val()
    regist username, email, password


  'keyup #login-username, keyup #account-username': (e, template) ->
    $target = $(e.currentTarget)
    username = $target.val()
    $target.val username.toLowerCase() if username
    template.$('#login-form .form-message').addClass('invisible')


  'keyup #login-password': (e, template) ->
    template.$('#login-form  .form-message').addClass('invisible')


  'keyup #account-username,#account-email,#account-password': (e) ->
    unless e.keyCode is 13
      $('#register .form-message').addClass 'invisible'



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
    $userModal.removeClass('is-visible') if event.which is 27

  resetWidth()

  verticallyCenterBox = ->
    windowHeight = $(window).height()
    $(".user-modal-container").each ->
      marginValue = 15
      boxHeight = $(this).outerHeight(false)
      if($(this).find('.header').length > 0)
        marginValue += $(this).find('.header').outerHeight(false) + 20
      if (windowHeight > boxHeight)
        marginValue = Math.max((windowHeight - boxHeight)/2, marginValue)
      marginValue += 'px'
      $(this).css
        "margin-top": marginValue
        "margin-bottom": marginValue

  verticallyCenterBox()
  $(window).off('resize', verticallyCenterBox).resize verticallyCenterBox
