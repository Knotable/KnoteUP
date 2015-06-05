showLoginForm = ->
  $form_modal = $('.user-modal')
  $form_modal.addClass('is-visible')
  $form_modal.find('#login-username').focus()


Template.padsList.helpers

  username: ->
    Meteor.user()?.username


  contentEditableSubject: ->
    subject = moment().format "MMM Do"
    attrs = [
      "class='subject'"
    ]
    html = "<div #{attrs.join(' ')}>#{subject}</div>"
    return new Spacebars.SafeString html



Template.padsList.events

  'click .logout': ->
    Meteor.logout()
    Router.go 'homepage'



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



  'click .login-button': ->
    return if Meteor.userId()
    title = $(".new-knote-title").val()
    body = $(".new-knote-body").html()
    editKnote =
      title: title
      body: body
    PadsListHelper.storeEditedContent editKnote
    showLoginForm()


  'keyup .new-knote-title': (event) ->
    $(event.target).autosize()
    title = $(event.currentTarget).val()
    length = title.length
    if length > 0
      $('.post-button').attr('disabled', false)
    else
      $('.post-button').attr('disabled', true)
    if length >= 150
      $('.new-knote-body').focus()



  'click .post-button': (e, template) ->
    subject = $("#header .subject").text()
    title = $(".new-knote-title").val()
    body = $(".new-knote-body").html()

    if not Meteor.userId()
      editKnote =
        title: title
        body: body
      PadsListHelper.storeEditedContent editKnote
      showLoginForm()
    else
      user = Meteor.user()
      requiredTopicParams =
        userId: Meteor.userId()
        participator_account_ids: []
        subject: subject
        permissions: ["read", "write", "upload"]

      $postButton = $(e.currentTarget)
      $postButton.val('...')

      requiredKnoteParameters =
        subject: subject
        body: body
        topic_id: topicId
        userId: user._id
        name: user.username
        from: user.emails[0].address
        isMailgun: false

      optionalKnoteParameters =
        title: title
        replys: []
        pinned: false

      if template.data?.latestPad?._id
        topicId = template.data.latestPad._id
        requiredKnoteParameters.topic_id = topicId

        Meteor.remoteConnection.call 'add_knote', requiredKnoteParameters, optionalKnoteParameters, (error, result) ->
          $postButton.val('Post')
          if error
            console.log 'add_knote', error
          else
            $(".new-knote-title").val('')
            $(".new-knote-body").html('')
      else
        Meteor.remoteConnection.call "create_topic", requiredTopicParams,  {source: 'quick'}, (error, result) ->
          if error
            console.log 'create_topic', error
            $postButton.val('Post')
          else
            topicId = result
            requiredKnoteParameters.topic_id = topicId
            Meteor.remoteConnection.call 'add_knote', requiredKnoteParameters, optionalKnoteParameters, (error, result) ->
              $postButton.val('Post')
              if error
                console.log 'add_knote', error
              else
                $(".new-knote-title").val('')
                $(".new-knote-body").html('')



Template.padItem.helpers
  knotes: ->
    Knotes.find {topic_id: @_id}, sort: order: 1
