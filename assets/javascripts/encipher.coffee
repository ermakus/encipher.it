HTML_INPUT=
    "<input type='text' style='position: absolute; display: block; top: 4px; left: 4px; right: 4px; bottom: 32px; width: 97%; display: none;' id='crypt-key-plain'/>
     <input type='password' style='position: absolute; display: block; top: 4px; left: 4px; right: 4px; bottom: 32px; width: 97%;' id='crypt-key-pass'/>
    <u style='cursor: pointer; display: block; position: absolute; display: block; top: 10px; right: 6px; color: black;' id='crypt-show-pass' z-index='10000'>Unmask</u>"

HTML_CHECKBOX=
    "<div style='position: absolute; display: block; right: 85px; bottom: 4px;'>
      <input style='vertical-align: middle;' type='checkbox' id='crypt-as-link' checked='yes'/>
      <label for='crypt-as-link'>Create link</label>
    </div>"

HTML_POPUP = (base, title, body, action, more)->
    more = more or ""
    "<div style='position: fixed; z-index: 9999; background: #355664; border: solid gray 1px; -moz-border-radius: 10px; -webkit-border-radius: 10px; border-radius: 10px'>
        <div style='position: absolute; left: 0; right: 0; color: white; margin: 4px; height: 32px;'>
            <b style='padding: 8px; float: left;'>#{title}</b>
            <img style='border: none; float: right; cursor: pointer;' id='crypt-close' src='#{base}/close.png'/>
        </div>
        <div style='position: absolute; bottom: 0; top: 32px; margin: 4px; padding: 10px; left: 0; right: 0;'>
            #{body}
            <b style='position: absolute; display: block; left: 4px; bottom: 4px;' id='crypt-message''></b>
            <input disabled='true' style='position: absolute; display: block; right: 4px; bottom: 4px;' id='crypt-btn' type='button' value='#{action}'/>
            #{more}
        </div>
    </div>"

# Popup dialog
class Popup

    constructor: (@encipher, @callback)->

    input: (title, action, more) ->
        @show title, action, HTML_INPUT, more

        jQuery('#crypt-show-pass').click =>
            pass = @password()
            jQuery('#crypt-key-plain').toggle().val(pass)
            jQuery('#crypt-key-pass').toggle().val(pass)
            el = jQuery('#crypt-show-pass')
            if el.html() == 'Unmask'
                el.html('Mask')
            else
                el.html('Unmask')

        # Encrypt handler
        jQuery('#crypt-key-plain,#crypt-key-pass').focus().keyup (e)=>
            enabled = @password() != ''
            score = @score()
            jQuery('#crypt-message').html(score)
            jQuery('#crypt-btn').attr('disabled', not enabled )
            if (e.which == 27) then return @hide()
            if (e.which == 13 and enabled) then return @callback()

        jQuery('#crypt-key-plain').toggle().toggle().val("")
        jQuery('#crypt-key-pass').toggle().toggle().val("")

    show: (title, action, body, more) ->
        @frame = jQuery(HTML_POPUP(@encipher.base, title, body, action, more))
        jQuery('body').append( @frame )
        if action == "Cancel"
            jQuery('#crypt-btn').attr('disabled',false).click( => @hide() ).keyup( (e)=> if e.which == 27 then @hide() ).focus()
        else
            jQuery('#crypt-btn').click => @callback()
        # Resize handler
        jQuery(window).resize => @layout()
        # Close handler
        jQuery('#crypt-close').click => @hide()
        @layout()
 
    alert: (msg) ->
        jQuery('#crypt-message').html( msg )

    # Hide dialog
    hide: ->
        @frame.remove()
        @frame = null

    isVisible: ->
        @frame and @frame.is(':visible')

    # Update dialog position
    layout: ->
        [width,height] = [400,105]
        @frame and @frame.css {'top': (jQuery(window).height() - height) / 2 + 'px', 'left':(jQuery(window).width() - width) / 2 + 'px', 'width':width + 'px' , 'height':height + 'px' }

    # Encryption password
    password: ->
        if jQuery('#crypt-key-plain').is(':visible')
            jQuery('#crypt-key-plain').attr('value')
        else
            jQuery('#crypt-key-pass').attr('value')

    # Key score
    score: ->
        value = @password()
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


CRYPTO_HEADER="EnCt2"

CRYPTO_FOOTER="IwEmS"

