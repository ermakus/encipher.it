GUI = (encipher)-> """ 
<style>
.encipher-popup {
    display: none;
    position: fixed;
    z-index: 9999;
    background: #355664;
    border: solid gray 1px; 
    -moz-border-radius: 10px; 
    -webkit-border-radius: 10px; 
    border-radius: 10px;
    top: 50%;
    left: 50%;
    padding: 5px;
    height: 90px;
    width: 390px;
    margin-top: -50px;
    margin-left: -200px;
}

.encipher-key {
    display: block;
    margin: 0px;
    width: 100%;
    padding: 0px;
    margin-top: 10px;
}

.encipher-key-input {
    border: 0;
    background-color: white;
    padding: 0;
    margin: 0;
    padding-left: 3px;
    width: 100%;
    height: 25px;
    -moz-border-radius: 4px; 
    -webkit-border-radius: 4px; 
    border-radius: 4px;
}

.encipher-title, .encipher-message {
    display: inline-block;
    padding: 5px;
    font-size: 14px;
    color:#fff;
    font-family:Arial, Helvetica, sans-serif; 
    text-decoration: none;
    text-align: left;
}

.encipher-message {
    margin-top: 8px;
}

.encipher-icon {
    -moz-border-radius: 16px; 
    -webkit-border-radius: 16px; 
    border-radius: 16px;
    display: inline-block;
    float: right;
    margin: 0;
    padding: 4px;
    width: 16px;
    height: 16px;
    cursor: pointer;
}

.encipher-icon:hover {
    background-color: #213e4a;
}

.encipher-settings {
    background: url(#{encipher.base}/images/settings-white.png) no-repeat center center;
}

.encipher-close {
    background: url(#{encipher.base}/images/close-white.png) no-repeat center center;
}

.encipher-key-mode {
    display: block;
    padding: 4px;
    margin: 0px;
    width: 16px;
    height: 16px;
    cursor: pointer;
    position: relative;
    top: -24px;
    z-index: 10000;
    float: right;
    background: url(#{encipher.base}/images/masked.png) no-repeat center center;
}

.encipher-key-mode-plain {
    background: url(#{encipher.base}/images/unmasked.png) no-repeat center center !important;
}

.encipher-it {
    position: absolute;
    right: 5px;
    bottom: 3px;
    display: inline-block;
    margin: 0;
    padding: 3px;
    padding-left:20px;
    margin-right: 4px;
    cursor: pointer;
    color:#0196E3;
    font-size: 14px;
    font-family:Arial, Helvetica, sans-serif; 
    background: url(#{encipher.base}/images/encrypt-white.png) no-repeat center left;
}

.encipher-it:hover {
    text-decoration: underline;
}

</style>

<div class='encipher-popup'>
    <div class='encipher-title'></div>
    <div class='encipher-icon encipher-close'></div>
    <div class='encipher-icon encipher-settings'></div>
    <div class='encipher-tab encipher-tab-key'>
        <div class='encipher-key'>
            <input type='text' class='encipher-key-input encipher-key-plain' style='display: none;'/>
            <input type='password' class='encipher-key-input encipher-key-pass'/>
            <div class='encipher-key-mode'></div>
        </div>
    </div>
    <div class='encipher-message'></div>
    <div class='encipher-it'>Encipher It</div>
</div>
"""

# Popup dialog
class Popup

    constructor: (@encipher)->
        jQuery('body').append( GUI(@encipher) )
        @frame = jQuery('.encipher-popup')
        # Plain/masked mode for key input
        jQuery('.encipher-key-plain').hide().val("")
        jQuery('.encipher-key-pass').show().val("")
        jQuery('.encipher-key-mode').click =>
            key = @key()
            jQuery('.encipher-key-plain').toggle().val(key)
            jQuery('.encipher-key-pass').toggle().val(key)
            el = jQuery('.encipher-key-mode')
            if el.hasClass('encipher-key-mode-plain')
                el.removeClass('encipher-key-mode-plain')
            else
                el.addClass('encipher-key-mode-plain')
        jQuery('.encipher-close').click => @hide()

    refresh: ->
        if @key() != ''
            jQuery('.encipher-it').show()
        else
            jQuery('.encipher-it').hide()

    # Enter key
    input: ( title, button, callback ) ->
        jQuery('.encipher-key-input').focus().val("").unbind().keyup (e)=>
            score = @score()
            jQuery('.encipher-message').html(score)
            if (e.which == 27) then return @hide()
            if (e.which == 13 and @key()) then return callback(@key())
            @refresh()

        jQuery('.encipher-message').html("")
        jQuery('.encipher-title').html( title )
        jQuery('.encipher-it').html( button ).unbind().bind 'click', => callback(@key())
        jQuery('.encipher-tab-key').show()
        @refresh()
        @frame.show()

    # Show alert
    alert: ( message ) ->
        jQuery('.encipher-tab-key').hide()
        jQuery('.encipher-title').html("")
        @message message
        @refresh()
        @frame.show()

    # Show alert
    message: ( message ) ->
        jQuery('.encipher-message').html( message )

    # Hide dialog
    hide: =>
        @frame and @frame.hide()

    isVisible: ->
        @frame and @frame.is(':visible')

    # Return current key
    key: ->
        if jQuery('.encipher-key-plain').is(':visible')
            return jQuery('.encipher-key-plain').attr('value')
        else
            return jQuery('.encipher-key-pass').attr('value')

    # Key score
    score: ->
        value = @key()
        strength = 1
        for regexp in [/{5\,}/, /[a-z]+/, /[0-9]+/, /[A-Z]+/]
            if value.match(regexp)
                strength++
        if value.length < 5
            strength = 1
        if value.length > 8
            strength++
        if value.length > 12
            strength++
        if value.length > 16 or strength > 5
            strength = 5
        ['<span style="#c11b17">Very weak</span>','Weak','Moderate','Strong','Very strong'][strength-1]


