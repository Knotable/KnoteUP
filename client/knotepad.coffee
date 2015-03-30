showLoginForm = ->
  $form_modal = $('.user-modal')
  $form_modal.addClass('is-visible')
  $form_modal.find('#login-username').focus()



Template.knotePad.events
  'keyup .new-knote-title': (event, template) ->
    MAX_LENGTH = 140

    text = $(event.currentTarget).val()
    remainingTextLength = MAX_LENGTH - text.length
    $counter = template.$('.counter')
    $counter.text remainingTextLength
    if remainingTextLength < 0
      $counter.attr("data-limit-exceed", true)
      template.$('.post-button').attr('disabled', true)
    else
      $counter.attr("data-limit-exceed", false)
      template.$('.post-button').attr('disabled', false)


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


  'click .post-button': (e, template) ->
    if not Meteor.userId()
      showLoginForm()
    else
      user = Meteor.user()
      subject = $("#pad-subject").val()
      title = $(".new-knote-title").val()
      body = $(".new-knote-body").html()
      if subject and title
        requiredTopicParams =
          userId: Meteor.userId()
          participator_account_ids: []
          subject: subject
          permissions: ["read", "write", "upload"]

        $postButton = $(e.currentTarget)
        $postButton.val('...')
        if template.data?.pad?._id
          topicId = template.data.pad._id

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
            $postButton.val('Post')
            if error
              console.log 'add_knote', error
            else
              $(".new-knote-title").val('')
              $(".new-knote-body").html('')
        else
          Meteor.remoteConnection.call "create_topic", requiredTopicParams, (error, result) ->
            if error
              console.log 'create_topic', error
              $postButton.val('Post')
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
                $postButton.val('Post')
                if error
                  console.log 'add_knote', error
                else
                  $(".new-knote-title").val('')
                  $(".new-knote-body").html('')

              Router.go 'knotePad', padId: topicId



Template.knotePad.helpers
  username: ->
    Meteor.user()?.username
  hasLoggedIn: ->
    Boolean Meteor.userId()
