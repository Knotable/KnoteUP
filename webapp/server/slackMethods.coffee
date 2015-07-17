Meteor.methods
  checkCurrentSlackCredentials: ->
    user = Meteor.user()
    slackAccessToken = user?.services?.slack?.accessToken
    return ok: false, error: 'not logged in slack' unless slackAccessToken
    postData = "token=#{slackAccessToken}"
    result = HTTP.post 'https://slack.com/api/auth.test', query: postData
    return _.pick result.data, 'ok', 'error' if result.data
    return ok: false, error: 'unable to parse the response'



  getListOfSlackChannels: ->
    user = Meteor.user()
    slackAccessToken = user?.services?.slack?.accessToken
    return [] unless slackAccessToken
    postData = "token=#{slackAccessToken}&exclude_archived=1"
    result = HTTP.post 'https://slack.com/api/channels.list', query: postData
    return result.data


  postOnSlack: (options) ->
    check options.title, String
    check options.text, String
    check options.channelId, String

    user = Meteor.user()
    slackAccessToken = user?.services?.slack?.accessToken
    return false unless slackAccessToken

    authorName = options.authorName or 'See progress on my queue at Knoteup'
    authorLink = options.authorLink or 'http://quick.knotable.com'
    check authorName, String
    check authorLink, String

    postData = "token=#{slackAccessToken}&channel=#{options.channelId}&as_user=true"
    attachments = [{
      fallback: "Posted via KnoteUp",
      color: "#2DACED",
      author_name: authorName,
      author_link: authorLink,
      author_icon: "http://d1wubs3nxxxkxo.cloudfront.net/static/public/images/chome_notification_icon.png",
      title: options.title,
      text: options.text,
      mrkdwn_in: ["text"]
    }]
    postData += "&attachments=#{encodeURIComponent JSON.stringify attachments}"
    result = HTTP.post 'https://slack.com/api/chat.postMessage', query: postData
    return result.data
