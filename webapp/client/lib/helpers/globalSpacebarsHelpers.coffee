UI.registerHelper 'baseUrl', (path) ->
  if path.indexOf('/') is 0
    return CdnHelper.getDomain() + path
  return path
