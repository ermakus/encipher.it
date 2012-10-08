mongoose = require 'mongoose'
crypto   = require 'crypto'

GuidSchema = mongoose.Schema
    counter: Number
    stump: Date

MessageSchema = mongoose.Schema
    hash: String
    body: String
    stump: Date

# CORS middleware
allowCrossDomain = (req, res, next)->
   res.header 'Access-Control-Allow-Origin', '*'
   res.header 'Access-Control-Allow-Credentials', true
   res.header 'Access-Control-Allow-Methods', 'POST, OPTIONS'
   res.header 'Access-Control-Allow-Headers', 'Content-Type'
   next()

exports.init = (app)->

    exports.db = db = mongoose.createConnection('localhost', 'encipher')
    exports.Guid    = Guid    = db.model('Guid', GuidSchema )
    exports.Message = Message = db.model('Message', MessageSchema)

    db.on('error', console.error.bind(console, 'connection error:'))

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
