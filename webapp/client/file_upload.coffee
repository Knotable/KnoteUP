uploaderVar = new ReactiveVar()

KnoteAttachmentUploadHelper =
  afterUploadFileStatus: (status, index) ->
    if status and index and status != 'success'
      thumbBoxStatus = $(".thumb-box-status-" + index)
      if status == "fail"
        thumbBoxStatus.addClass("text-error")
        $('.thumb-box-' + index).addClass('upload-failed')
      else
        thumbBoxStatus.addClass("text-success")
      thumbBoxStatus.append("Upload " + status)



  afterComposeUploadFile: (parent, name, fileId, index, fileUrl) ->
      fileExtention = FileHelper.fileExtention(name)
      isPhoto = FileHelper.isGraphic(name)
      attach_button = parent.find(".upload-photo-btn-container")
      parent.append("<input type='hidden' name='file_ids' value='" + fileId + "' index='" + index + "'>")
      file_ids = parent.find("input[name='file_ids']").map(()-> return $(this).val())
      thumbBox = $(".thumb-box-" + index)
      if isPhoto
        knotableConnection.call "processThumbnailAsync", fileId, name, fileUrl, (e, r)->
          thumbBox.find("img.bar-loader")
            .attr("src", fileUrl) # Using original url instead of thumbnail ( r || fileUrl )
            .attr("file_id", fileId)
            .attr("img_src", fileUrl)
            .removeClass("loading")
            #.wrap("<a href='#{fileUrl}' target='_blank'></a>")
          thumbBox.removeClass("loading-thumb")
          parent.find('.compose-area').focus()
      else
        thumbBox.find(".loading-wrapper").remove()
        thumbBox.find("div.thumb").each ->
          unless $(this).hasClass("img-wrapper")
            fileImage = "<img src='#{CdnHelper.getCdnUrlOrAbsoluteUrl()}images/file_type_icon/archive.png' />"
            $(this).append("<a href='#{fileUrl}' target='_blank' class='file embedded-link'  title='#{name}' file_id='#{fileId}'>#{fileImage}</a>")
        thumbBox.removeClass("loading-thumb")
        parent.find('.compose-area').focus()

      thumbBox.find(".delete_file_ico").click () ->
        thumbBox.remove()
        parent.find("input[name='file_ids'][index='" + index + "']").remove()
        #TopicsHelper.updatePostingAccessibility()



###
#
  'availableOptions':
    className: ['', '']
    onRendered: ->
    afterInsertedAFile: (err, id, event, data) ->
    onSubmit: (event, data) ->
    beforeSubmit: (event, data, fileId) ->
    beforeSending: (event, data) ->
    failed: (event, data) ->
    done: (event, data) ->
#
###
uploadOptions =
  'uploadingKnoteAttachment':
    className: ['upload-photo-btn-container']

    onRendered: ->
      $(@find('.file_upload_s3')).prepend '<i class="upload-icon icon icon-attach" title="Upload"></i>'



    beforeSubmit: (event, data, fileId) ->
      index = Math.floor((Math.random()*10000000))
      data.index = index
      file = data.files[0]
      parent = $(event.target).closest(".files_holder")

      isImage = file.type.indexOf("image") >= 0

      $file = $(UI.toHTMLWithData Template.file_thumb_loading, {index: index, name: file.name, isImage:isImage})


      $fileContainer = parent.find('.file-container')
      if not $fileContainer.text().trim() and $fileContainer.find('.thumb').length is 0
        $fileContainer.empty()

      fileContainer = $fileContainer.append($file.clone()).get(0)
      fileContainer.appendChild document.createTextNode "\u00a0"  # $nbsp;

      AppHelper.setCursorOnContentEditable(fileContainer)


    failed: (event, data) ->
      KnoteAttachmentUploadHelper.afterUploadFileStatus("fail", data.index) if data.index


    done: (event, data) ->
      fileId = data.file_id
      fileName = data.file_name
      fileURL = "http:" + FileHelper.cdnUrl(data.file_id, data.file_name)

      $thumbBoxes = $(".thumb-box-#{data.index}")
      if $thumbBoxes.length
        knoteId = $thumbBoxes.closest('.message[data-id]').data('id')
        if knoteId
          isPhoto = FileHelper.isGraphic(fileName)
          if isPhoto
            knotableConnection.call "processThumbnailAsync", fileId, fileName, fileURL, (e, thumbUrl)->
              $thumbBoxes.find("img.bar-loader")
                .attr("src", thumbUrl || fileURL)
                .removeClass("loading")
                .addClass('thumb')
                .wrap("<a href='#{fileURL}' onclick='javascript:;' class='embedded-link'></a>")
              $thumbBoxes.removeClass("loading-thumb")
          else
            $file = $thumbBoxes.find(".img-wrapper .thumb")
            $file.find("img.bar-loader").remove()
            fileImage = "<img src='#{CdnHelper.getCdnUrlOrAbsoluteUrl()}images/file_type_icon/archive.png' />"
            $file.append("<a href='#{fileURL}' class='file embedded-link' title='#{fileName}' target='_blank' file_id='#{fileId}'>#{fileImage}</a>")
            $thumbBoxes.removeClass("loading-thumb")
            $thumbBoxes.find(".loading-wrapper").remove()
          $thumbBoxes.find('input[name=file_ids]').val(fileId)
          try
            KnoteAttachmentUploadHelper.afterUploadFileStatus(data.textStatus, data.index)
          catch e
            console.log 'File uploading error', e.stack or e
        else
          parent = $(event.target).closest(".files_holder")
          KnoteAttachmentUploadHelper.afterComposeUploadFile(parent, fileName, fileId, data.index, fileURL)
          KnoteAttachmentUploadHelper.afterUploadFileStatus(data.textStatus, data.index)

      # TODO
      # knotableConnection.call('update_short_photo_url', Session.get('subject_id'), fileId) if fileId
      # TopicsHelper.updatePostingAccessibility()
      knotableConnection.subscribe 'fileById', fileId



