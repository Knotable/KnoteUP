@FileHelper =
  REGEXP_ALLOWED_GRAPHIC_EXTENTIONS: /\.(png|gif|jpg|jpeg|bmp)$/i
# Return extention of file
# Ex: file.pdf => return 'pdf' string
  fileExtention: (fileName) ->
    extension = ''
    if fileName and fileName.indexOf('.') > 0
      extension = fileName.split('.').pop()
      extension = extension.toLowerCase()
    return extension



  fileNameWithoutExtension: (fileName) ->
    index = fileName.lastIndexOf('.')
    if index > 0
      return fileName.substring(0, index)
    return fileName



# Check if file type is graphic file that Knotable support
# It only checks extension of file name, not content of file.
  isGraphic: (fileName) ->
    @REGEXP_ALLOWED_GRAPHIC_EXTENTIONS.test fileName if fileName


  isGraphicMime: (type) ->
    type in ['image/jpeg', 'image/png', 'image/jpg', 'image/gif']


  isImage: (name, type) ->
    @isGraphic(name) && @isGraphicMime(type)



# Get thumb icon for file type
  getThumbIcon: (fileName) ->
    extention = @fileExtention(fileName)
    thumbIcon = FILE_EXTENTION_THUMB_MAPPING['txt']
    if FILE_EXTENTION_THUMB_MAPPING[extention]
      thumbIcon = FILE_EXTENTION_THUMB_MAPPING[extention]
    return thumbIcon



  s3_key: (file_id, filename)->
    datePart = moment().format("YYYY-MM")
    "uploads/" + datePart + "/" + file_id + '_' + filename



  s3_thumb_key: (file_id, filename)->
    datePart = moment().format("YYYY-MM")
    "uploads/" + datePart + "/thumb/" + file_id + '_' + filename



  s3_url: (file_id, filename) ->
    bucket = Meteor.settings.public?.aws?.bucket
    "//#{bucket}.s3.amazonaws.com/" + @s3_key(file_id, filename)



  s3_thumb_url: (file_id, filename) ->
    bucket = Meteor.settings.public?.aws?.bucket
    "//#{bucket}.s3.amazonaws.com/" + @s3_thumb_key(file_id, filename)



  cdnUrl: (file_id, filename) ->
    domain = Meteor.settings.public?.aws?.cloudFrontDomain
    "//#{domain}/" + @s3_key(file_id, filename)



  cdnThumbUrl: (file_id, filename) ->
    domain = Meteor.settings.public?.aws?.cloudFrontDomain
    "//#{domain}/" + @s3_thumb_key(file_id, filename)



  cleanFileName: (filename) ->
    filename = filename.replace(/[^a-z0-9_\.\-]/gi, '_').toLowerCase()
    filename = filename.replace(/_{2,}/g, '_')
    filename.replace(/_\./g, '.')


#@FileHelper = ObjectProxy(FileHelper, 'FileHelper')
