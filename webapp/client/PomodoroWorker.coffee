class @PomodoroWorker
  worker = null
  _instance = null



  constructor: ->
    return _instance if _instance
    _instance = @



  stopWorker: ->
    if worker
      worker.terminate()
      worker = null


  getWorker: ->
    return worker if worker
    worker = new Worker("/js/pomodoro_worker.js")



  isWorker: ->
    Boolean worker


@pomodoroWorker = new PomodoroWorker()