@CdnHelper =
  getDomain : ->
    Meteor.settings.public?.aws?.cdnUrl or ''



  getCdnUrlOrAbsoluteUrl: ->
    cdnUrl = CdnHelper.getDomain()
    unless cdnUrl then Meteor.absoluteUrl() else cdnUrl + '/'
