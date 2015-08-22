class @PomodoroHelper
  pomodoroWorker = null
  tomatoSeconds = 25 * 60


  stopPomodoro: ->
    return unless Meteor.userId()
    if pomodoroWorker
      pomodoroWorker.terminate()
      pomodoroWorker = null
    $(@).trigger('stop')



  startPomodoro: (knoteId) ->
    return unless Meteor.userId() and knoteId
    time = @getPomodoroTime(knoteId)
    setTimeout =>

      pomodoroWorker = new Worker("/js/pomodoro_worker.js")
      pomodoroWorker.onmessage = (event) =>
        if event.data > time
          $(@).trigger('flushing', s2Str(0))
        else
          $(@).trigger('running', s2Str(time - event.data) )
    , 0



  getPomodoroTime: (knoteId) ->
   if pomodoro = Knotes.findOne(_id: knoteId)?.pomodoro
     return pomodoro.pauseTime if pomodoro.pauseTime
     newTime = moment(pomodoro.date).add(tomatoSeconds, 'seconds')
     if moment().isBefore(newTime)
      return moment.duration(moment(newTime).subtract(new Date())).asSeconds()
   0



  pomodoroPause: (knoteId) ->
    return unless pomodoro = Knotes.findOne(_id: knoteId)?.pomodoro
    time = @getPomodoroTime(knoteId)
    pomodoro.pauseTime = time
    Knotes.update {_id: knoteId}, {$set: {pomodoro: pomodoro} }



  clickOnTomato: (knoteId) ->
    if pomodoro = Knotes.findOne(_id: knoteId)?.pomodoro
      if pomodoroWorker
        return if pomodoro.pauseTime
        return @pomodoroPause(knoteId) if @getPomodoroTime(knoteId) > 0
        return Knotes.update {_id: knoteId}, {$unset: pomodoro: ''}
      if pomodoro.pauseTime
        newPomodoro =
         userId: pomodoro.userId
         date: moment().subtract(tomatoSeconds - pomodoro.pauseTime, 'seconds').toDate()
        return Knotes.update {_id: knoteId}, {$set: pomodoro: newPomodoro }
    return if pomodoroWorker
    pomodoro =
      userId: Meteor.userId()
      date: new Date()
    Knotes.update {_id: knoteId}, {$set: pomodoro: pomodoro }



  s2Str = (seconds) ->
    sec = seconds % 60
    min = Math.floor(seconds / 60)
    sec = '0' + sec if sec < 10
    return min + ':' + sec



@pomodoroHelper = new @PomodoroHelper()

