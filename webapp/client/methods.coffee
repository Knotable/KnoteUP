#Meteor.remoteConnection.methods
#  add_knote: (requiredKnoteParameters, optionalKnoteParameters) ->
#    option = _.clone optionalKnoteParameters
#    _.extend option, requiredKnoteParameters
#    Knotes.insert option
