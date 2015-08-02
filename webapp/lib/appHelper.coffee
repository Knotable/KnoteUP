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
