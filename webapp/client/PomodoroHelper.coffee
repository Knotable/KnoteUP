class PomodoroHelper
  pomodoroTimers = {}
  $favicon = null
  $pageTitle = null

  stopPomodoro: (knoteId)->
    return unless Meteor.userId() and knoteId
    if pomodoroTimers[knoteId]
      clearTimeout(pomodoroTimers[knoteId])
      delete pomodoroTimers[knoteId]
      user = AppHelper.currentContact()
      if user
        $pageTitle?.text('Knoteup - ' + user.username)
      else
        $pageTitle?.text('Knoteup')
      $favicon?.attr('href', '/favicon.ico')



  startPomodoro: (knoteId, $pomodoroTime, $pomodoro) ->
    return unless Meteor.userId() and knoteId
    $favicon = $('#favicon')
    $pageTitle = $('title')
    @stopPomodoro(knoteId)
    return unless pomorodo = Knotes.findOne({_id: knoteId})?.pomodoro
    pomodoroDate = moment(pomorodo.date).add(25, 'minutes')
    updateView($pomodoroTime, moment.duration(moment(pomodoroDate).subtract(new Date())).asSeconds())
    $favicon.attr('href', '/tomato-red.ico')
    func = =>
      time = moment.duration(moment(pomodoroDate).subtract(new Date())).asSeconds()
      if time <= 0
        Knotes.update {_id: knoteId}, {$unset: pomodoro: '' }
        @stopPomodoro(knoteId)
      else
        updateView($pomodoroTime, time, $pomodoro)
        pomodoroTimers[knoteId] = setTimeout func, 1000
    pomodoroTimers[knoteId] = setTimeout func, 1000



  updateView = ($pomodoroTime, pomodoroTime, $pomodoro) ->
    time = s2Str(pomodoroTime)
    $pomodoroTime?.html(time)
    $pageTitle?.text("Knoteup - #{time}")
    $pomodoro?.toggleClass('animate')
    if $pomodoro?.hasClass('animate')
      $favicon.attr('href', '/tomato-red.ico')
    else
      $favicon.attr('href', '/tomato.ico')


  s2Str = (seconds) ->
    sec = seconds % 60
    min = Math.floor(seconds / 60)
    sec = '0' + sec if sec < 10
    return min + ':' + sec



@pomodoroHelper = new PomodoroHelper()

