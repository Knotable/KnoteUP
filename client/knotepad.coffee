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

        $postButton = $(e.currentTarget)
        $postButton.val('...')
        Meteor.remoteConnection.call "create_topic", requiredTopicParams, (error, result) ->
          if error
            console.log 'create_topic', error
            $postButton.val('Add')
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
              $postButton.val('Add')
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
