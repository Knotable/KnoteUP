class KnotesRepository
  _initialization = false
  _draftKnoteExpiration = moment.duration(1, 'day')
  _currentUserKey = ''
  _repositoryStoreKey = 'knotesRepository'
  _draftKnotesKey = 'draftKnotes'
  _postTransactionsCount = 0
  _repository = null



  constructor: ->
    _repository = _repository or new Mongo.Collection null
    @_bindKnotesCursor()
    @_bindKnotesStorage()
    @_mapCollectionMethod()
    Tracker.autorun ->
      _currentUserKey = if Meteor.userId() then Meteor.userId() else ''



  insertKnote: (requiredKnoteParameters, optionalKnoteParameters) ->
    @_startPostTransaction()
    promise = KnoteHelper.postNewKnote(requiredKnoteParameters, optionalKnoteParameters)
    draftKnote = _.extend _.clone(requiredKnoteParameters), optionalKnoteParameters,
      isPosting: true
      archived: false
      isLocalKnote: true
      timestamp: Date.now()
      requiresPostProcessing: false
      requiredKnoteParameters: requiredKnoteParameters
      optionalKnoteParameters: optionalKnoteParameters
    draftKnoteId = _repository.insert draftKnote
    @_listenToPostCompletion(draftKnoteId, promise)
    return promise



  repostKnote: (knoteId) ->
    draftKnote = _repository.findOne(_id: knoteId, isLocalKnote: true)
    unless draftKnote
      deferred = $.Deferred()
      _.defer -> deferred.reject new Meteor.Error 'Knote not found'
      return deferred.promise()
    _repository.update knoteId, $set: isReposting: true
    @_startPostTransaction()
    promise = KnoteHelper.postNewKnote(draftKnote.requiredKnoteParameters, draftKnote.optionalKnoteParameters)
    @_listenToPostCompletion(draftKnote._id, promise)
    return promise



  _bindKnotesCursor: ->
    Knotes.find().observe
      added: (document) =>
        @_removeDraftKnoteIfExists(document)
        _repository.insert(document)
      changed: (newDocument) ->
        _repository.upsert(newDocument._id, newDocument)
      removed: (oldDocument) ->
        _repository.remove(oldDocument._id)



  _bindKnotesStorage: ->
    @_fillRepositoryWithDraftKnotes()
    _repository.find().observe
      added: @_updateStoredDocument.bind(@)
      changed: @_updateStoredDocument.bind(@)
      removed: (document) =>
        if document.isLocalKnote
          draftKnotes = amplify.store(@_getLocalStorageKey(_draftKnotesKey)) or {}
          delete draftKnotes[document._id] if draftKnotes[document._id]
          amplify.store(@_getLocalStorageKey(_draftKnotesKey), draftKnotes)



  _fillRepositoryWithDraftKnotes: ->
    draftKnotes = amplify.store(@_getLocalStorageKey(_draftKnotesKey))
    unless _.isEmpty(draftKnotes)
      now = moment()
      _.each _.clone(draftKnotes), (localKnote, key) ->
        if moment(localKnote.timestamp).add(_draftKnoteExpiration).isAfter(now)
          _repository.insert(localKnote)
        else
          delete draftKnotes[key]
      amplify.store(@_getLocalStorageKey(_draftKnotesKey), draftKnotes)



  _updateStoredDocument: (document) ->
    if document.isLocalKnote
      draftKnotes = amplify.store(@_getLocalStorageKey(_draftKnotesKey)) or {}
      draftKnotes[document._id] = document
      amplify.store(@_getLocalStorageKey(_draftKnotesKey), draftKnotes)



  _mapCollectionMethod: ->
    ['find', 'findOne'].forEach (methodName) =>
      @[methodName] = ->
        _repository[methodName]?.apply(_repository, arguments)



  _listenToPostCompletion: (draftKnoteId, promise) ->
    promise.always =>
      @_completePostTransaction()
    promise.fail (err) ->
      _repository.update(draftKnoteId, $set: isFailed: true, isPosting: false, isReposting: false)
      console.log err
    return promise



  _removeDraftKnoteIfExists: (knote) ->
    if @_isThereAnyTransaction()
      draftKnotes = _repository.find(isLocalKnote: true, {sort: timestamp: 1}).fetch()
      targetKnote = _.find draftKnotes, (draftKnote) ->  moment(draftKnote.date).isSame(knote.date, 'second')
      _repository.remove(targetKnote._id) if targetKnote



  _startPostTransaction: ->
    _postTransactionsCount++



  _completePostTransaction: ->
    _postTransactionsCount-- if _postTransactionsCount



  _isThereAnyTransaction: ->
    _postTransactionsCount



  _getLocalStorageKey: (subKey) ->
    [_currentUserKey, _repositoryStoreKey, subKey].join('.')



@knotesRepository = new KnotesRepository()