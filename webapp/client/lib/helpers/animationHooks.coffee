@AnimationHooks =

  moveKnote: (node, next) ->
    console.log("moveKnote fired")
    $node = $(node)
    $next = $(next)
    oldTop = $node.offset().top
    height = $node.outerHeight(true)

    # // find all the elements between next and node
    $inBetween = $next.nextUntil(node)
    if $inBetween.length is 0
      $inBetween = $node.nextUntil(next)
    # // now put node in place
    $node.insertBefore(next)
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
    $node.addClass('animate').css('top', 0)
    $inBetween.addClass('animate').css('top', 0)
