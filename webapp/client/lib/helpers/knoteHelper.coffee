formatPredefinedServiceUrl = (service, $linkNode) ->
  service = KnoteHelper.CUSTOM_EMBED_LINKS[service]
  originalUrl = $linkNode.attr('href')
  embedData =
    title: service.name
    hasPhoto: true
    original_url: originalUrl
    thumbnail_url: service.logo
    formattedUrl: UrlHelper.removeScheme(originalUrl)
    longerWidth: true
  newNode = $(UI.toHTMLWithData(Template.knote_embed_block_link, embedData))
  $linkNode.replaceWith newNode
  newNode



formatInlineLink = ($linkNode, data) ->
  data.title = data.title or UrlHelper.removeScheme(data.original_url)
  newNode = $(UI.toHTMLWithData(Template.knote_embed_inline_link, data))
  $linkNode.replaceWith newNode
  newNode



formatBlockLink = ($linkNode, data, callback) ->
  data.formattedUrl = UrlHelper.removeScheme(data.original_url)

  ### TODO
  if SettingsHelper.isURLPreviewImageUseFavicon(data.original_url)
    faviconUrl = UrlHelper.getFaviconUrl(data.original_url)
    data.favicon_url = faviconUrl if faviconUrl
  else if SettingsHelper.isURLPreviewShowThumbshot(data.original_url)
    data.thumbnail_url = UrlHelper.getThumbshotUrl(data.original_url)
  ###

  data.hasPhoto = data.favicon_url or data.thumbnail_url

  if data.thumbnail_url
    if data.thumbnail_width > data.thumbnail_height
      data.longerWidth = true

  shortHash = UrlHelper.getShortHashInUrl(data.original_url)
  if shortHash
    topic = UrlHelper.getTopicByShortHash shortHash
    if topic
      data.title = topic.subject
    else
      knotableConnection.call 'getTopicByShortHash', shortHash, (err, topic) ->
        data.title = topic.subject if topic
        newNode = $(UI.toHTMLWithData(Template.knote_embed_block_link, data))
        $linkNode.replaceWith newNode
        callback?(newNode)
      return

  newNode = $(UI.toHTMLWithData(Template.knote_embed_block_link, data))
  $linkNode.replaceWith newNode
  callback?(newNode)



tryToRetrievePredefinedServiceFromUrl = (regex, url)->
  return null unless regex or url
  result = url.match(regex)
  return null unless result and result.length
  result[0]



displayEmbedLinks = (links, options = {}, callback) ->
  if _.isFunction options
    callback = options
    options = {}

  regex = KnoteHelper.buildRegexForCustomEmbedLink()
  formattedLinks = []
  async.each links, (linkItem, completed) ->
    $linkNode = $(linkItem)

    url = $linkNode.attr('href')
    ### TODO
    if SettingsHelper.isURLDontPreview(url)
      completed()
      return
    ###

    if service = tryToRetrievePredefinedServiceFromUrl(regex, url)
      newNode = formatPredefinedServiceUrl service, $linkNode
      formattedLinks.push newNode
      completed()
      return


    $linkNode.embedly
      key: Meteor.settings.public.embed_key,
      query:
        maxwidth: 520
      display: (data) ->
        filter = new EmbeddableLinksFilter()
        if options.inlineLinks or filter.isInlineLink(linkItem)
          newNode = formatInlineLink($linkNode, data)
          formattedLinks.push newNode
          return completed()

        if KnoteHelper.hasError data
          if UrlHelper.getShortHashInUrl(data.original_url)
            formatBlockLink $linkNode, data, (newNode) ->
              formattedLinks.push newNode
              completed()
          else
            completed()
          return

        if data.type is KnoteHelper.TYPE_PHOTO
          photoUrl = data.thumbnail_url or data.url
          data.photoName = data.title or _.last photoUrl.split('/')
          newNode = $(UI.toHTMLWithData(Template.knote_embed_photo, data))
          $linkNode.replaceWith newNode
          $('<br class="clear"/>').insertAfter newNode unless newNode.next().is 'br'
        else if data.type is KnoteHelper.TYPE_VIDEO and data.html
          newNode = $(UI.toHTMLWithData(Template.knote_embed_video, data))
          $linkNode.replaceWith newNode
        else
          formatBlockLink $linkNode, data, (newNode) ->
            formattedLinks.push newNode
            completed()
          return

        formattedLinks.push newNode
        completed()
  , (err) ->
    callback err, formattedLinks if _.isFunction callback



