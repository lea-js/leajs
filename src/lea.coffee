path = require "path"

http = require "http"
Stream  = require "stream"

fs = require "fs-extra"
Promise = require "yaku"

hookUp = require "hook-up"
readConf = require "read-conf"

util = require "./util"

class Lea
  constructor: ->
    hookUp @,
      actions: ["respond", "init", "close"]
  version: 1
  util: util
  fs: fs
  Promise: Promise
  path: path
  startUp: -> @whenLoaded = new Promise (resolve, reject) =>
    try
      {config, respond, position, init} = this
      
      {hyphenate, getAccepted, getQuery, isArray} = util

      respond.hookIn position.init, (o) =>
        o.head = {}
        o.trailers = {}

      # convert objects to JSON
      respond.hookIn position.after+1, (req) =>
        {body, head} = req
        if body? and
            not typeof body == "string" and
            not body instanceof Stream and 
            not Buffer.isBuffer(body) 
          req.body = JSON.stringify body
          

      # set default status and convert header
      respond.hookIn position.end-1, (req) =>
        {statusCode, body, head, stats} = req
        if not statusCode? and not body?
          throw 404
        req.statusCode = 200
        lastModified = req.lastModified ?= stats?.mtime or new Date()
        head.lastModified = lastModified.toUTCString()
          
        tmp = {}
        for k,v of head
          tmp[hyphenate(k)] = v
        req.head = tmp

      getRequest = this.getRequest = (req, url) =>
        url ?= req.url
        if (base = config.base) 
          if url.startsWith(base)
            url = url.replace base, "" 
          else
            return false
        [url, getQ] = getQuery(url)

        request = {
          request: req
          url: url
          getAccepted: getAccepted.bind null, req
          getQuery: getQ
        }
        hookUp request, actions: ["chunk", "end"]
        return request
      server = this.server = config.server ?= http.createServer()
      server.on "request", (req, res) =>
        return unless (request = getRequest(req)) 
        request.response = res
        request.chunk.hookIn position.end, ({chunk}) => new Promise (resolve) =>
          res.write chunk, null, resolve
        flag = => request.closed = true
        req.on "aborted", flag
        res.on "close", flag
        respond(request)
        .then ({closed,head,body,statusCode,trailers,chunk,end}) =>
          unless closed
            if (trailerNames = Object.keys(trailers)).length > 0
              head.trailer = trailerNames.join(",")
              request.end.hookIn position.end-1, =>
                tmp = {}
                for name in trailerNames
                  tmp[name] = await trailers[name]
                res.addTrailers(tmp)
            unless head.connection == "keep-alive"
              request.end.hookIn position.end, => res.end()
            res.writeHead statusCode, head
            unless body?
              end()
            else if body instanceof Stream
              body.on "data", (data) => 
                body.pause()
                chunk chunk:data
                .then => body.resume()
              body.on "end", end
            else
              chunk chunk:body
              .then end
        .catch (e) => 
          if e instanceof Error
            statusCode = 500
            head = {}
            console.error e
          else
            if e.statusCode?
              {head, statusCode, body} = e
            else
              statusCode = e or 404
            tmp = {}
            for k,v of head
              tmp[hyphenate(k)] = v
            head = tmp
          res.writeHead statusCode, head
          res.end(body)
          

      await Promise.all config.plugins.map ({plugin}) => plugin(this)
      await init()
      if (arr = config.respond)?
        arr = [arr] unless isArray(arr)
        for fn in arr
          respond.hookIn fn

      this.close.hookIn => 
        server.close()
        if (sockets = this._sockets)?
          for socket in sockets
            socket?.destroy?()

      server.on "error", (e) =>
        await this.close()
        reject(e) if e.code == "EADDRINUSE"

      if this.readConfig.watch
        server.on "connection", Array.prototype.push.bind(this._sockets = [])
      if config.listen != false
        server.listen config.listen, => 
          if config.verbose
            unless typeof (port=config.listen.port) == "number"
              connectionString = "local socket"
            else
              unless (host = config.listen.host)?
                ip = require "ip"
                host = ip.address()
              host = "http://" + host
              chalk = require "chalk"
              connectionString = chalk.bold(host+":"+port)
            
            console.log "leajs is listening on #{connectionString}"
          resolve(this)
      else
        resolve(this)
    catch e
      reject e

module.exports = (options) =>
  options ?= {}
  options.name ?= "leajs.config"
  readConf 
    name: options.name
    watch: options.watch
    folders: ["./server","./"]
    assign: options.config
    schema: path.resolve(__dirname, "./configSchema")
    plugins:
      paths: [process.cwd(), path.resolve(__dirname,"..")]
    concatArrays:true
    required: false
    catch: (e) => console.log e
    base: new Lea
    cancel: ({resetAllActions, close}) =>
      await close().catch (e) => console.log e
      resetAllActions()
    cb: (lea) => lea.startUp()

module.exports.getConfig = => readConf 
  name: "leajs.config"
  folders: ["./server","./"]
  schema: path.resolve(__dirname, "./configSchema")
  plugins:
    paths: [process.cwd(), path.resolve(__dirname,"..")]
  base: new Lea


if process.argv[0] == "coffee"
  module.exports()
  