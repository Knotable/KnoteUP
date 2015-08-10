class KnotesRepository
  _initialization = false
  _repositoryStoreKey = 'local_draft_knotes_repo'
  _repository = null



  constructor: ->
    _repository = _repository or new Mongo.Collection null
    @_bindKnotesCursor()
    @_bindKnotesStorage()
    @_mapCollectionMethod()



  insertKnote: (requiredKnoteParameters, optionalKnoteParameters) ->
    promise = KnoteHelper.postNewKnote(requiredKnoteParameters, optionalKnoteParameters)
    draftKnote = _.extend _.clone(requiredKnoteParameters), optionalKnoteParameters,
      isPosting: true
      archived: false
      isLocalKnote: true
      timestamp: Date.now()
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
    promise = KnoteHelper.postNewKnote(draftKnote.requiredKnoteParameters, draftKnote.optionalKnoteParameters)
    @_listenToPostCompletion(draftKnote._id, promise)
    return promise



  _bindKnotesCursor: ->
    Knotes.find().observe
      added: (document) ->
        _repository.insert(document)
      changed: (newDocument) ->
        _repository.upsert(newDocument._id, newDocument)
      removed: (oldDocument) ->
        _repository.remove(oldDocument._id)



  _bindKnotesStorage: ->
    draftKnotes = amplify.store(_repositoryStoreKey)
    unless _.isEmpty(draftKnotes)
      _.each draftKnotes, (localKnote) ->
        _repository.insert(localKnote)
    _repository.find().observe
      added: @_updateStoredDocument
      changed: @_updateStoredDocument
      removed: (document) ->
        if document.isLocalKnote
          draftKnotes = amplify.store(_repositoryStoreKey) or {}
          delete draftKnotes[document._id] if draftKnotes[document._id]
          amplify.store(_repositoryStoreKey, draftKnotes)



  _updateStoredDocument: (document) ->
    if document.isLocalKnote
      draftKnotes = amplify.store(_repositoryStoreKey) or {}
      draftKnotes[document._id] = document
      amplify.store(_repositoryStoreKey, draftKnotes)



  _mapCollectionMethod: ->
    ['find', 'findOne'].forEach (methodName) =>
      @[methodName] = ->
        _repository[methodName]?.apply(_repository, arguments)



  _listenToPostCompletion: (draftKnoteId, promise) ->
    promise.done ->
      _repository.remove(draftKnoteId)
    promise.fail (err) ->
      _repository.update(draftKnoteId, $set: isFailed: true, isPosting: false, isReposting: false)
      console.log err
    return promise



@knotesRepository = new KnotesRepository()