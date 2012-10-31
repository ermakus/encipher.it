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
    line-height: 25px;
    -moz-border-radius: 4px; 
    -webkit-border-radius: 4px; 
    border-radius: 4px;
}

.encipher-text {
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

.encipher-tab-settings {
    position: absolute;
    top: 20px;
    bottom: 0px;
    right: 0px;
    left: 0px;
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

.encipher-link {
    position: absolute;
    bottom: 5px;
    text-align: right;
    display: block;
    float: right;
    display: inline-block;
    margin: 0;
    padding: 0;
    padding-left: 20px;
    cursor: pointer;
    color:#0196E3;
    font-size: 14px;
    font-family:Arial, Helvetica, sans-serif; 
    font-weight: bold;
}

.encipher-link:hover {
    text-decoration: underline;
}

.encipher-it {
    background: url(#{encipher.base}/images/encrypt-white.png) no-repeat center left;
    right: 5px;
}

.encipher-yes {
    background: url(#{encipher.base}/images/settings-white.png) no-repeat center left;
    right: 5px;
}

.encipher-no {
    background: url(#{encipher.base}/images/close-white.png) no-repeat center left;
    right: 85px;
}

.encipher-option {
    float: left;
    clear: both;
    padding-bottom: 10px;
}

</style>

<div class='encipher-popup'>
    <div class='encipher-icon encipher-close'></div>
    <div class='encipher-tab encipher-tab-key'>
        <div class='encipher-icon encipher-settings'></div>
        <div class='encipher-text encipher-title'></div>
        <div class='encipher-key'>
            <input type='text' class='encipher-key-input encipher-key-plain' style='display: none;'/>
            <input type='password' class='encipher-key-input encipher-key-pass'/>
            <div class='encipher-key-mode'></div>
        </div>
        <div class='encipher-link encipher-it'>Encipher It</div>
    </div>
    <div class='encipher-tab encipher-tab-settings'>
        <div class='encipher-text encipher-option'>Convert encrypted text into short link?</div>
        <div class='encipher-text encipher-option'><input type='checkbox' class='encipher-always'>&nbsp;Do not ask next time</div>
        <div class='encipher-link encipher-no'>No</div>
        <div class='encipher-link encipher-yes'>Yes</div>
    </div>
    <div class='encipher-text encipher-message'></div>
</div>
"""

# Set and get cookie - used to save user settings
setCookie = (name, value, days)->
    if (days)
        date = new Date()
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000))
        expires = "; expires=" + date.toGMTString()
    else
        expires = ""
    document.cookie = name + "=" + value + expires + "; path=/";

getCookie = (c_name)->
    if document.cookie.length > 0
        c_start = document.cookie.indexOf(c_name + "=")
        if (c_start != -1)
            c_start = c_start + c_name.length + 1
            c_end = document.cookie.indexOf(";", c_start)
            if (c_end == -1)
                c_end = document.cookie.length
            return unescape(document.cookie.substring(c_start, c_end))
    return ""

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
        jQuery('.encipher-settings').click =>
            @settings true, =>
                jQuery('.encipher-tab').hide()
                jQuery('.encipher-tab-key').show()

    refresh: ->
        if @key() != ''
            jQuery('.encipher-it').show()
        else
            jQuery('.encipher-it').hide()

    # Enter key
    input: ( title, button, callback ) ->
        jQuery('.encipher-key-input').val("").unbind().keyup (e)=>
            score = @score()
            jQuery('.encipher-message').html(score)
            if (e.which == 27) then return @hide()
            if (e.which == 13 and @key()) then return callback(@key())
            @refresh()
        jQuery('.encipher-title').html( title )
        jQuery('.encipher-tab').hide()
        jQuery('.encipher-tab-key').show()
        jQuery('.encipher-key-input:visible').focus()
        jQuery('.encipher-it').html( button ).unbind().bind 'click', => callback(@key())
        @message("")
        @refresh()
        @frame.show()

    # Show alert
    alert: ( message ) ->
        jQuery('.encipher-tab').hide()
        jQuery('.encipher-title').html("")
        @message message
        @refresh()
        @frame.show()

    # settings
    settings: ( show, callback ) ->
        jQuery('.encipher-tab').hide()
        jQuery('.encipher-tab-settings').show()
        @message("")
        @refresh()
        mode = getCookie('encipher-link')
        check = jQuery('.encipher-always')
        if mode in ['yes','no']
            check.attr('checked','checked')
        if mode == 'yes' and not show
            return callback( true )
        if mode == 'no' and not show
            return callback( false )
        jQuery('.encipher-yes').unbind().bind 'click', =>
            if check.is(':checked')
                setCookie 'encipher-link', 'yes'
            else
                setCookie 'encipher-link', 'ask'
            callback( true )
        jQuery('.encipher-no').unbind().bind 'click', =>
            if check.is(':checked')
                setCookie 'encipher-link', 'no'
            else
                setCookie 'encipher-link', 'ask'
            callback( false )

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


# Format encrypted as plain text
class TextFormat
    constructor: (@base) ->
        @HAS = /EnCt2/
        @EXTRACT = /(EnCt2.*IwEmS)/

    hasCipher: (message)->
        return false unless message
        return (message or "").match @HAS

    # Extract ciphered message
    extractCipher: (message)->
        parts = (message or "").replace(/[\n> ]/g,'').match @EXTRACT
        if parts
            return parts[1]
        else
            return false

    pack: (message, callback) ->
        callback( null, message.match(/.{0,80}/g).join('\n') + "\nEncrypted by " + @base )

    unpack: (message, callback) ->
        message = @extractCipher(message)
        if message
            callback( null, message )
        else
            callback( new Error("Encrypted message not found" ) )

# Format encrypted text as short link 
# Ciphered text will be stored on the public remote server
class LinkFormat extends TextFormat

    constructor: (@base)->
        base = base.replace(/([\:\.\/])/g,"\\$1")
        @HAS = new RegExp("#{base}")
        @EXTRACT = new RegExp("(#{base}\\?[0-9A-Za-z]+)")

    pack: (message, cb)->
        jQuery.post @base + "/pub", {body:message}, (guid)=>
            cb(null, @base + '?'+guid )
        .error ->
            cb( new Error("Can't create link") )

    unpack: (message, cb)->
        url = @extractCipher( message )
        return cb(null, message) if not url
        guid = url[@base.length+1...]
        jQuery.post @base + "/pub", {guid}, (res)=>
            cb(null, res)
        .error ->
            cb( new Error("Can't expand link") )


# Main service class
window.Encipher = class Encipher

    constructor: (@base) ->
        @base ||= (window.location.protocol + '//' + window.location.host)
        @cache = {}

        # Encrypted text formatters
        @format =
            text : new TextFormat(@base)
            link : new LinkFormat(@base)

    # Traverse document and collect all encrypted blocks to collection
    findEncrypted: ->
        # Collection of elements and related text blocks
        [nodes, texts] = [[],[]]

        # Extract encoded block from element and put it to collection
        found = (elem,txt) =>
            if elem[0].nodeName.toLowerCase() == 'a'
                elem = elem.parent()
            cipher = @format.text.extractCipher(txt) or @format.link.extractCipher(txt)
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
            if node.nodeType == 3 and (@format.text.hasCipher(node.data) or @format.link.hasCipher(node.data))
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
        # New composer
        node = jQuery('div.editable[g_editable=true]:visible')
        if node.length then return [node, node.html()]
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
        @unpack text, (error, text)=>
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
            @format.text.pack "EnCt2#{cipher}IwEmS", (error, cipher)=>
                if not error
                    @updateNode @node, cipher
                @cache = {}
                callback( error, cipher )

    # Update text 
    updateNode: (node, value)->
        if node.is('textarea')
            node.val( value.replace(/<(?:.|\n)*?>/gm, '\n'))
        else
            node.html( value.replace(/\n/g,'<br/>') )

    # Unpack all supported formats
    unpack: (message, callback) ->
        @format.link.unpack message, (err, message)=>
            return callback(err, message) if err
            @format.text.unpack message, callback

    # Called when injected by bookmarklet
    startup: ->
        @gui ||= new Popup(@)
        if @gui.isVisible()
            @gui.hide()
        else
            # Pare DOM
            if @parse()
                # If encrypted message found, decrypt
                if @encrypted
                    @gui.input "Enter decryption key", "Decipher It", (key)=>
                        @decrypt key, (error, success)=>
                            if success
                                if @success
                                    @success("plain")
                                @gui.hide()
                            else
                                if error
                                    @gui.message error.message
                                else
                                    @gui.message "Invalid key"
                else
                    # If input area found, encrypt
                    if @text
                        @gui.input "Enter encryption key", "Encipher It", (key)=>
                            @encrypt key, (error, cipher)=>
                                if error
                                    @gui.message error.message
                                else
                                    # Convert to short link, if needed
                                    @gui.settings false, (ok)=>
                                        if ok
                                            @format.text.unpack cipher, (error, cipher)=>
                                                if error
                                                    @gui.message error.message
                                                else
                                                    @format.link.pack (cipher), (error, cipher)=>
                                                        if error
                                                            @gui.message error.message
                                                        else
                                                            @updateNode @node, cipher
                                                            @gui.hide()
                                                            @success("link", cipher) if @success
                                        else
                                            @success("cipher", cipher) if @success
                                            @gui.hide()
                    else
                        @gui.alert "Message is empty"
            else
                @gui.alert "Message not found"

