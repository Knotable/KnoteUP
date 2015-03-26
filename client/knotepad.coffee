Meteor.settings.public.remoteHost ?= 'beta.knotable.com'

remoteServerUrl = Meteor.settings.public.remoteHost
Meteor.remoteConnection = DDP.connect(remoteServerUrl)
Accounts.connection = Meteor.remoteConnection
Meteor.users = new Mongo.Collection 'users', connection: Meteor.remoteConnection

loginToken = 'loginToken'
meteorLoginToken = 'Meteor.loginToken'

Accounts.onLogin ->
  if localStorage[meteorLoginToken]
    amplify.store loginToken, localStorage[meteorLoginToken]


resetLoginToken = ->
  if amplify.store loginToken
    Meteor.setTimeout ->
      localStorage[meteorLoginToken] = amplify.store loginToken
    , 1000

Accounts.onLoginFailure resetLoginToken

resetLoginToken()


showLoginForm = ->
  $(".cd-user-modal").addClass('is-visible')

  $form_modal = $('.cd-user-modal')
  $form_login = $form_modal.find('#cd-login')
  $form_signup = $form_modal.find('#cd-signup')
  $form_modal_tab = $('.cd-switcher')
  $tab_login = $form_modal_tab.children('li').eq(0).children('a')
  $tab_signup = $form_modal_tab.children('li').eq(1).children('a')

  $form_login.addClass('is-selected')
  $form_signup.removeClass('is-selected')
  $tab_login.addClass('selected')
  $tab_signup.removeClass('selected')


Template.knotePad.events
  'click .redirect-to-knotable': (e) ->
    token = amplify.store loginToken
    remoteHost = Meteor.settings.public.remoteHost
    if remoteHost[-1] is '/'
      tokenSuffix = "loginToken/#{token}"
    else
      tokenSuffix = "/loginToken/#{token}"
    remoteUrl = "http://" + Meteor.settings.public.remoteHost + tokenSuffix
    if not remoteUrl.match('http://')
      remoteUrl = 'http://' + remoteUrl
    console.log remoteUrl
    window.location = remoteUrl

  'click .icon-key':  (e) ->
    return if Meteor.userId()
    showLoginForm()


  'click .post-button': (e) ->
    if Meteor.userId()
      user = Meteor.user()
      subject = $("#pad-subject").val()
      title = $(".knote-title").val()
      body = $("#knote-body").html()
      if subject and title
        requiredTopicParams =
          userId: Meteor.userId()
          participator_account_ids: []
          subject: subject
          permissions: ["read", "write", "upload"]

        Meteor.remoteConnection.call "create_topic", requiredTopicParams, (error, result) ->
          if error
            console.log 'create_topic', error
          else
            topicId = result

            requiredKnoteParameters =
              subject: subject
              body: body
              topic_id: topicId
              userId: user._id
              name: user.username
              from: user.emails?[0]
              isMailgun: false

            optionalKnoteParameters =
              title: title
              replys: []
              pinned: false
            Meteor.remoteConnection.call 'add_knote', requiredKnoteParameters, optionalKnoteParameters, (error, result) ->
              if error
                console.log 'add_knote', error
              else
                $("#pad-subject").val('')
                $(".knote-title").val('')
                $("#knote-body").html('')
    else
      showLoginForm()


Template.knotePad.helpers
  username: ->
    Meteor.user()?.username
  hasLoggedIn: ->
    Boolean Meteor.userId()


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
