settings = require './settings'
express  = require 'express'
mailer   = require 'mailer'
mongoose = require 'mongoose'
crypto   = require 'crypto'

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

db = mongoose.createConnection('localhost', 'test')
db.on('error', console.error.bind(console, 'connection error:'))

MessageSchema = mongoose.Schema
    hash: String
    body: String
    stump: Date

Message = db.model('Message', MessageSchema)

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
    js('inject.vios.js')
    js('encipher.js')
    js('compose.js')

app.configure 'development', ->
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))

app.configure 'production', ->
    app.use(express.errorHandler())

# Redirect all bookmarklet versions to single hook
app.get '/javascripts/inject:version.js', (req, res, next)->
    if req.params.version == ''
        return next()
    else
        res.redirect '/javascripts/inject.js'

# CORS middleware
allowCrossDomain = (req, res, next)->
   res.header 'Access-Control-Allow-Origin', '*'
   res.header 'Access-Control-Allow-Credentials', true
   res.header 'Access-Control-Allow-Methods', 'POST, GET, PUT, DELETE, OPTIONS'
   res.header 'Access-Control-Allow-Headers', 'Content-Type'
   next()

# Allow cross-origin requests
app.options '/pub', allowCrossDomain, (req, res, next)->
    next()

# Public store for encrypted messages
app.post '/pub', allowCrossDomain, (req, res)->
    # If hash passed, then lookup body
    hash = req.param('hash','')
    if hash
        Message.findOne {hash}, (err, msg)->
            if err
                res.send( err.message, 500 )
            else
                if msg
                    res.send( msg.body )
                else
                    res.send "Not found", 404
    else
        # else calck body hash and store it
        body = req.param('body','')
        if body
            hash = crypto.createHash('sha1').update(body).digest('hex')
            Message.findOne {hash}, (err, msg)->
                if err
                    res.send( err.message, 500 )
                else
                    if msg
                        res.send( hash )
                    else
                        msg = new Message({hash,body})
                        msg.save (err)->
                            if err
                                res.send( err.message, 500 )
                            else
                                res.send( hash )
        else
            res.send("Invalid request", 500)

app.get '/', (req, res)->
    res.render 'index', {
        title: 'Encipher.it – encrypt text or email in one click'
        def_bookmarklet: bookmarklet()
    }

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
