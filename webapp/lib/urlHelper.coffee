ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".split('')
ALPHABET_LENGTH = ALPHABET.length

@UrlHelper =
  removeScheme: (url) ->
    url.replace(new RegExp('^(' + CommonRegularExpressions.scheme + '|mailto:)', 'i'), '')

  getShortHash: (padId) ->
    pad = Pads.findOne _id: padId
    return '' unless pad
    padId.slice(0, 2) + @encodeNumberToShortHash(pad.uniqueNumber)

  encodeNumberToShortHash: (uniqueNumber) ->
    return ALPHABET[uniqueNumber] if uniqueNumber is 0
    urlHash = ""
    while uniqueNumber > 0
      urlHash += ALPHABET[uniqueNumber % ALPHABET_LENGTH]
      uniqueNumber = parseInt(uniqueNumber / ALPHABET_LENGTH, 10)
    return urlHash.split("").reverse().join("")

  decodeShortHashToNumber: (urlHash) ->
    uniqueNumber = 0
    for character in urlHash
      uniqueNumber = uniqueNumber * ALPHABET_LENGTH + ALPHABET.indexOf character
    return uniqueNumber

  getPadUrlFromId: (padId) ->
    'http://' + Meteor.settings.public.remoteHost + '/p/' + @getShortHash(padId)

  getShortHashInUrl: (url) ->
    url = @removeScheme url
    return false unless @isKnotableLink(url)
    url.match(/([^\/]+)\/([^\/]+)\/([^\/]+)/)?[3]

  isKnotableLink: (url) ->
    reg = new RegExp('^' + @removeScheme(Meteor.absoluteUrl()) + '|^[^\\s\\/?]*knotable.com', 'i')
    reg.test @removeScheme(url)

  getTopicByShortHash: (shortHash, reactive = true) ->
    prefixId = shortHash.slice 0, 2
    hash = shortHash.slice 2
    uniqueNumber = UrlHelper.decodeShortHashToNumber hash
    regex = new RegExp("^" + prefixId, "i")
    topic = Pads.findOne {_id: {$regex: regex}, uniqueNumber: uniqueNumber}, {reactive: reactive}
    return topic
