@ModalHelper =

  showModal: (type) ->
    $modal = $('.user-modal')
    $modal.addClass('is-visible')
    Session.set 'modalType', type
    if type == 'welcome'
      Session.set 'welcome', true
    else
      Session.set 'welcome', false
      $modal.find('#login-username').focus()


  initWelcome: ->
    carousel = $(".owl-carousel")
    carousel.owlCarousel(
      margin: 50,
      nav: true,
      autoWidth: true,
      center: true,
      responsiveClass: true,
      responsive: {
        5000: {
          items: 1,
          nav: true
        }
      }
    )
    carousel.on('changed.owl.carousel', (event) ->
      total = event.item.count - 1
      current = event.item.index
      if current == 0
        $('.owl-prev').hide()
      else
        $('.owl-prev').css('display', 'inline-block')
      if total == current
        $('.owl-next').hide()
      else
        $('.owl-next').css('display', 'inline-block')
    )
