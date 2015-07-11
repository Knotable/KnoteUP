Meteor.methods
  checkCurrentSlackCredentials: ->
    console.log '#eluck# checkCurrentSlackCredentials - started'
    user = Meteor.user()
    slackAccessToken = user?.services?.slack?.accessToken
    return ok: false, error: 'not logged in slack' unless slackAccessToken
    postData = "token=#{slackAccessToken}"
    console.log '#eluck# checkCurrentSlackCredentials - post data:', postData
    result = HTTP.post 'https://slack.com/api/auth.test', query: postData
    console.log '\n\n#eluck# checkCurrentSlackCredentials - result.data:', result.data
    return _.pick result.data, 'ok', 'error' if result.data
    return ok: false, error: 'unable to parse the response'



  getListOfSlackChannels: ->
    console.log '#eluck# getListOfSlackChannels - started'
    user = Meteor.user()
    slackAccessToken = user?.services?.slack?.accessToken
    return [] unless slackAccessToken
    postData = "token=#{slackAccessToken}&exclude_archived=1"
#    console.log '#eluck# getListOfSlackChannels - post data:', postData
    result = HTTP.post 'https://slack.com/api/channels.list', query: postData
#    console.log '\n\n#eluck# getListOfSlackChannels - result.data:', result.data
    return result.data
