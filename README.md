# Leajs

extendable, configuration based http server.

## Features
- Snapshots only - forces you to do proper tests of input -> output
- Interactively shows you the output and asks about it
- Uses webpack bundles to track changes
- Watches test files and dependencies
- Static analysis of tests to make writing them as easy as possible

### Install
```sh
npm install --save leajs-server
```

### Usage
```
# cli
usage: leajs <options> (config file)

options:
-w, --watch         restart server on changes in config
-p, --prod          sets NODE_ENV to "production"
    --port [port]   opens server on [port]

config file is optional and defaults to "leajs.config.[js|json|coffee|ts]"
in "server/" and "/"
```

```js
// in node
Leajs = require("leajs-server")

// available options
// name (String) Default:"leajs.config" Name of the configuration file
// watch (Boolean) Starts the server in watch mode
// config (Object) Overwrites configuration file

Leajs(options)
.then((leajs) => {
  // finished
  leajs.close() // returns promise
})
.catch((e) => {
  // got some error
})
```

## leajs.config
Read by [read-conf](https://github.com/paulpflug/read-conf), from `./` or `./server/` by default.
```js
module.exports = {

  // namespace for the server e.g. /leajs
  base: "", // String

  // Disable some of the default plugins
  // $item (String) Package name or filepath (absolute or relative to cwd) of plugin
  disablePlugins: null, // Array

  // Default file to serve when in folder
  index: "index.html", // String

  // Listen object for httpServer
  // type: Object
  listen: {

    // Hostname for listening
    // Default: if inProduction then "localhost" else null
    host: null, // String

    // Port or socket to listen to
    // Default: if process.env.LISTEN_FDS then {fd: 3} else 8080
    port: null, // [Object, Number]

  },

  // Leajs plugins to load
  // type: Array
  // $item (String) Package name or filepath (absolute or relative to cwd) of plugin
  plugins: ["leajs-files","leajs-folders","leajs-encoding","leajs-cache","leajs-locale","leajs-eventsource","leajs-redirect"],

  // Custom respond function for quick debugging or testing
  respond: null, // [Function, Array]

  // Level of logging
  verbose: 1, // Number

  // …

}
```

### Custom respond function
```js
module.exports = {
  respond: (req) => {
    // req.request raw request object
    if (req.url == "/hello"){
      req.body = "hello world!"
    }
  }
}
```

## Plugins

You should read the (short) docs of the bold ones.

Activated by default:
- **[leajs-files](https://github.com/lea-js/leajs-files)** - serve files
- **[leajs-folders](https://github.com/lea-js/leajs-folders)** - serve folders
- **[leajs-encoding](https://github.com/lea-js/leajs-encoding)** - handles the encoding
- **[leajs-cache](https://github.com/lea-js/leajs-cache)** - handles caching of resources
- [leajs-locale](https://github.com/lea-js/leajs-locale) - simplifies local
- [leajs-eventsource](https://github.com/lea-js/leajs-eventsource) - eventsource implementation
- [leajs-redirect](https://github.com/lea-js/leajs-redirect) - manages redirects

Installed and activated manually
- [leajs-spa-router](https://github.com/lea-js/leajs-spa-router) - single page router
- [leajs-webpack](https://github.com/lea-js/leajs-webpack) - webpack development and hot middleware

## License
Copyright (c) 2018 Paul Pflugradt
Licensed under the MIT license.
