class @SharePadPopup
  @id = '#share-pad-popup'
  @parent = 'body'
  @activeInstance = null


  constructor: (data = {}) ->
    return false unless data.padId
    removeInstanceIfExists $ SharePadPopup.id
    data.SharePadPopup = @
    if data.shareLink
      data.url = UrlHelper.getPadUrlFromId data.padId
    UI.renderWithData Template.sharePadPopup, data, $(SharePadPopup.parent)[0]
    SharePadPopup.activeInstance = @
    @$popup = $ SharePadPopup.id


  removeInstanceIfExists = ($popup) ->
    $popup.remove() if $popup.length
    SharePadPopup.activeInstance = null


  show: ->
    @$popup.lightbox_me
      centered: true


  close: ->
    @$popup.trigger 'close'


Template.sharePadPopup.helpers
  copySupported: ->
    !document.queryCommandSupported?('copy')


Template.sharePadPopup.onRendered ->
  @find('.shared-url')?.select()


Template.sharePadPopup.events
  'click .btn-cancel-share': ->
    SharePadPopup.activeInstance.close()

  'click .icon-docs': ->
    document.execCommand 'copy'

  'click .shared-url': (e) ->
    e.currentTarget.select()

  'click .btn-share': (e, template) ->
    message = template.$('.share-message').val()
    emails = template.$('#shareEmails input').val()
    emails = emails.split(',')
    emails = _.select emails, (email) ->
      email.match(/[\w-]+@([\w-]+\.)+[\w-]+/)
    emails = _.map emails, (email) -> $.trim(email)
    if emails.length
      Meteor.remoteConnection.call 'addContactsToThread', template.data.padId, emails, {message: message}, (error, result) ->
        if error
          showWarningMessage 'Add contact to pad failed. Please try again later.'
          console.log 'ERROR: addContactsToThread', error
        else
          SharePadPopup.activeInstance.close()
          showSuccessMessage 'Shared in Knotable.'
