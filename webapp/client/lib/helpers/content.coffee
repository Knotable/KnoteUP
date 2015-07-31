class ContentHelper
  linkifyDOM: (domFragment) ->
    return unless domFragment
    initDomIterator.call @, domFragment, NodeFilter.SHOW_TEXT
    uriRegExp = new RegExp(CommonRegularExpressions.uri, "ig")
    emailRegExp = new RegExp(CommonRegularExpressions.email, 'i')
    schemeRegExp = new RegExp('^(' + CommonRegularExpressions.scheme + '|mailto:)', 'i')

    while textNode  = next.call @
      continue if checkAllParentNodes 'a', textNode

      text = textNode.textContent
      docFragment = document.createDocumentFragment()
      prevIndex = 0
      uriRegExp.lastIndex = 0
      while res = uriRegExp.exec text
        uri = res[0]
        linkText = uri.replace schemeRegExp, ''
        addText = ''
        unless (uri.indexOf(':') + 1)
          if uri.match(emailRegExp)
            addText = 'mailto:'
            uri = addText + uri
          else
            addText = 'http://'
            uri = addText + uri
        startText = text.substring prevIndex, res.index
        prevIndex = res.index + uri.length - addText.length
        if startText
          docFragment.appendChild createTextNode startText
        docFragment.appendChild createLinkNode uri, linkText, '_blank'

      if docFragment.hasChildNodes()
        if prevIndex < text.length
          docFragment.appendChild(createTextNode text.substr prevIndex)
        replaceNode docFragment, textNode



  formatImagesDOM: (domFragment) ->
    return unless domFragment
    initDomIterator.call @, domFragment, NodeFilter.SHOW_ELEMENT, 'img'

    while imgNode = next.call @
      continue if imgNode.parentNode.className.indexOf('img-wrapper') >= 0
      # set max-height of image to 500px
      imgNode.style.maxHeight = "500px"
      #if parseInt(imgNode.width) > 400 and parseInt(imgNode.width) > 0
        #imgNode.height = imgNode.height / 400 * imgNode.width
        #imgNode.width = 400
      span = createElement 'span', 'btn-close', 'contenteditable': false

      imgWrapper = createElement 'span', 'img-wrapper', 'contenteditable': false
      imgWrapper.appendChild span
      replaceNode imgWrapper, imgNode
      imgWrapper.appendChild imgNode



  formatLinksDOM: (domFragment) ->
    return unless domFragment
    initDomIterator.call @, domFragment, NodeFilter.SHOW_ELEMENT, 'a'
    schemeRegExp = new RegExp('^(' + CommonRegularExpressions.scheme + '|mailto:)', 'i')

    while aNode = next.call @
      href = aNode.href
      aNode.removeAttribute 'style'

      node = $(aNode)
      if nodeText = node.text()
        node.text nodeText.replace(schemeRegExp, '')

      continue if href.indexOf(CommonRegularExpressions.mailto) > -1

      if href.indexOf('://') < 0
        aNode.setAttribute 'href', "http://#{href}"

      aNode.setAttribute 'target', '_blank'



  convertLinksToText : (container) ->
    $(container).find('a').each ->
      linkHref = $(this).attr('href')
      if linkHref.startWith "mailto:"
        return
      $parent = $(this).parent()
      if $parent.prop("tagName") == "div" && $parent.hasClass("embed")
        $(this).parent().replaceWith $(this).append("<br/>").html()
      else if $parent.attr('contenteditable')
        $(this).parent().replaceWith(linkHref)
      else
        $(this).replaceWith(linkHref)



#***** private *****
  initDomIterator = (input, filter, tagName) ->
    @iterator = document.createNodeIterator input, filter, null, false

    if tagName and NodeFilter.SHOW_ELEMENT & filter
      tagNameRegexp = new RegExp "^(#{tagName})$", 'gi'
      _nextNode = @iterator.nextNode
      self = @
      @iterator.nextNode = ->
        while node = _nextNode.apply self.iterator
          return node if tagNameRegexp.test node.tagName

    @cachedNode = @iterator.nextNode()



  next = ->
    node = @cachedNode
    @cachedNode = @iterator.nextNode()
    node



  checkParentNode = (parentTagName, child) ->
    (p = child.parentNode) and p.tagName.toLowerCase() is parentTagName.toLowerCase()



  checkAllParentNodes = (parentTagName, child) ->
    result = false
    p = child
    while p = p.parentNode
      if p.tagName?.toLowerCase() is parentTagName.toLowerCase()
        result = true

    result



  createLinkNode = (href, text, target, alt) ->
    a = document.createElement 'A'
    a.href = href
    a.innerText = text || href
    if target
      a.setAttribute 'target', target
    if alt
      a.setAttribute 'alt', alt
    return a



  createTextNode = (text) ->
    document.createTextNode text



  createElement = (tagName, className, attrs) ->
    node = document.createElement tagName
    if className
      node.className = className
    if attrs and typeof attrs is 'object'
      for attr of attrs
        node.setAttribute(attr, attrs[attr])
    node



  replaceNode = (newNode, oldNode) ->
    if p = oldNode.parentNode
      p.replaceChild newNode, oldNode

      


@contentHelper = new ContentHelper()
