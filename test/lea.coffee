{test, prepare, Promise, getTestID} = require "snapy"
Lea = require "!./src/lea.coffee"
http = require "http"


port = => 8081 + getTestID()

request = (path = "/") =>
  promise: new Promise (resolve, reject) =>
    http.get Object.assign({hostname: "localhost", port: port(), agent: false}, {path: path}), resolve
    .on "error", reject
  plain: true
  stream: "":"body"
  filter: "headers,statusCode,-headers.date,body"

prepare (state, cleanUp) =>
  Lea config: Object.assign (state or {}), {listen:port:port()}
  .then (lea) =>
    cleanUp => lea.close()
    return lea

test (snap) =>
  snap request()
