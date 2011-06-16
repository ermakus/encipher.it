BASE_URL="http://localhost:3000"

HELP="This message is encrypted. Visit #{BASE_URL} to learn how to deal with it.\n\n"

CRYPTO_HEADER="EnCt2"

CRYPTO_FOOTER="IwEmS"

# Popup dialog
class Popup

    constructor: ->
        @cache = {}
        if @parse()
            body = "<input type='text' style='position: absolute; display: block; top: 4px; left: 4px; right: 4px; bottom: 32px; width: 97%;' id='crypt-key'/>"
            if @encrypted
                @show "Enter decryption key","Decrypt", body
            else
                if @text
                    @show "Enter encryption key","Encrypt", body
                else
                    @show "Message is empty","Cancel","Please type the message first"
        else
            @show "Message not found","Cancel","Please select the input area"

        # Encrypt handler
        jQuery('#crypt-key').focus().keyup (e)=>
            enabled = @password() != ''
            jQuery('#crypt-btn').attr('disabled', not enabled )
            if (e.which == 27) then return @hide()
            if (e.which == 13 and enabled) then return @run()

    show: (title, action, body) ->
        @frame = jQuery("
            <div style='position: fixed; z-index: 9999; background: #355664; border: solid gray 1px; -moz-border-radius: 10px; -webkit-border-radius: 10px; border-radius: 10px'>
                <div style='position: absolute; left: 0; right: 0; color: white; margin: 4px; height: 32px;'>
                    <b style='padding: 8px; float: left;'>#{title}</b>
                    <img style='border: none; float: right;' id='crypt-close' src='#{BASE_URL}/close.png'/>
                </div>
                <div style='position: absolute; bottom: 0; top: 32px; margin: 4px; padding: 10px; left: 0; right: 0;'>
                    #{body}
                    <b style='position: absolute; display: block; left: 4px; bottom: 4px;' id='crypt-message''></b>
                    <input disabled='true' style='position: absolute; display: block; right: 4px; bottom: 4px;' id='crypt-btn' type='button' value='#{action}'/>
                </div>
            </div>
        ")
        jQuery('body').append( @frame )
        if action == "Cancel"
            jQuery('#crypt-btn').attr('disabled',false).click( => @hide() ).keyup( (e)=> if e.which == 27 then @hide() ).focus()
        else
            jQuery('#crypt-btn').click => @run()
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
        window.CRYPT_GUI = undefined

    # Update dialog position
    layout: ->
        [width,height] = [400,105]
        @frame.css {'top': (jQuery(window).height() - height) / 2 + 'px', 'left':(jQuery(window).width() - width) / 2 + 'px', 'width':width + 'px' , 'height':height + 'px' }

    # Encryption password
    password: -> jQuery('#crypt-key').attr('value')

    # Encrypt/decrypt entry point
    run: ->
        callback = (res)=>
            if res then @hide() else @alert("Invalid password")

        if @encrypted
            @decrypt( @password(), callback )
        else
            @encrypt( @password(), callback )

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
                @alert( "Generating key: #{Math.floor(per)}%" )
            ,
            (key)=>
                # Put key to cache
                @cache[cacheKey]=key
                callback(key)
        )

    # Decrypt text in DOM node
    decryptNode: (node, text, password, callback)->
        hash = text[0...64]
        salt = text[64...72]
        text = text[72...]
        @derive password, salt, (key) =>
            text = Aes.Ctr.decrypt( text, key, 256 )
            newHash = Sha256.hash text
            if hash == newHash
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
        hash = Sha256.hash @text
        salt = Base64.random(8)
        @derive password, salt, (key) =>
            @updateNode @node, HELP + @dump( hash + salt + Aes.Ctr.encrypt( @text, key, 256) )
            callback( true )

    dump: (text) ->
        text = CRYPTO_HEADER + text + CRYPTO_FOOTER

        i = 0
        out = ""
        for i in [0...text.length]
            out += text.charAt i
            if (i % 80 ) == 79 then out += '\n'
        out


    # Update text 
    updateNode: (node, value)->
        if node.is('textarea')
            node.val( value )
        else
            node.html( value.replace /\n/g,'<br/>' )


    # Traverse document and collect all encrypted blocks to collection
    findEncrypted: ->
        # Collection of elements and related text blocks
        [nodes, texts] = [[],[]]

        # Extract encoded block from element and put it to collection
        found = (elem,txt) ->
            txt = txt.replace /[\n> ]/g,''
            hdr = txt.indexOf( CRYPTO_HEADER )
            ftr = txt.indexOf( CRYPTO_FOOTER )
            if hdr >= 0 and ftr >= 0
                txt = txt[ hdr + CRYPTO_HEADER.length ... ftr ]
                nodes.push elem
                texts.push txt
                return 1
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
                try
                    traverseBody( jQuery(this).contents().find('body') )
                catch e


        traverseBody jQuery('body')
    
        return [nodes,texts]


    # Return input element and text (simple heuristic used)
    findInput: ->
        # Check for gmail first
        # Plain textarea
        node = jQuery('#canvas_frame').contents().find('textarea[name=body]:visible')
        if node.length then return [node, node.val()]
        # Rich formatting
        node = jQuery('#canvas_frame').contents().find('iframe.editable').contents().find('body')
        if node.length then return [node, node.html()]
        # Fail otherways if we on gmail
        if jQuery('#canvas_frame').length then return [undefined,undefined]
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


show = ->
    if window.CRYPT_GUI
       window.CRYPT_GUI.hide()
    else
       window.CRYPT_GUI = new Popup()

# Entry point
main = ->
    if window.CRYPT_LOADED
        show()
    else
        # Load javascript dependencies
        scripts = ['AES.js','sha1.js','pbkdf2.js','base64.js','utf8.js']
        # Load jQuery if not loaded already
        if typeof jQuery == "undefined" then scripts.push 'jquery.min.js'

        count = scripts.length

        ready = ->
            count -= 1
            if count == 0
                window.CRYPT_LOADED =true
                # Avoid conflicts if jquery is own
                if 'jquery.min.js' in scripts then $.noConflict()
                # JQuery focus selector
                jQuery.expr[':'].focus = ( elem ) -> return elem == document.activeElement && ( elem.type || elem.href )
                show()

        for script in scripts
            script_tag = document.createElement('script')
            script_tag.setAttribute "type","text/javascript"
            script_tag.setAttribute "src", BASE_URL + "/javascripts/" + script
            script_tag.onload = ready
            script_tag.onreadystatechange = ->
                if this.readyState == 'complete' or this.readyState == 'loaded' then ready()
            document.getElementsByTagName("head")[0].appendChild(script_tag)
main()
