//https://github.com/meteor/meteor/issues/4793
//https://trello.com/c/3Lbn4igf/8052-knotes-are-not-posting-in-the-development-branch-code
if (Meteor.isClient) {
  var MeteorVersion = Meteor.release.replace(/[.@METRO]+/g, '');
  MeteorVersion += new Array(5 - MeteorVersion.length).join('0');
  if (Number(MeteorVersion) <= 1103) {
    console.log('Updating Tracker.Dependency.prototype.changed function');
    Tracker.Dependency.prototype.changed = function () {
      var self = this;
      for (var id in self._dependentsById) {
        var dependent = self._dependentsById[id];
        if (dependent) dependent.invalidate();
      }
    }
  }
}
