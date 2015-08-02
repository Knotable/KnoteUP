@AppHelper =
  USERNAME_REGEX: /^[a-zA-Z0-9\._\-]+$/

  isValidUsername: (username) ->
    AppHelper.USERNAME_REGEX.test(username)

  EMAIL_REGEX: /^[a-zA-Z0-9\._\-\+]+@[a-zA-Z0-9\.\-]+\.[a-zA-Z]{2,6}$/

  isCorrectEmail: (address) ->
    AppHelper.EMAIL_REGEX.test(address)

  # password length should be more than 6 characters
  isValidPassword : (val) ->
    val.length >= 6 ? true : false


  getTextFromHtml: (html) ->
    $('<div>').append(html).text()


  escapeRegexpPattern: (pattern) ->
    return '' unless pattern
    pattern.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&")


  currentAccount: () ->
    user = Meteor.user()
    UserAccounts.findOne user_ids: user?._id


  currentContact: () ->
    Contacts.findOne
      account_id: AppHelper.currentAccount()?._id
      type: 'me'


  setCursorOnContentEditable : (element) ->
    element.focus()
    if (typeof window.getSelection != "undefined") && (typeof document.createRange != "undefined")
      # IE 9 and non-IE
      range = document.createRange()
      range.selectNodeContents(element)
      range.collapse(false)
      sel = window.getSelection()
      sel.removeAllRanges()
      sel.addRange(range)
    else if (typeof document.body.createTextRange != "undefined")
      # IE < 9
      textRange = document.body.createTextRange()
      textRange.moveToElementText(element)
      textRange.collapse(false)
      textRange.select()
    return false


  pasteAsPlainTextEventHandler: (jEvent) ->
    originalEvent = jEvent.originalEvent
    originalEvent.preventDefault()
    if originalEvent.clipboardData
      content = (originalEvent.originalEvent or originalEvent).clipboardData.getData('text/plain')
      document.execCommand('insertText', false, content)
    else if window.clipboardData
      content = window.clipboardData.getData('Text')
      sel = undefined
      range = undefined
      if window.getSelection
        sel = window.getSelection()
        if sel.getRangeAt and sel.rangeCount
          range = sel.getRangeAt(0)
          range.deleteContents()
          # Range.createContextualFragment() would be useful here but is
          # non-standard and not supported in all browsers (IE9, for one)
          el = document.createElement('div')
          el.innerHTML = content
          frag = document.createDocumentFragment()
          node = undefined
          lastNode = undefined
          while node = el.firstChild
            lastNode = frag.appendChild(node)
          range.insertNode frag
          # Preserve the selection
          if lastNode
            range = range.cloneRange()
            range.setStartAfter lastNode
            range.collapse true
            sel.removeAllRanges()
            sel.addRange range
      else if document.selection and document.selection.type != 'Control'
       document.selection.createRange().pasteHTML(content)


  getAvatarUrlOfContact: (contact, type) ->
    return false unless contact
    type = 'path' unless type is 'mini'
    url = contact.avatar_uploaded?[type]
    return url if url and url isnt "false"
    url = contact.avatar?[type]
    return url if url and url isnt "false"
    return false


  render_user_name : (contact, default_render) ->
    if contact?.fullname
      return contact.nickname || contact.fullname
    else
      return default_render if typeof default_render is "string"
      return default_render.name if default_render?.name
      return default_render.email if default_render?.email


  initialName: (name) ->
    return '' if _.isEmpty(name)
    split_name = _.compact name.split(/[", ]/)
    if split_name.length == 2
      gravatarName = (split_name[0][0] + split_name[1][0]).toUpperCase()
      longNameArray = new Array('MM','MN','WW','MW','WM','WN','NW','NM','GM')
      for item in longNameArray
        if(gravatarName == item)
          return gravatarName.substring(0,1)
      return gravatarName
    else
      split_name[0][0].toUpperCase()


  getDefaultUserBgColor: ->
    return 'bgcolor3'
