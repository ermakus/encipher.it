settings = require './settings'
express  = require 'express'
mailer   = require 'mailer'
store    = require './store'

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
    js('encipher.js')
    js('compose.js')

app.configure 'development', ->
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))

app.configure 'production', ->
    app.use(express.errorHandler())

# Init mongo store
store.init(app)

app.get '/', (req, res)->
    parts = (req._parsedUrl.query or "").match /(^[A-Za-z0-9]+)/
    if parts
        store.loadHash parts[0], (error, cipher)->
            console.log "Hash", parts[0], "Body", cipher
            res.render 'index',
                title: 'You Got Encrypted Message'
                cipher: cipher or (error and error.message)
                encrypted: true
                def_bookmarklet: bookmarklet()
    else
        res.render 'index',
            title: 'Encipher.it – encrypt text or email in one click'
            cipher: "Sample text"
            encrypted: false
            def_bookmarklet: bookmarklet()

app.get '/help', (req, res)->
    res.render 'help', {
        title: 'Encipher.it – How to encrypt emails and text messages'
        def_bookmarklet: bookmarklet()
    }

app.get '/ios', (req, res)->
    res.render 'ios', {
        title: 'Encipher.it - iOS version'
        def_bookmarklet: bookmarklet('ios')
        layout: false
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
        'authentication': false }, (err)->
            err and console.log "Send feedback error: #{err.message}"
            res.send( "success" )

app.listen(settings.PORT, settings.INTERFACE)
console.log("Express server listening on port %d", settings.PORT)
