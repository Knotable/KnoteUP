ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".split('')
ALPHABET_LENGTH = ALPHABET.length

@AppHelper =
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
    
  getPadUrlFromId: (padId) ->
    'http://' + Meteor.settings.public.remoteHost + '/p/' + @getShortHash(padId)