# Main service class
window.Encipher = class Encipher

    constructor: (@base) ->
        @base ||= (window.location.protocol + '//' + window.location.host)
        @format = new Format(@)
        @cache = {}
        basere = @base.replace(/([\:\.\/])/g,"\\$1")
        @reHasCipher = new RegExp("(EnCt2|#{basere})")
        @reGetCipher = [ new RegExp("(EnCt2.*IwEmS)"), new RegExp("(#{basere}[\#\?][0-9A-Za-z]+)") ]

    hasCipher: (message)->
        return false unless message
        return (message or "").match(@reHasCipher)

    # Extract ciphered message or hash reference from the text
    extractCipher: (message)->
        for re in @reGetCipher
            parts = (message or "").match re
            return parts[1] if parts
        return false

    # Traverse document and collect all encrypted blocks to collection
    findEncrypted: ->
        # Collection of elements and related text blocks
        [nodes, texts] = [[],[]]

        # Extract encoded block from element and put it to collection
        found = (elem,txt) =>
            if elem[0].nodeName.toLowerCase() == 'a'
                elem = elem.parent()
            cipher = @extractCipher(txt.replace(/[\n> ]/g,''))
            if cipher
                nodes.push elem
                texts.push cipher
                return 1
            else
                return 0

        # Traverse DOM and search for encoded block headers
        traverse = (node) =>
            skip = 0
            # Text node
            if node.nodeType == 3 and @hasCipher(node.data)
                elem = jQuery(node.parentNode)
                skip = found(elem, elem.text())
            else
                # Element node
                if (node.nodeType == 1 && !/(script|style)/i.test(node.tagName))
                    # Text area or input
                    if /(input|textarea)/i.test( node.tagName )
                        elem = jQuery(node)
                        found(elem, elem.val())
                    else
                        # Recursive traverse children
                        if node.childNodes
                            for i in  [0...node.childNodes.length]
                                i += traverse node.childNodes[i]
            return skip

        # Traverse body and all iframes
        traverseBody = (body) ->
            body.each -> traverse this
            body.find("iframe").each ->
                try
                    iframe = jQuery(this).get(0)
                    if iframe.src.indexOf(location.protocol + '//' + location.host) == 0 or iframe.src.indexOf('about:blank') == 0 or iframe.src == ''
                        traverseBody( jQuery(this).contents().find('body') )
                catch e
                    # pass
        traverseBody jQuery('body')
        return [nodes,texts]


    # Return input element and text (simple heuristic used)
    findInput: ->
        # Check for gmail first
        # Rich formatting
        node = jQuery('iframe.editable:visible').contents().find('body')
        if node.length then return [node, node.html()]
        # Plain textarea
        node = jQuery('textarea[form=nosend]:visible')
        if node.length then return [node, node.val()]
        # Yahoo mail
        node = jQuery('iframe[name=compArea_test_]').contents().find('body')
        if node.length then return [node, node.html()]
        # Outlook web access or own site
        node = jQuery('textarea[name=txtbdy]')
        if node.length == 1 then return [node, node.val()]
        # Return textarea if only one
        node = jQuery('textarea')
        if node.length == 1 then return [node, node.val()]
         # If many textareas, then select focused one
        if node.length > 1 then node = jQuery('textarea:focus')
        if node.length == 1 then return [node, node.val()]
        # Fail finally
        return [undefined,undefined]

    parse: ->
        [@nodes, @texts] = @findEncrypted()
        [@node,  @text]  = @findInput()
        @encrypted = @nodes.length > 0
        return @encrypted or @node != undefined

    # Password based key derivation function
    derive: (password, salt, callback) ->
        # Check if password cached
        cacheKey = password + salt
        if @cache[cacheKey]
            return callback( @cache[cacheKey] )
        # Generate key        
        pbkdf2 = new PBKDF2( password, salt, 1000, 32 )
        pbkdf2.deriveKey(
            (per)=>
                @gui and @gui.message( "Generating key: #{Math.floor(per)}%" )
            ,
            (key)=>
                # Put key to cache
                @cache[cacheKey]=key
                callback(key)
        )

    # Decrypt text in DOM node
    decryptNode: (node, text, password, callback)->
        @format.beforeDecrypt text, (error, text)=>
            return callback(error, false) if error
            @updateNode node, text
            text = text.slice(5,text.length-5)
            hash = text[0...64]
            hmac = text[0...40]
            salt = text[64...72]
            text = text[72...]
            @derive password, salt, (key) =>
                text = Aes.Ctr.decrypt( text, key, 256 )
                # Old version used hash - changed to more secure HMAC in latest
                if hex_hmac_sha1(key, text ) == hmac or hash == Sha256.hash( text )
                    @updateNode node, text
                    callback( null, true )
                else
                    callback( null, false )
 
    # Decrypt all encrypted nodes
    decrypt: (password, callback)->
        i = 0
        success = false
        # Trick for sequence of async calls
        next = =>
            if @nodes.length > i
                @decryptNode @nodes[i], @texts[i], password, (error, res)=>
                    return callback( error, false ) if error
                    i += 1
                    success ||= res
                    next()
            else
                @cache = {}
                callback( null, success )
        next()

    # Encrypt text in input element
    encrypt: (password, callback)->
        salt = Base64.random(8)
        @derive password, salt, (key) =>
            # Calculate HMAC digest
            hmac = hex_hmac_sha1(key, @text )
            # Pad to to 256bit (reserved for sha256 hash)
            hmac += hmac[0...24]
            cipher = hmac + salt + Aes.Ctr.encrypt( @text, key, 256)
            @format.afterEncrypt cipher, (err, cipher)=>
                @updateNode @node, cipher
                @cache = {}
                callback( err )

    # Update text 
    updateNode: (node, value)->
        if node.is('textarea')
            node.val( value )
        else
            node.html( value.replace /\n/g,'<br/>' )

    # Called when injected by bookmarklet
    startup: ->
        @gui ||= new Popup(@)
        if @gui.isVisible()
            @gui.hide()
        else
            if @parse()
                if @encrypted
                    @gui.input "Enter decryption key", "Decipher It", (key)=>
                        @decrypt key, (error, success)=>
                            if success
                                @gui.hide()
                            else
                                if error
                                    @gui.message error.message
                                else
                                    @gui.message "Invalid key"
                else
                    if @text
                        @gui.input "Enter encryption key", "Encipher It", (key)=>
                            @encrypt key, (error)=>
                                if not error
                                    @gui.hide()
                                else
                                    @gui.message error.message
                    else
                        @gui.alert "Message is empty"
            else
                @gui.alert "Message not found"

