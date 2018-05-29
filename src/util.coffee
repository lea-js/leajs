capitalize = (str) => str.charAt(0).toUpperCase() + str.slice(1)
hyphenate = (str) => str.replace(/([^-])([A-Z])/g, '$1-$2')
module.exports = 
  camelize: (str) => str.replace /-(\w)/g, (_, c) -> if c then c.toUpperCase() else ''
  cHyphenate: (str) => capitalize(hyphenate(str))
  capitalize: capitalize
  hyphenate: (str) => hyphenate(str).toLowerCase()
  isString: (obj) => typeof obj == "string" or obj instanceof String
  isArray: Array.isArray
  arrayize: (obj) => 
    return obj if Array.isArray(obj)
    return [] unless obj?
    return [obj]
  isFunction: (obj) => typeof obj == "function"
  getAccepted: (req, header) =>
    str = req.headers[header.toLowerCase()]
    return [] unless str
    return str.split(",")
      .map (str) => 
        arr = str.split(";")
        arr[1] = arr[1]?.replace("q=","") or 1
        return arr
      .sort (a,b) => a[1] - b[1]
      .map (arr) => arr[0]
  getQuery: (url) =>
    fn = =>
    if ~(i = url.indexOf("?"))
      query = url.slice(i+1).split("&").reduce ((acc, curr) =>
        splitted = curr.split("=")
        if splitted.length == 2
          acc[splitted[0]] = splitted[1]
        return acc
      ), {}
      url = url.slice(0,i)
      fn = (str) => query[str]
    return [url, fn]