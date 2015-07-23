@SelectionTextHelper =
  getSelectionData: ->
    if document.getSelection
      range = document.getSelection().getRangeAt 0
      r = range.cloneRange()
      if r.startOffset != r.endOffset
        throw 'incorrect cursor position'
      data = pos: r.startOffset, node: r.startContainer, text: r.startContainer.nodeValue
    else if document.selection
      range = document.selection.createRange()
      textRange = document.body.createTextRange()
      textRange.moveToElementText(range.startContainer)
      textRange.setEndPoint("EndToStart", selectedTextRange)
      data = pos: textRange.text.length, node: range.startContainer, text: range.startContainer.nodeValue
    else
      throw 'Cannot retrieve selection data'
    return data



  setCursorAt: (pos, elem) ->
    if document.createRange
      charIndex = 0
      nodeStack = [elem]
      stop = false
      range = document.createRange()
      range.setStart(elem, 0)
      range.collapse(true)

      while !stop && (node = nodeStack.pop())
        if node.nodeType == 3
          nextCharIndex = charIndex + node.length
          if pos >= charIndex && pos <= nextCharIndex
            range.setStart(node, pos - charIndex)
            range.setEnd(node, pos - charIndex)
            stop = true
          charIndex = nextCharIndex
        else
          i = node.childNodes.length
          while i--
            nodeStack.push node.childNodes[i]

      sel = window.getSelection()
      sel.removeAllRanges()
      sel.addRange range
    else if document.selection
      range = document.body.createTextRange()
      range.moveToElementText(elem)
      range.collapse(true)
      range.moveEnd("character", pos)
      range.moveStart("character", pos)
      range.select()
    else
      throw 'Cannot set cursor'
