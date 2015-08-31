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
      Session.set 'modal', null
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

    knotableConnection.call 'createAccount', user, null, false, false, true, (err, result) =>
      form.removeClass 'processing'
      if err
        return registerEventHandler null, {type: 'error', desc: err.reason}

      knotableConnection.call('update_contact_gravatar_status', result.userId)

      logIn user.email, user.password, (err) ->
        registerEventHandler null, {type: 'error', desc: err.reason} if err  



Template.user_modal.helpers

  modal: ->
    Session.get 'modal'

  welcome: ->
    Session.equals 'modal', 'welcome'

  login: ->
    Session.equals 'modal', 'login'



Template.user_modal.events

  'click .user-modal': (event) ->
    $userModal = $('.user-modal')
    if $(event.target).is($userModal)
      Session.set 'modal', false



  'click .icon-cancel': (event) ->
    Session.set 'modal', false



Template.welcome_carousel.onRendered ->
  Meteor.setTimeout ->
    carousel = $(".owl-carousel")
    carousel.owlCarousel(
      margin: 50,
      nav: true,
      autoWidth: true,
      center: true,
    )
    carousel.on('changed.owl.carousel', (event) ->
      total = event.item.count - 1
      current = event.item.index
      if current == 0
        $('.owl-prev').hide()
      else
        $('.owl-prev').css('display', 'inline-block')
      if total == current
        $('.owl-next').hide()
      else
        $('.owl-next').css('display', 'inline-block')
    )
  , 1000


Template.welcome_carousel.helpers

  isMobile: ->
    return mobileHelper.isMobile()


Template.login_box.onRendered ->
  $('.user-modal').find('#login-username').focus()



Template.login_box.events

  'click #register-link': ->
    $("#login-box").addClass('hidden')
    $("#register").removeClass('hidden')


  'click #go-login': ->
    $('#login-box').removeClass("hidden")
    $('#register').addClass("hidden")


  'click #login-button': (event, template) ->
    event.preventDefault()
    event.stopPropagation()
    email = $("#login-username").val()
    password = $("#login-password").val()
    if email and password
      logIn email, password, (error) ->
        if error
          console.log 'login error', error
          reason = error.reason or error.error or error.message
          try
            parseReason = JSON.parse reason
            reason = parseReason.message or reason
          catch e

          template.$('#login-form .form-message').removeClass('invisible').text(reason)
    else
      template.$('#login-form .form-message').removeClass('invisible').text('Please fill out all the boxes!')


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


  'keyup #login-password,#login-username': (e, template) ->
    if e.keyCode isnt 13
      template.$('#login-form  .form-message').addClass('invisible')


  'keyup #account-username,#account-email,#account-password': (e) ->
    unless e.keyCode is 13
      $('#register .form-message').addClass 'invisible'