# Format encrypted as plain text
class TextFormat
    constructor: (@encipher)->

    afterEncrypt: (message, callback) ->
        callback( null, message.match(/.{0,80}/g).join('\n') + "\nEncrypted by " + @encipher.base )

    beforeDecrypt: (message, callback) ->
        callback( null, message )

# Format encrypted text as short link 
# Ciphered text will be stored on the public remote server
class LinkFormat
    constructor: (@encipher)->

    afterEncrypt: (message, cb)->
        body = @encipher.extractCipher( message )
        return cb(null, message) if not body
        jQuery.post @encipher.base + "/pub", {body}, (res)=>
            cb(null, message.replace( body, @encipher.base + '?'+res) )
        .error ->
            cb( new Error("Can't create link") )

    beforeDecrypt: (message, cb)->
        url = @encipher.extractCipher( message )
        return cb(null, message) if not url or url.indexOf( @encipher.base ) != 0
        guid = url[@encipher.base.length+1...]
        jQuery.post @encipher.base + "/pub", {guid}, (res)=>
            cb(null, res)
        .error ->
            cb( new Error("Can't expand link") )

# Format selector
class Format
    constructor: (@encipher)->
        @text  = new TextFormat(@encipher)
        @link  = new LinkFormat(@encipher)
        @selected  = @link

    # Format with with selected type
    afterEncrypt: (message, callback) ->
        @selected.afterEncrypt("EnCt2#{message}IwEmS", callback)

    # Unpack all supported formats
    beforeDecrypt: (message, callback) ->
        @link.beforeDecrypt message, (err, message)=>
            return callback(err, message) if err
            @text.beforeDecrypt message, callback