getFileUploadOptions = (uploadForm) ->
  if uploadForm.parents('.compose, .knote').length
    uploadOptions['uploadingKnoteAttachment']



Template.file_upload.events
  'click .upload-icon': (e) ->
    return unless Meteor.user()
    $(e.currentTarget).siblings('input[name=file]').click()

  'click .upload-photo-btn-large': (e)->
    e.stopPropagation()



Template.file_upload.helpers
  bucket: ->
    Meteor.settings.public.aws?.bucket


  s3_credentials: ->
    if S3Credentials.areReady()
      S3Credentials.getCredentials()


  fileUpload : ->
    {
      action : "//" + Meteor.settings.public.aws?.bucket + ".s3.amazonaws.com/"
      isS3_credentials : true
    }


Template.file_upload.onRendered ->
  $form = $(@find '.file_upload_s3')
  options = getFileUploadOptions $form
  return unless options
  if options.className?.length
    $form.addClass options.className.join(' ')

  options.onRendered?.call @

  $form.on 'drop', (e) ->
    return unless e.originalEvent.dataTransfer?.files.length
    e.preventDefault()
    return false

  $form.bind 'fileuploadprogress', (e , data)->
    fileUploading = Session.get('fileUploading') or {}

    progress = data._progress
    process = progress.loaded / progress.total * 100

    fileUploading[data.file_id] = {
      process : process
      name: data.file_name
    }
    Session.set('fileUploading' , fileUploading)


  @autorun ->
    if S3Credentials.areReady()
      Meteor.defer -> initFileuploader $form, options



