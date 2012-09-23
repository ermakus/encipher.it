settings = require './settings'
express  = require 'express'
mailer   = require 'mailer'

# JS code to inject in page
bookmarklet_code = (version)->
    if version
        version = ".v#{version}"
    else
        version = ""
    return "(function(){document.body.appendChild(document.createElement('script'))" +
           ".src='#{settings.BASE_URL}/javascripts/inject#{version}.js';})"

# Bookmarklet link
bookmarklet = (version)->
    return "javascript:" + bookmarklet_code(version) + "();"


app = module.exports = express()

app.configure ->
    app.set('views', __dirname + '/views')
    app.set('view engine', 'jade')
    app.set('view options', {layout:true})
    app.use(express.static(__dirname + '/public'))
    app.use(express.bodyParser())
    app.use(express.methodOverride())
    app.use(app.router)
    app.use require('connect-assets')(buildDir: __dirname + '/public')

    js.root = 'javascripts'
    js('inject.js')
    js('inject.v2.js')
    js('inject.v3.js') # same as v4
    js('inject.v3-orig.js') # old v3
    js('inject.v4.js')
    js('inject.vios.js')

app.configure 'development', ->
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))

app.configure 'production', ->
    app.use(express.errorHandler())

app.get '/', (req, res)->
    agent = req.headers["user-agent"] or "Unknown"
    if false #agent.match(/iPad/) or agent.match(/iPhone/)
        return res.redirect settings.BASE_URL + '/ios'
    else
        res.render 'index', {
            title: 'Encipher.it – encrypt text or email in one click'
            bookmarklet: bookmarklet
            def_bookmarklet: bookmarklet(4)
            def_code: bookmarklet_code(4)
            crypto: "Sample text"
        }

app.get '/help', (req, res)->
    res.render 'help', {
        title: 'Encipher.it – How to encrypt emails and text messages'
        bookmarklet: bookmarklet
        def_bookmarklet: bookmarklet(4)
    }


app.get '/update', (req, res)->
    res.render 'update', {
        title: 'Encipher.it – new version available'
        bookmarklet: bookmarklet
        def_bookmarklet: bookmarklet(4)
    }

app.get '/ios', (req, res)->
    res.render 'ios', {
        title: 'Encipher.it - iOS version'
        def_bookmarklet: bookmarklet('ios')
        def_code: bookmarklet_code('ios')
        layout: false
    }

app.post '/survey', (req, res)->
    pgp = req.param('PGP')
    cost = req.param('cost')
    mailer.send {
        'host' : "localhost",
        'port' : "25",
        'domain' : "localhost",
        'to' : "anton@ermak.us",
        'from' : "nobody@encipher.it",
        'subject' : "Survey from encipher.it: #{pgp}/#{cost}",
        'body': "Interested in PGP: #{pgp}\nAble to spent: #{cost}",
        'username': 'decipher',
        'authentication': false }, (err)->
            err and console.log "Send survey error: #{err.message}"
            res.redirect( settings.BASE_URL )

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
        'authentication': false }, (err)->
            err and console.log "Send feedback error: #{err.message}"
            res.send( "success" )

app.listen(settings.PORT, settings.INTERFACE)
console.log("Express server listening on port %d", settings.PORT)