@KnoteHelper =
  TYPE_LINK: 'link'
  TYPE_PHOTO: 'photo'
  TYPE_VIDEO: 'video'
  TYPE_RICH: 'rich'
  TYPE_ERROR: 'error'

  PROVIDER_NAME_YOUTUBE: 'YouTube'
  PROVIDER_NAME_VIMEO: 'Vimeo'

  CUSTOM_EMBED_LINKS:
    'dropbox.com':
      logo: CdnHelper.getCdnUrlOrAbsoluteUrl() + 'images/dropbox.png'
      name: 'Dropbox'
    'app.box.com':
      logo: CdnHelper.getCdnUrlOrAbsoluteUrl() + 'images/box-logo.png'
      name: 'Box'
    'drive.google.com':
      logo: CdnHelper.getCdnUrlOrAbsoluteUrl() + 'images/Logo_of_Google_Drive.png'
      name: 'Google Drive'
    'docs.google.com':
      logo: CdnHelper.getCdnUrlOrAbsoluteUrl() + 'images/Logo_of_Google_Drive.png'
      name: 'Google Drive'
    'onedrive.live.com':
      logo: CdnHelper.getCdnUrlOrAbsoluteUrl() + 'images/onedrive-logo.png'
      name: 'Onedrive'



  # embed.ly
  # API usage: https://github.com/embedly/embedly-jquery/
  embedLink: (root, options, callback) ->
    if _.isFunction options
      callback = options
      options = null

    # param: root - DOM element
    unless root
      callback null if _.isFunction callback
      return
    filter = new EmbeddableLinksFilter root
    links = filter.getLinks()
    displayEmbedLinks links, options, (err, formattedLinks) ->
      contentHelper.formatImagesDOM root
      $root = $(root)
      rootHtml = $root.html().replace(/&amp;/g, '&').replace(/[\r\n]+/g, '')
      $root.html(rootHtml)
      callback?(err, formattedLinks)



  formatAndSave: (template, callback) ->
    async.waterfall [
      (next) -> KnoteHelper.formatTitle template, next
      (next) -> KnoteHelper.formatBody template, next
      (next) -> KnoteHelper._saveKnote template, next
    ], (err) ->
      console.log(err.stack or err) if err
      callback(err) if _.isFunction(callback)



  formatTitle: (template, after) ->
    $title = $(template.find('.knote-title'))
    return after?(new Meteor.Error "validationError", "Title is required") if _.isEmpty($title.text().trim())
    @getFormattedHtmlContentAsync $title, {inlineLinks: true}, (error, contentInfo) =>
      $title.html contentInfo.content.trim()
      after?(error)



  formatBody: (template, after) ->
    knote = template.data
    bodyEditor = $(template.find('.knote-body'))
    @getFormattedHtmlContentAsync bodyEditor, (error, contentInfo) =>
      return after?(error) if error
      bodyEditor.html contentInfo.content.trim()
      after?()



  getFormattedHtmlContentAsync: ($editor, options, callback) ->
    if _.isFunction options
      callback = options
      options = null
    return callback(null, content: '') unless $editor.length
    $el = $editor.clone()
    #CommentsHighlighter.getInstance().unhighlight($el)
    #Usertag.cleanUp $el
    contentHelper.linkifyDOM $el[0]
    KnoteHelper.embedLink $el[0], options, (err) =>
      html = $el.html()
      ### TODO
      if SettingsHelper.isEnableKnoteHashtagsParsing()
        Hashtag.resetHashtags()
        content_info = Hashtag.extract_hashtags_from_html html
      else
        content_info = content: html
      ###
      content_info = content: html
      callback err, content_info if _.isFunction callback



  buildRegexForCustomEmbedLink: ->
    keys = _.keys(KnoteHelper.CUSTOM_EMBED_LINKS).map (p) -> AppHelper.escapeRegexpPattern(p)
    return null unless keys.length
    new RegExp(keys.join('|'))



  hasError: (data) ->
    if data.invalid
      # The URL that you passed in was not a good one.
      console.log('EMBED-Invalid: ', data.error, data.error_message)
      return true
    else if (data.type is KnoteHelper.TYPE_ERROR)
      # The API passed back an error.
      console.log('EMBED-type error: ', data.type, data.error_message)
      return true
    return false



  shouldLeaveArchived: (knote, content, filesIds) ->
    # Card#1217: If an archived knote is edited can it be moved back to the thread?
    return knote.htmlBody.trim() == content.trim() and filesIds.length == 0



  getFilesIds: (template) ->
    fileInputs = $.makeArray($(template.findAll(".message input[name='file_ids']")))
    return _.map fileInputs, (fi) -> $(fi).val()



  postReplyMessage: ($target) ->
    btnText = $target.val()
    el = $target.parents('.knote-compose-popup-cn').find(".reply-message-textarea").clone()[0]
    knote_id = $target.parents('.knote-compose-popup-cn').prev('.knote-reply-cn').attr('data-id')
    knote_id = $target.parents('.knote-compose-popup-cn').attr('data-id') unless knote_id
    replyDisplaying = $target.parents('.knote-compose-popup-cn').prev('.knote-reply-cn').find('.knote-reply-wraper').attr('data-reply-displaying')
    replyDisplaying = 0 if replyDisplaying is undefined
    options=
      replyDisplay: parseInt(replyDisplaying) + 1
      knoteId: knote_id

    contentHelper.linkifyDOM el

    KnoteHelper.embedLink el, {inlineLinks: true}, (err) =>
      body = $(el).html()
      $(".reply-message-textarea").html("")
      knotableConnection.call 'add_reply_message', knote_id, body, (e) ->
        console.log e if e
        ###
        unless e
          Meteor.defer ->
            KnotableAnalytics.trackEvent eventName: KnotableAnalytics.events.knoteCommented, knoteId: knote_id, relevantPadId: TopicsHelper.currentTopicId()
        ###
        Session.set "reply-option",options unless e



  postNewKnote: (requiredKnoteParameters, optionalKnoteParameters = {}) ->
    deferred = $.Deferred()
    user = Meteor.user()
    unless user
      _.defer -> deferred.reject(new Meteor.Error "User not found")
      return deferred.promise()
    requiredTopicParams =
      userId: requiredKnoteParameters.userId or user._id
      participator_account_ids: []
      subject: requiredKnoteParameters.subject
      permissions: ["read", "write", "upload"]

    requiredKnoteParameters = _.defaults requiredKnoteParameters,
      userId: user._id
      name: user.username
      from: user.emails[0].address
      isMailgun: false

    optionalKnoteParameters = _.defaults optionalKnoteParameters,
      replys: []
      pinned: false
      requiresPostProcessing: true
      date: new Date

    addKnote = ->
      Meteor.remoteConnection.call 'add_knote', requiredKnoteParameters, optionalKnoteParameters, (error, knoteId) ->
        return deferred.reject(error) if error
        deferred.resolve(knoteId)

    if requiredKnoteParameters.topic_id
      addKnote()
    else
      Meteor.remoteConnection.call "create_topic", requiredTopicParams,  {source: 'quick'}, (error, topicId) ->
        return deferred.reject(error) if error
        requiredKnoteParameters.topic_id = topicId
        addKnote()
    deferred.promise()



  processSavingOnCtrlEnterAction: ($action, jEvent)->
    return unless $(jEvent.target).is('div[contenteditable]')
    if (jEvent.keyCode is 13 or jEvent.keyCode is 10) and (jEvent.shiftKey or jEvent.ctrlKey)
      jEvent.preventDefault()
      $action.click()



  _saveKnote: (template, callback) ->
    knote = template.data
    newTitle = $(template.find('.knote-title')).html()
    $knoteBody = $(template.find('.knote-body'))

    archiveFileIds = []
    $knoteBody.find('.file-archiving').each (i, ele) ->
      archiveFileIds.push $(ele).attr('data-id')
    $knoteBody.find('.file-archiving').remove()
    # TODO - Set archive = true or delete file doc with s3 file for
    # All ids inside archiveFileIds

    newBody = $knoteBody.html()

    # TODO
    #isKnoteTitleEnable = SettingsHelper.isEnableKnoteTitle()
    isKnoteTitleEnable = true
    if knote.htmlBody is newBody
      return callback() if !isKnoteTitleEnable or (isKnoteTitleEnable and knote.title is newTitle)

    toSetData = { htmlBody: newBody, lastHtmlBody: knote.htmlBody, requiresPostProcessing: false}
    if knote.title isnt newTitle
      newTitle = null if _.isEmpty(AppHelper.getTextFromHtml(newTitle).trim())
      toSetData.title = newTitle
      $(template.find('.knote-title')).html('')

    fileIds = KnoteHelper.getFilesIds(template)
    if knote.archived
      isArchived = KnoteHelper.shouldLeaveArchived(knote, newBody, fileIds)
      toSetData.archived = isArchived

    ###
    if SettingsHelper.isEnableKnoteHashtagsParsing() and contentInfo.hashtags
      toSetData.hashtags = contentInfo.hashtags
    ###

    query = $set: toSetData
    unless _.isEmpty(fileIds)
      query.$addToSet = { file_ids: $each: fileIds }

    Knotes.update knote._id, query, (error) =>
      return callback(error) if error
      #KnotableAnalytics.trackEvent eventName: KnotableAnalytics.events.textKnoteEdited, knoteId: knote._id, relevantPadId: TopicsHelper.currentTopicId()
      callback()
      template.controller?.isEditing?.set(false)
      knotableConnection.call 'update_knote_metadata', knote._id, {}, 'webapp:knoteup:KnoteController.save'
      #@updateKnoteEditors(knote)
      knotableConnection.call 'remove_other_topic_viewers', knote.topic_id


  deleteKnote: (knoteId) ->
    user = Meteor.user()
    knote = Knotes.findOne knoteId
    throw new Meteor.Error "User not found" unless user
    throw new Meteor.Error "Knote not found" unless user
    throw new Meteor.Error "Can not delete knote" unless knote.archived

    # TODO - If there are files in knote, remove files from s3 & file collection

    # Quick solve - Update the knote collection to delete it
    Knotes.update {_id: knoteId},
      $set: {htmlBody: '', file_ids: []}

    # Remove the knote
    Knotes.remove knoteId



