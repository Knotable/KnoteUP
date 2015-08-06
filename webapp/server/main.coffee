init_aws = ->
  Meteor.settings.AWS = {} unless Meteor.settings.AWS

  if Meteor.settings.AWS
    Meteor.settings.public ?= {}
    Meteor.settings.public.aws ?= {}
    Meteor.settings.public.aws.bucket = Meteor.settings.AWS.bucket

    ###
    AWS.config.update
      port: 443
      accessKeyId: Meteor.settings.AWS.accessKeyId
      secretAccessKey: Meteor.settings.AWS.secretAccessKey
    ###

logAnError = ->
  interval = 12
  log = ->
    console.error 'This message is logged intentionally. Do not consider this as a real error'

  log()

  Meteor.setInterval ->
    log()
  , interval * 60 * 60 * 1000


Meteor.startup ->
  startDate = new Date
  Meteor.settings.public.startedAt = startDate
  console.log 'METEOR SETTINGS: ', Meteor.settings

  logAnError()

  init_aws()

  Slingshot.fileRestrictions 'myFileUploads',
    allowedFileTypes: null
    maxSize: 10 * 1024 * 1024

  Slingshot.createDirective 'myFileUploads', Slingshot.S3Storage,
    bucket: Meteor.settings.AWS.bucket
    AWSAccessKeyId: Meteor.settings.AWS.accessKeyId
    AWSSecretAccessKey: Meteor.settings.AWS.secretAccessKey
    acl: 'public-read'
    authorize: (file,metaContext) ->
      #Deny uploads if user is not logged in.
      ### TODO can not get the userId even user has logged in. why?
      if !@userId
        message = 'Please login before posting files'
        throw new (Meteor.Error)('Login Required', message)
      ###
      true
    key: (file,metaContext) ->
      FileHelper.s3_key(metaContext.file_id,  file.name)