# Main service class
window.Encipher = class Encipher

    constructor: (@base) ->
        @base ||= (window.location.protocol + '//' + window.location.host)
        @format = new Format(@)
        @cache = {}

    # Extract ciphered message or hash reference from the text
    extractCipher: (message)->
        parts = (message or "").match /.*(EnCt2.*IwEmS).*/
        return parts[1] if parts
        parts = (message or "").match /.*(\$[0-9A-Fa-f]{40}).*/
        return parts and parts[1]

    # Traverse document and collect all encrypted blocks to collection
    findEncrypted: ->
        # Collection of elements and related text blocks
        [nodes, texts] = [[],[]]

        # Extract encoded block from element and put it to collection
        found = (elem,txt) =>
            cipher = @extractCipher(txt.replace(/[\n> ]/g,''))
            if cipher
                nodes.push elem
                texts.push cipher
                return 1
            else
                return 0

        # Traverse DOM and search for encoded block headers
        traverse = (node) ->
            skip = 0
            # Text node
            if node.nodeType == 3 and node.data.indexOf( CRYPTO_HEADER ) >= 0
                elem = jQuery(node.parentNode)
                skip = found( elem, elem.text() )
            else
                # Element node
                if (node.nodeType == 1 && !/(script|style)/i.test(node.tagName))
                    # Text area or input
                    if /(input|textarea)/i.test( node.tagName )
                        elem = jQuery(node)
                        found( elem, elem.val() )
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
                iframe = $(this).get(0)
                if iframe.src.indexOf(location.protocol + '//' + location.host) == 0 or iframe.src.indexOf('about:blank') == 0 or iframe.src == ''
                    try
                        traverseBody( jQuery(this).contents().find('body') )
                    catch e
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
                @gui and @gui.alert( "Generating key: #{Math.floor(per)}%" )
            ,
            (key)=>
                # Put key to cache
                @cache[cacheKey]=key
                callback(key)
        )

    # Decrypt text in DOM node
    decryptNode: (node, text, password, callback)->
        @format.beforeDecrypt text, (err, text)=>
            return callback(false) if err
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
                    callback( true )
                else
                    callback( false )
 
    # Decrypt all encrypted nodes
    decrypt: (password, callback)->
        i = 0
        success = false
        # Trick for sequence of async calls
        next = =>
            if @nodes.length > i
                @decryptNode @nodes[i], @texts[i], password, (res)=>
                    i += 1
                    success ||= res
                    next()
            else
                callback( success )
        next()

    # Encrypt text in input element
    encrypt: (password, callback)->
        salt = Base64.random(8)
        @derive password, salt, (key) =>
            # Calculate HMAC digest
            hmac = hex_hmac_sha1(key, @text )
            # Pad to to 256bit (reserved for sha256 hash)
            hmac += hmac[0...24]
            cipher = CRYPTO_HEADER + hmac + salt + Aes.Ctr.encrypt( @text, key, 256) + CRYPTO_FOOTER
            
            @format.afterEncrypt cipher, (err, cipher)=>
                @updateNode @node, cipher
                callback( true )

    # Update text 
    updateNode: (node, value)->
        if node.is('textarea')
            node.val( value )
        else
            node.html( value.replace /\n/g,'<br/>' )

    # Called when injected by bookmarklet
    startup: ->
        @gui ||= new Popup(@, @onAction)
        if @gui.isVisible()
            @gui.hide()
        else
            if @parse()
                if @encrypted
                    @gui.input "Enter decryption key", "Decrypt"
                else
                    if @text
                        @gui.input "Enter encryption key", "Encrypt", HTML_CHECKBOX
                    else
                        @gui.show "Message is empty", "Cancel", "Please enter the message first"
            else
                @gui.show "Message not found", "Cancel", "Please select the input area"

    # Encrypt/decrypt GUI action handler
    onAction: =>
        if @encrypted
            @decrypt( @gui.password(), @onResult )
        else
            @encrypt( @gui.password(), @onResult )

    # Action result handler
    onResult: (good)=>
        if good
            @gui.hide()
        else
            @gui.alert("Invalid password")

# Format encrypted as text
class TextFormat
    constructor: (@encipher)->

    afterEncrypt: (message, callback) ->
        callback( null, message.match(/.{0,80}/g).join('\n') + "\nEncrypted by " + @encipher.base )

    beforeDecrypt: (message, callback) ->
        callback( null, message )

# Format encrypted as link
class LinkFormat
    constructor: (@encipher)->

    afterEncrypt: (message, callback) ->
        callback( null, @encipher.base + '#' + message )

    beforeDecrypt: (message, callback) ->
        callback( null, message )

# Format encrypted text as short link (will be stored on server)
class ShortLinkFormat
    constructor: (@encipher)->

    afterEncrypt: (message, cb)->
        body = @encipher.extractCipher( message )
        return cb(null, message) if not body
        $.post @encipher.base + "/pub", {body}, (res)=>
            cb(null, message.replace( body, @encipher.base + '#$'+res) )

    beforeDecrypt: (message, cb)->
        hash = @encipher.extractCipher( message )
        return cb(null, message) if not hash or hash[0] != '$'
        $.post @encipher.base + "/pub", {hash:hash[1...]}, (res)=>
            cb(null, message.replace(hash, res) )

# Format selector
class Format
    constructor: (@encipher)->
        @text  = new TextFormat(@encipher)
        @link  = new LinkFormat(@encipher)
        @short = new ShortLinkFormat(@encipher)
        @selected  = @short

    # Format with with selected type
    afterEncrypt: (message, callback) ->
        @selected.afterEncrypt(message, callback)

    # Unpack all supported formats
    beforeDecrypt: (message, callback) ->
        @text.beforeDecrypt message, (err, message)=>
            return callback(err, message) if err
            @link.beforeDecrypt message, (err, message)=>
                return callback(err, message) if err
                @short.beforeDecrypt message, callback
