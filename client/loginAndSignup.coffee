Template.loginAndSignup.events
  'click #cd-login .login': (event) ->
    event.preventDefault()
    event.stopPropagation()
    email = $("#signin-email").val()
    password = $("#signin-password").val()
    if email and password
      Meteor.loginWithPassword email, password, (error) ->
        if not error
          $('.cd-user-modal').removeClass('is-visible')

  'click #cd-signup .signup': (event) ->
    event.preventDefault()
    event.stopPropagation()
    username = $("#signup-username").val()
    email = $("#signup-email").val()
    password = $("#signup-password").val()
    if username and email and password
      user =
        username: username
        email: email
        password: password
      Accounts.createUser user, (error) ->
        $('.cd-user-modal').removeClass('is-visible') if not error


Template.loginAndSignup.onRendered  ->
  $form_modal = $('.cd-user-modal')
  $form_login = $form_modal.find('#cd-login')
  $form_signup = $form_modal.find('#cd-signup')
  $form_modal_tab = $('.cd-switcher')
  $tab_login = $form_modal_tab.children('li').eq(0).children('a')
  $tab_signup = $form_modal_tab.children('li').eq(1).children('a')
  $main_nav = $('.main-nav')
  # close modal
  $('.cd-user-modal').on 'click', (event) ->
    if( $(event.target).is($form_modal) || $(event.target).is('.cd-close-form') )
      $form_modal.removeClass('is-visible')

  # close modal when clicking the esc keyboard button
  $(document).keyup (event) ->
    $form_modal.removeClass('is-visible') if(event.which=='27')


  # switch from a tab to another
  $form_modal_tab.on 'click', (event) ->
    event.preventDefault()
    if ( $(event.target).is( $tab_login ) )
       login_selected()
    else
      signup_selected()

  # hide or show password
  $('.hide-password').on 'click', ->
    $this= $(this)
    $password_field = $this.prev('input')

    if ( 'password' == $password_field.attr('type') )
      $password_field.attr('type', 'text')
    else
      $password_field.attr('type', 'password')
    if ( 'Hide' == $this.text() )
      $this.text('Show')
    else
      $this.text('Hide')


  $('.hide-password').click()


  login_selected = ->
    $form_login.addClass('is-selected')
    $form_signup.removeClass('is-selected')
    $tab_login.addClass('selected')
    $tab_signup.removeClass('selected')

  signup_selected = ->
    $form_login.removeClass('is-selected')
    $form_signup.addClass('is-selected')
    $tab_login.removeClass('selected')
    $tab_signup.addClass('selected')
