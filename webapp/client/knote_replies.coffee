###
Template.knote_replies.onRendered ->
  lines = SettingsHelper.getLinesBeforeReadmore()
  maxHeight = lines * KnotesHelper.LINE_HEIGHT
  $('ul.knote-replys li').each ->
    ele = $(this).find('.reply-body')
    ele.removeClass (id, classes) ->
      temp = classes.match('lines-[0-9][0-9]?')
      if temp?.length
        return temp[0]
      return ""
    $(this).removeClass 'need-readmore'

    if ele.height() > maxHeight
      $(this).addClass 'need-readmore'
      ele.addClass "lines-" + lines
###



Template.knote_replies.helpers
  replyContact: ->
    contact = Contacts.findOne emails: @from
    unless contact
      knotableConnection.subscribe 'contactsByEmails', [@from]

    contact



  styleClass: ->
    className = []
    ###
    unless @from is UsersHelper.getUserEmail()
      lastSeenDate = new Date(Session.get 'lastSeenDate')
      replyDate = new Date @date
      if lastSeenDate.getTime() < replyDate.getTime()
        className.push 'is-new'
    ###
    className.join ' '



  replyedTime: ->
    return moment(@date).fromNow()



  replys: ->
    return false if _.isEmpty(@replys)
    defaultReplyDisplay = 3
    option = Session.get "reply-option"
    totalReplies = @replys.length
    if option
      if option.knoteId is @_id
        replyDisplay = parseInt option.replyDisplay
      else
        replyDisplay = $(".knote-reply-wrapper[data-knote-id=#{@_id}]").attr('data-reply-displaying')
        replyDisplay = defaultReplyDisplay unless replyDisplay
    remainingReply = totalReplies - replyDisplay

    isEditingReply = true
    showCommentActions = totalReplies > replyDisplay

    editingReply = amplify.store('editingTopic')
    replies = _.map @replys, (r) ->
      r.body = body if body = editingReply?.comments[r.replyId]?.body
      r['isEditingReply'] = isEditingReply
      r.editBody = '<div contenteditable="true" class="reply-body reply">' + r.body + '</div>'
      return r

    text = remainingReply
    text += " more" if replyDisplay > 0
    text += if remainingReply is 1 then " reply" else " replies"
    result =
      replys: replies
      totalReplys: totalReplies
      replyDisplay: replyDisplay
      remainingReply: remainingReply
      showCommentActions: showCommentActions
      text: text
    return result



Template.knote_replies.events
  "click .reply a": (e) ->
    e.stopPropagation()
    window.open($(e.target).attr("href"), '_blank')



  "click .knote-replys li .btn-close": (e) ->
    ele = $(e.target)
    id = $(e.currentTarget).parents('li').attr('data-id')
    knote_id = $(e.currentTarget).parents('.knote-reply-cn').attr('data-id')
    knote_id = $(e.currentTarget).parents('.knote-reply-wrapper').attr('data-knote-id') unless knote_id
    ele.next('.fa-refresh').show()
    ele.hide()
    knotableConnection.call "remove_reply_message", knote_id, id, (e,r) ->
      ele.css("display": '')
      ele.next('.fa-refresh').hide()



  'click .knote-replys li.need-readmore .readmore-tip': (e) ->
    ele=$(e.currentTarget)
    parent=ele.parents('li.need-readmore')
    if parent.hasClass 'viewing'
      parent.removeClass 'viewing'
      ele.attr('title','Click to read more')
    else
      parent.addClass "viewing"
      ele.attr('title','Click to collapse')



  'click .see-replies': (e) ->
    ele=$(e.currentTarget)
    getReply=ele.parents('.knote-reply-wrapper').attr('data-reply-displaying')
    totalReply=ele.parents('.knote-reply-wrapper').attr('data-total-reply')
    knote_id=ele.parents('.knote-reply-cn').attr('data-id')
    unless totalReply is getReply
      #setting options for getting more replays
      options=
        replyDisplay: totalReply
        knoteId:knote_id
      Session.set "reply-option",options



  'click .shrink-replies': (e) ->
    #TopicsHelper.shrinkAllComments()
    ele=$(e.currentTarget)
    knote_id=ele.parents('.knote-reply-cn').attr('data-id')
    options=
        replyDisplay: 0
        knoteId:knote_id
    Session.set "reply-option",options



## Knote Reply Compose Template
#
Template.knote_reply_compose.events
  "keydown .reply-message-textarea": (e) ->
    code = e.keyCode || e.which;
    if code == 9
      ele=$(e.currentTarget)
      dataOrder = ele.data("txtarea")
      ele.focusout()
      $(document).find("[data-repbtn='" + dataOrder + "']").focus()
      e.preventDefault()
      return false



  ###
  'keyup .reply-message-textarea': (e) ->
    TopicsHelper.autoSaveEditingTopic({type: "commentsDraft", id: @_id , body: $(e.target).html()})
    KnotesHelper.listenToMentions(e)



  'keydown .reply-message-textarea': (e) ->
    KnotesHelper.listenToMentions(e)



  'keyup .reply-message-textarea.reply': (e) ->
    TopicsHelper.autoSaveEditingTopic({type: "comments", id: @replyId, body: $(e.target).html()})
  ###



  'paste .reply-message-textarea': AppHelper.pasteAsPlainTextEventHandler



  'paste .reply-message-textarea.reply': AppHelper.pasteAsPlainTextEventHandler



  "click .reply-new-message": (e) ->
    $ele = $(e.target)
    $knote = $ele.closest('.knote')
    replyCompose = $knote.find('.knote-compose-popup-cn')
    #TopicsHelper.removeAutoSaveEditingTopic({type: 'commentsDraft', id: @_id})
    KnoteHelper.postReplyMessage $ele
    replyCompose.slideToggle ->
      $knote.find('.knote-actions').show()



  "click .reply-cancel": (e) ->
    $knote = $(e.target).closest('.knote')
    replyCompose = $knote.find('.knote-compose-popup-cn')
    replyText = $knote.find('.reply-message-textarea')
    replyText.html('')
    replyCompose.slideToggle ->
      $knote.find('.knote-actions').show()
