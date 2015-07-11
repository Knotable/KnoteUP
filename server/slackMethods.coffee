Meteor.methods
  checkCurrentSlackCredentials: ->
    console.log '#eluck# checkCurrentSlackCredentials - launched'
    user = Meteor.user()
    slackAccessToken = user?.services?.slack?.accessToken
    return unless slackAccessToken
    result = HTTP.post 'https://slack.com/api/auth.test', data: token: slackAccessToken
    console.log '#eluck# checkCurrentSlackCredentials - result:', result
    console.log '\n\n#eluck# checkCurrentSlackCredentials - result.data:', result.data
    return _.pick result.data, 'ok', 'error' if result.data
    return ok: false, error: 'unable to parse the response'



  getListOfSlackChannels: ->
    return unless Meteor.userId()
    return []
