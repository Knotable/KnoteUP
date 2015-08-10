@knoteupConnection = Accounts.connection

Meteor.settings.public.remoteHost ?= 'beta.knotable.com'
remoteServerUrl = Meteor.settings.public.remoteHost
@knotableConnection = DDP.connect(remoteServerUrl)

Meteor.remoteConnection = knotableConnection
Accounts.connection = knotableConnection



Meteor.users = new Mongo.Collection 'users', connection: knotableConnection
@UserAccounts = new Meteor.Collection "user_accounts", connection: knotableConnection
@Pads = new Meteor.Collection "topics", connection: knotableConnection
@Files = new Meteor.Collection "files", connection: knotableConnection


@Knotes = new Meteor.Collection "knotes",
  connection: knotableConnection
  transform: (knote) ->
    if knote.timestamp
      nowDate = moment()
      knoteDate = moment(knote.timestamp)
      if nowDate.year() isnt knoteDate.year()
        format = 'MMM DD, YYYY [at] ha'
        formatedDate = knoteDate.format(format)
      if nowDate.isSame(knoteDate, 'day')
        formatedDate = knoteDate.format('[today at] ha')
      formatedDate ?= knoteDate.format('MMM DD [at] ha')
      knote.formatedDate = formatedDate || ''
    knote.from = knote.from.address if knote.from and _.isObject knote.from
    return knote


@Contacts = new Meteor.Collection "contacts",
  connection: knotableConnection
  transform: (contact) ->
    contact.hasAvatar = if contact.avatar
      true
    else
      false
    name = contact.nickname || contact.fullname || contact.username
    contact.initialName = name[0].toUpperCase()
    return contact


@SharingKeys = new Meteor.Collection "sharing_keys", connection: knoteupConnection





class KnotesRepository
  _repository = null



  constructor: ->
    _repository = _repository or new Mongo.Collection null
    Knotes.find().observe
      added: (document) ->
        _repository.insert(document)

      changed: (newDocument) ->
        _repository.upsert(newDocument._id, newDocument)

      removed: (oldDocument) ->
        _repository.remove(oldDocument._id)

    ['find', 'findOne'].forEach (methodName) =>
      @[methodName] = ->
        _repository[methodName]?.apply(_repository, arguments)



  insertKnote: (requiredKnoteParameters, optionalKnoteParameters) ->
    promise = KnoteHelper.postNewKnote(requiredKnoteParameters, optionalKnoteParameters)
    draftKnote = _.extend _.clone(requiredKnoteParameters), optionalKnoteParameters,
      isPosting: true
      archived: false
      requiredKnoteParameters: requiredKnoteParameters
      optionalKnoteParameters: optionalKnoteParameters
    console.log 'draft knote', draftKnote
    draftKnoteId = _repository.insert draftKnote, (e, r) -> console.log '_repository insert', e, r
    promise.done (knoteId) ->
      console.log 'done', knoteId
      _repository.remove(draftKnoteId)
    promise.fail (err) ->
      console.log 'fail', err
      _repository.update(draftKnoteId, $set: isFailed: true, isPosting: false)
    promise



@knotesRepository = new KnotesRepository()