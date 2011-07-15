BASE_URL="http://localhost:3000"

express = require 'express'
mailer = require 'mailer'

app = module.exports = express.createServer()

bookmarklet1 = "javascript:(function(){document.body.appendChild(document.createElement('script')).src='#{BASE_URL}/javascripts/inject.js';})();"
bookmarklet = "javascript:(function(){document.body.appendChild(document.createElement('script')).src='#{BASE_URL}/javascripts/inject.v2.js';})();"

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
    res.render 'index', {
        title: 'AES text encryptor',
        bookmarklet, bookmarklet1
    }

app.post '/feedback', (req, res)->
    name = req.param('name')
    email = req.param('email')
    message = req.param('message')
    console.log "Feedback from #{name} <#{email}>: #{message}"

    mailer.send {
        'host' : "localhost",
        'port' : "25",
        'domain' : "localhost",
        'to' : "anton@ermak.us",
        'from' : email,
        'subject' : "Feedback from #{name} (encipher.it)",
        'body': message,
        'username': 'decipher',
        'authentication': false }
    res.send( "success" )

if !module.parent
    app.listen(3000, '127.0.0.1')
    console.log("Express server listening on port %d", app.address().port)
