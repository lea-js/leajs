#!/usr/bin/env node
var args, i, len, options, arg
options = { config: {} }
args = process.argv.slice(2)
for (i = 0, len = args.length; i < len; i++) {
  arg = args[i]
  if (arg[0] == "-") {
    switch (arg) {
      case '-w':
      case '--watch':
        options.watch = true
        break
      case '-p':
      case '--prod':
        process.env.NODE_ENV = "production"
        break
      case '--port':
        options.config.listen = { port: args[++i] }
        break
      case '-h':
      case '--help':
        console.log('usage: leajs <options> (config file)')
        console.log('')
        console.log('options:')
        console.log('-w, --watch         restart server on changes in config')
        console.log('-p, --prod          sets NODE_ENV to "production"')
        console.log('    --port [port]   opens server on [port]')
        console.log('')
        console.log('config file is optional and defaults to "leajs.config.[js|json|coffee|ts]"')
        console.log('in "server/" and "/"')
        process.exit()
        break
    }
  } else {
    options.name = arg
  }
}
var start
try {
  require("coffeescript/register")
  start = require("./src/lea.coffee")
} catch (e) {
  start = require("./lib/lea.js")
}

start(options)