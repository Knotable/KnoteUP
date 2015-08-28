class @PomodoroController extends BaseController
  tomatoSeconds = 25 * 60

  extend: (template) =>
    @_setupControllerDependencies(template, @)
    return template



  stopPomodoro: =>
    pomodoroWorker.stopWorker()
    $(@).trigger('stop')



  startPomodoro: (knoteId) =>
    time = @_getPomodoroTime(knoteId)
    setTimeout =>
      pWorker = pomodoroWorker.getWorker()
      pWorker.onmessage = (event) =>
        if event.data > time
          $(@).trigger('flushing', s2Str(0))
        else
          $(@).trigger('running', s2Str(time - event.data))
    , 0



  pausePomodoro: (knoteId) =>
    return unless pomodoro = Knotes.findOne(_id: knoteId)?.pomodoro
    return unless time = pomodoro?.pauseTime
    @stopPomodoro()
    $(@).trigger('pause', s2Str(tomatoSeconds - 1 - (tomatoSeconds - time)))



  clickOnTomato: (knoteId) =>
    if pomodoro = Knotes.findOne(_id: knoteId)?.pomodoro
      if pomodoroWorker.isWorker()
        return if pomodoro.pauseTime
        return @_setPause(knoteId) if @_getPomodoroTime(knoteId) > 0
        @stopPomodoro()
        return Knotes.update {_id: knoteId}, {$unset: pomodoro: ''}
      if pomodoro.pauseTime
        newPomodoro =
         userId: pomodoro.userId
         date: moment().subtract(tomatoSeconds - pomodoro.pauseTime, 'seconds').toDate()
        return Knotes.update {_id: knoteId}, {$set: pomodoro: newPomodoro }
    return if pomodoroWorker.isWorker()
    pomodoro =
      userId: Meteor.userId()
      date: new Date()
    Knotes.update {_id: knoteId}, {$set: pomodoro: pomodoro }



  _getPomodoroTime: (knoteId) =>
    if pomodoro = Knotes.findOne(_id: knoteId)?.pomodoro
      return pomodoro.pauseTime if pomodoro.pauseTime
      newTime = moment(pomodoro.date).add(tomatoSeconds, 'seconds')
      if moment().isBefore(newTime)
        return moment.duration(moment(newTime).subtract(new Date())).asSeconds()
    0



  _setPause: (knoteId) =>
    return unless pomodoro = Knotes.findOne(_id: knoteId)?.pomodoro
    time = @_getPomodoroTime(knoteId)
    pomodoro.pauseTime = time
    Knotes.update {_id: knoteId}, {$set: {pomodoro: pomodoro} }



  s2Str = (seconds) ->
    sec = seconds % 60
    min = Math.floor(seconds / 60)
    sec = '0' + sec if sec < 10
    return min + ':' + sec