class EmbeddableLinksFilter
  TAG_LINK_RGX = /^a$/i
  TAG_BR_RGX = /^br$/i
  ALLOWED_PARENTS_RGX = /^(div|p|body)$/i
  NODE_TYPE = TEXT: 3, ELEMENT: 1
  DIRECTION = NEXT: 1, PREV: 0



  constructor: (root) ->
    #throw new Meteor.Error '"root" cannot be undefined' unless root
    @_root = root



  getLinks: ->
    return [] unless @_root
    links = []
    try
      treeWalker = document.createNodeIterator @_root, NodeFilter.SHOW_ELEMENT, null, false
      while node = treeWalker.nextNode()
        continue unless TAG_LINK_RGX.test(node.tagName)
        continue unless canBeEmbedded(node)
        links.push(node)
    catch e
      console.log '[Error][getEmbeddableLinks]', e
    links



  isInlineLink: (link) ->
    return false unless link
    (contentPrecedeThe link or contentFollowThe link) and isAllowedParent link



# Private section
  canBeEmbedded = (linkItem) ->
    return false unless linkItem
    linkHref = linkItem.getAttribute('href') or ''
    return false if linkHref.startsWith("javascript:")
    return false if AppHelper.isCorrectEmail(linkHref)
    return false if linkItem.className?.indexOf("embedded-link") >= 0
    true



  contentPrecedeThe = (link) ->
    checkSiblingNodeOf link, DIRECTION.PREV



  contentFollowThe = (link) ->
    checkSiblingNodeOf link, DIRECTION.NEXT



  checkSiblingNodeOf = (link, direction) ->
    node = if direction is DIRECTION.NEXT then link.nextSibling else link.previousSibling
    return false unless node
    if node.nodeType is NODE_TYPE.TEXT
      return Boolean(node.textContent?.trim()) or checkSiblingNodeOf node, direction
    return true if node.nodeType is NODE_TYPE.ELEMENT and not TAG_BR_RGX.test node.tagName
    return false



  isAllowedParent = (link) ->
    parent = link.parentNode
    parent and (ALLOWED_PARENTS_RGX.test(parent.tagName) or isInlineLink parent)
