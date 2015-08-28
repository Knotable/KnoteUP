App.info({
  id: 'com.knotable.knoteup',
  name: 'KnoteUp',
  description: 'KnoteUp iOS',
  version: '0.0.1',
  author: 'Knotable',
  email: 'team@knote.com',
  website: 'http://knotable.com'
});

// Resources
App.icons({
  'iphone': 'public/icon.png',
  // ... more screen sizes and platforms ...
});

App.launchScreens({
  'iphone': 'public/launch.png',
  // ... more screen sizes and platforms ...
});

// Cordova preferences
App.setPreference('HideKeyboardFormAccessoryBar', true);
App.setPreference('Orientation', 'portrait');
App.setPreference('StatusBarOverlaysWebView', true);
App.setPreference('StatusBarBackgroundColor', '#000000')
App.setPreference('StatusBarStyle', 'default')

// Accesss rules
App.accessRule('*')
