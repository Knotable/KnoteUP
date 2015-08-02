init_aws = ->
  logger.info 'init aws'
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
  else
    logger.error "init_aws - AWS settings missing"



Meteor.startup ->
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
