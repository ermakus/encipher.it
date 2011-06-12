BASE_URL="http://localhost:3000"

express = require 'express'

app = module.exports = express.createServer()

app.configure ->
    app.set('views', __dirname + '/views')
    app.set('view engine', 'jade')
    app.use(express.bodyParser())
    app.use(express.methodOverride())
    app.use(app.router)
    app.use(express.static(__dirname + '/public'))


app.configure 'development', ->
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))

app.configure 'production', ->
    app.use(express.errorHandler())

app.get '/', (req, res)->
    bookmarklet = "javascript:(function(){document.body.appendChild(document.createElement('script')).src='#{BASE_URL}/javascripts/inject.js';})();"
    res.render 'index', {
        title: 'Mail Protector',
        bookmarklet
    }

if !module.parent
    app.listen(3000)
    console.log("Express server listening on port %d", app.address().port)