initFileuploader = ($form, options) ->
  $form.fileupload
    autoUpload: true,


    add: (event, data) ->
      # Change made by Duc Duong to fix the error that cannot upload attachment to a knote when editing
      # Card: https://trello.com/c/4QHdhlJy/6200-i-cannot-add-attachments-to-knotes-i-am-editing
      eventDataId = $(event.delegatedEvent.target).closest(".likeable").attr("data-id")
      formDataId = $form.closest(".likeable").attr("data-id")
      return if eventDataId and formDataId and eventDataId isnt formDataId

      return if event.delegatedEvent.type is 'drop' and
              $(event.target).closest('#compose-popup').length and
              $('.message.in-edit').length

      $composePopup = $(event.target).closest('#compose-popup')
      $composePopup.find('#message-textarea')?.show() if $composePopup

      file = data.files[0]
      fileName = FileHelper.cleanFileName file.name
      file_id = Files.insert
        name: file.name
        account_id: AppHelper.currentAccount()?._id
        type: file.type
        size: file.size
        created_time: new Date()
      $form = $('.file_upload_s3')
      if $form.parents('.key-note, .message, #compose-popup, .knote').length
        ############################################
        index = Math.floor((Math.random()*10000000))
        file = data.files[0]
        parent = $(event.target).closest(".files_holder")

        isImage = file.type.indexOf("image") >= 0

        $file = $(UI.toHTMLWithData Template.file_thumb_loading, {index: index, name: file.name, isImage:isImage})


        $fileContainer = parent.find('.file-container')
        if not $fileContainer.text().trim() and $fileContainer.find('.thumb').length is 0
          $fileContainer.empty()

        fileContainer = $fileContainer.append($file.clone()).get(0)
        fileContainer.appendChild document.createTextNode "\u00a0"  # $nbsp;

        $('.post-knote').attr('disabled', 'disable')

        AppHelper.setCursorOnContentEditable(fileContainer)


        ############################################
        metaContext = {'file_id':file_id}
        uploader = new (Slingshot.Upload)('myFileUploads',metaContext)
        uploader.send file, (error, downloadUrl) ->
          if error
            # Log service detailed response
            #console.error 'Error uploading', uploader.xhr.response
            fileUploading = uploaderVar
            if fileUploading[file_id]
              delete fileUploading[file_id]
            uploaderVar.set(fileUploading)
            console.log error
          else
            url = "http:" + FileHelper.cdnUrl(file_id, file.name)
            url = encodeURI url
            Files.update file_id,
              $set:
                s3_url: url
            , (err) ->
              console.error err if err
            fileId = file_id
            fileName = file.name
            fileURL = url
            $thumbBoxes = $(".thumb-box-#{index}")
            console.log $thumbBoxes,$(".thumb-box-#{index}")


            if $thumbBoxes.length
              knoteId = $thumbBoxes.closest('.message[data-id]').data('id')
              if true
              #if knoteId
                isPhoto = FileHelper.isGraphic(fileName)
                if isPhoto
                  knotableConnection.call "processThumbnailAsync", fileId, fileName, fileURL, (e, thumbUrl)->
                    $thumbBoxes.find("img.bar-loader")
                    .attr("src", thumbUrl || fileURL)
                    .removeClass("loading")
                    .addClass('thumb')
                    .wrap("<a href='#{fileURL}' onclick='javascript:;' class='embedded-link'></a>")
                    $thumbBoxes.removeClass("loading-thumb")
                    fileUploading = uploaderVar
                    if fileUploading[file_id]
                      delete fileUploading[file_id]
                    uploaderVar.set(fileUploading)
                    $('.post-new-knote').removeAttr('disabled')
                else
                  $file = $thumbBoxes.find(".img-wrapper .thumb")
                  $file.find("img.bar-loader").remove()
                  fileImage = "<img src='#{CdnHelper.getCdnUrlOrAbsoluteUrl()}images/file_type_icon/archive.png' />"
                  $file.append("<a href='#{fileURL}' class='file embedded-link' title='#{fileName}' target='_blank' file_id='#{fileId}'>#{fileImage}</a>")
                  $thumbBoxes.removeClass("loading-thumb")
                  $thumbBoxes.find(".loading-wrapper").remove()
                  fileUploading = uploaderVar
                  if fileUploading[file_id]
                    delete fileUploading[file_id]
                  uploaderVar.set(fileUploading)
                  $('.post-new-knote').removeAttr('disabled')
                $thumbBoxes.find('input[name=file_ids]').val(fileId)
              else
                parent = $(event.target).closest(".files_holder")
                KnoteAttachmentUploadHelper.afterComposeUploadFile(parent, fileName, fileId, data.index, fileURL)
                #KnoteAttachmentUploadHelper.afterUploadFileStatus(data.textStatus, data.index)

            #knotableConnection.call('update_short_photo_url', Session.get('subject_id'), fileId) if fileId
            #TopicsHelper.updatePostingAccessibility()
            knotableConnection.subscribe 'fileById', fileId
            #fileUploading = uploaderVar
            #if fileUploading[file_id]
            #  delete fileUploading[file_id]
            #uploaderVar.set(fileUploading)
          return
        fileUploading = uploaderVar or {}
        fileUploading[file_id] = {
          'uploader' : uploader,
          'name' : file.name
        }
        uploaderVar.set(fileUploading)
        return

      file_key = FileHelper.s3_key(file_id, fileName)
      $form.find("input[name=key]").val(file_key)
      $form.find("input[name=Content-Type]").val(file.type)

      data.file_id = file_id
      data.file_name = fileName

      if options.beforeSubmit?.call(@, event, data) != false
        data.submit()


    submit: options.onSubmit


    send:   options.beforeSending


    fail: (event, data) ->
      errorData =
        S3Credentials: S3Credentials.credentials
        formData:
          s3_key: $form.find("input[name=AWSAccessKeyId]").val()
          s3_policy: $form.find("input[name=policy]").val()
          s3_signature: $form.find("input[name=signature]").val()
      errorData.formDataAndRealDataComparison =
          areS3PoliciesEqual: errorData.S3Credentials?.s3_policy == errorData.formData.s3_policy
          areS3KeysEqual: errorData.S3Credentials?.s3_key == errorData.formData.s3_key
          areS3SignaturesEqual: errorData.S3Credentials?.s3_signature == errorData.formData.s3_signature

      knotableConnection.call 'fileUploadFailed', errorData
      #LoggingHelper.trace('Error: file upload failed - errorData:', errorData)
      options.failed(event, data)

      if fileUploading = Session.get('fileUploading')
        if fileUploading[data.file_id]
          delete fileUploading[data.file_id]
          Session.set('fileUploading' , fileUploading)


    done: (event, data) ->
      url = "http:" + FileHelper.cdnUrl(data.file_id, data.file_name)
      url = encodeURI url
      _this = @

      Files.update data.file_id,
        $set:
          s3_url: url
      , (err, result) ->
        options.afterInsertedAFile?.call _this, err, data.file_id, event

      options.done?.call @, event, data

      if fileUploading = Session.get('fileUploading')
        if fileUploading[data.file_id]
          delete fileUploading[data.file_id]
          Session.set('fileUploading' , fileUploading)
