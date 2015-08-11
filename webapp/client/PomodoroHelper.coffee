class PomodoroHelper
  pomodoroTimers = {}


  stopPomodoro: (knoteId)->
    return unless Meteor.userId() and knoteId
    if pomodoroTimers[knoteId]
      clearTimeout(pomodoroTimers[knoteId])
      delete pomodoroTimers[knoteId]
      user = AppHelper.currentContact()
      if user
        $('title').text('Knoteup - ' + user.username)
      else
        $('title').text('Knoteup')
      $('#favicon').attr('href', '/favicon.ico')



  startPomodoro: (knoteId, $pomodoroTime) ->
    return unless Meteor.userId() and knoteId
    @stopPomodoro(knoteId)
    return unless pomorodo = Knotes.findOne({_id: knoteId})?.pomodoro
    pomodoroDate = moment(pomorodo.date).add(25, 'minutes')
    updateView($pomodoroTime, moment.duration(moment(pomodoroDate).subtract(new Date())).asSeconds())
    $('#favicon').attr('href', '/tomato-red.ico')
    func = =>
      time = moment.duration(moment(pomodoroDate).subtract(new Date())).asSeconds()
      if time <= 0
        Knotes.update {_id: knoteId}, {$unset: pomodoro: '' }
        @stopPomodoro(knoteId)
      else
        updateView($pomodoroTime, time)
        pomodoroTimers[knoteId] = setTimeout func, 1000
    pomodoroTimers[knoteId] = setTimeout func, 1000



  updateView = ($pomodoroTime, pomodoroTime) ->
    time = s2Str(pomodoroTime)
    $pomodoroTime?.html(time)
    $('title').text("Knoteup - #{time}")



  s2Str = (seconds) ->
    sec = seconds % 60
    min = Math.floor(seconds / 60)
    sec = '0' + sec if sec < 10
    return min + ':' + sec



@pomodoroHelper = new PomodoroHelper()

