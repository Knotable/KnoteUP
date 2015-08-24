Template.avatar.helpers
  'currentUserClass': ->
    currentContactId = AppHelper.currentContact()?._id
    if currentContactId and currentContactId is @_id
      "account-avatar-current"

  'avatar_src': ->
    type = if @showSmallAvatar then 'mini'
    AppHelper.getAvatarUrlOfContact @, type


  'get_username': ->
    AppHelper.render_user_name @, 'anonymous'


  'initial_name': ->
    unless _.isEmpty @
      AppHelper.initialName AppHelper.render_user_name @
    else
      '?'


  'get_bgcolor': ->
    @bgcolor || AppHelper.getDefaultUserBgColor()


  'email': ->
    @emails?[0] or ''


  'is_activated': ->
    not @hasOwnProperty('is_activated') or @is_activated

  'title': ->
    "We couldn't figure out who sent this message originally." if _.isEmpty(@)



Template.suggestion_avatar.helpers
  avatarPath: -> AppHelper.getAvatarUrlOfContact @contact, 'mini'
  initialName: -> AppHelper.initialName(@contact.fullname)
