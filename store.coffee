mongoose = require 'mongoose'
crypto   = require 'crypto'

@db = db = mongoose.createConnection('localhost', 'encipher')

GuidSchema = mongoose.Schema
    _id: String
    counter: Number

GuidSchema.statics.setup = (callback)->
    # Init guid counter
    @findOne {'_id':'messages'}, (error, guid)=>
        return callback( error ) if error or (guid and guid.counter)
        @update {'_id':'messages'}, '$set':{'counter':0}, {upsert:true}, (error, init)->
            callback(error)

GuidSchema.statics.next = (callback)->
    @collection.findAndModify {'_id':'messages'}, {}, '$inc':{'counter':1}, {}, (error, guid)->
        if error or not guid
            callback( error )
        else
            buf = new Buffer(4)
            buf.writeUInt32BE( guid.counter, 0 )
            callback( null, buf.toString('base64').replace( /\=/g,'' ) )

MessageSchema = mongoose.Schema
    guid: String
    hash: String
    body: String
    stump: Date

Guid = db.model('Guid', GuidSchema )

Guid.setup (error)->
    console.log "Guid counter error", error.message if error

Message = db.model('Message', MessageSchema)

# CORS middleware
allowCrossDomain = (req, res, next)->
   res.header 'Access-Control-Allow-Origin', '*'
   res.header 'Access-Control-Allow-Credentials', true
   res.header 'Access-Control-Allow-Methods', 'POST, OPTIONS'
   res.header 'Access-Control-Allow-Headers', 'Content-Type'
   next()

@loadHash = (guid, callback)->
    if hash
        Message.findOne {guid}, (err, msg)->
            callback(err, msg and msg.body )
    else
        callback( null, null )

@init = (app)->

    db.on('error', console.error.bind(console, 'connection error:'))

    # Allow cross-origin requests
    app.options '/pub', allowCrossDomain, (req, res, next)->
        next()

    # Public store for encrypted messages
    app.post '/pub', allowCrossDomain, (req, res)->
        # If hash passed, then lookup body
        guid = req.param('guid','')
        if guid
            Message.findOne {guid}, (err, msg)->
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
                            res.send( msg.guid )
                        else
                            Guid.next (err, guid)->
                                console.log "Save message", guid
                                if err
                                    res.send( err.message, 500 )
                                else
                                    msg = new Message({hash,body,guid})
                                    msg.save (err)->
                                        if err
                                            res.send( err.message, 500 )
                                        else
                                            res.send( guid )
            else
                res.send("Invalid request", 500)
