Package.describe({
    summary: 'Some language enhancements for coding style'
});

Package.on_use(function (api) {
    api.use([
        'coffeescript'
    ]);

    api.add_files([
        'language-tools.coffee'
    ], ['client', 'server']);
});
