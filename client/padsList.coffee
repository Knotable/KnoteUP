showLoginForm = ->
  $form_modal = $('.user-modal')
  $form_modal.addClass('is-visible')
  $form_modal.find('#login-username').focus()



todaySubject = ->
  moment().format "MMM Do"


moveAnimationHooks =
  moveElement: (node, next) ->
    $node = $(node)
    $next = $(next)
    oldTop = $node.offset().top
    height = $node.outerHeight(true)

    # // find all the elements between next and node
    $inBetween = $next.nextUntil(node)
    if $inBetween.length is 0
      $inBetween = $node.nextUntil(next)
    # // now put node in place
    $node.insertBefore(next);
    # // measure new top
    newTop = $node.offset().top
    # // move node *back* to where it was before
    $node.removeClass('animate')
         .css('top', oldTop - newTop)
    # // push every other element down (or up) to put them back
    $inBetween.removeClass('animate')
              .css('top', oldTop < newTop ? height : -1 * height)
    # // force a redraw
    $node.offset()
    # // reset everything to 0, animated
    $node.addClass('animate').css('top', 0);
    $inBetween.addClass('animate').css('top', 0);



Template.padsList.onRendered ->
  @data.subject = moment().format "MMM Do"

  $title = @$(".new-knote-title")
  $title.autosize()
  PadsListHelper.restoreEditedContent()
  @$('.post-button').attr('disabled', false) if $title.val().length


  scrollAction = ->
    currentScroll = $('.padList').scrollTop()

    if currentScroll > 0
      $('#header').addClass('scrolling')
    else
      $('#header').removeClass('scrolling')

    if currentScroll > 180
      $('.show-compose').removeClass("invisible")
    else
      $('.show-compose').addClass("invisible")

    $currentPadItem = $('.padItem').filter( ->
      $pad = $(@)
      top = 80
      $pad.position().top < top
    ).last()

    if $currentPadItem.length
      subject = $currentPadItem.data('subject')
    else
      subject = todaySubject()
    $('#header .subject').text subject


  @$('.padList').off('scroll').on 'scroll', _.throttle(scrollAction, 200)

  @find('.currentDatePad .knote-list')?._uihooks = moveAnimationHooks




Template.padsList.helpers

  username: ->
    Meteor.user()?.username


  contentEditableSubject: ->
    subject = todaySubject()
    attrs = [
      "class='subject'"
    ]
    html = "<div #{attrs.join(' ')}>#{subject}</div>"
    return new Spacebars.SafeString html



Template.padsList.events

  'click .show-compose': ->
    $(".padList").animate {scrollTop: 0}, 600
    $('.new-knote-title').focus()


  'click .logout': ->
    Meteor.logout()



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



  'click .login-button': (event, template) ->
    return if Meteor.userId()
    title = template.$(".new-knote-title").val()
    body = template.$(".new-knote-body").html()
    editKnote =
      title: title
      body: body
    PadsListHelper.storeEditedContent editKnote
    showLoginForm()


  'keyup .new-knote-title': (event, template) ->
    title = $(event.currentTarget).val()
    length = title.length
    $postButton = template.$('.post-button')
    if length > 0
      $postButton.attr('disabled', false)
    else
      $postButton.attr('disabled', true)
    if length >= 150
      template.$('.new-knote-body').focus()
    PadsListHelper.resetEditedContent()




  'click .post-button': (e, template) ->
    subject = $("#header .subject").text()
    $newTitle = template.$(".new-knote-title")
    $newBody = template.$(".new-knote-body")
    title = $newTitle.val()
    body = $newBody.html()

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
            $newTitle.val('')
            $newBody.html('')
            PadsListHelper.resetEditedContent()
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
                $newTitle.val('')
                $newBody.html('')
                PadsListHelper.resetEditedContent()



Template.padItem.helpers
  knotes: ->
    Knotes.find {topic_id: @_id}, sort: archived: 1, order: 1

Template.padItem.onRendered ->
  @find('.pad .knote-list')?._uihooks = moveAnimationHooks
