BASE_URL="http://localhost:3000"

HELP="This message is encrypted. Visit #{BASE_URL} to learn how to deal with it.\n\n"

CRYPTO_HEADER="EnCt1"

CRYPTO_FOOTER="IwEmS"


# Popup dialog
class Popup
 
    # Create dialog
    constructor: (@base, @width, @height) ->

        if @parse()
            body = "<input type='text' style='position: absolute; display: block; top: 4px; left: 4px; right: 4px; bottom: 32px; width: 97%;' id='crypt-key'/>"
            if @encrypted
                @show "Enter decryption key","Decrypt", body
            else
                @show "Enter encryption key","Encrypt", body
        else
            @show "Message not found","Cancel","Please select input area"

        # Encrypt handler
        $('#crypt-key').focus().keyup (e)=>
            enabled = @key() != ''
            $('#crypt-btn').attr('disabled', not enabled )
            if (e.which == 27) then return @hide()
            if (e.which == 13 and enabled) then return @run()


    show: (title, action, body) ->
        @frame = $("
            <div style='position: fixed; z-index: 9999; background: #355664; border: solid gray 1px; -moz-border-radius: 10px; -webkit-border-radius: 10px; border-radius: 10px'>
                <div style='position: absolute; left: 0; right: 0; color: white; margin: 4px; height: 32px;'>
                    <b style='padding: 8px; float: left;'>#{title}</b>
                    <img style='border: none; float: right;' id='crypt-close' src='#{@base}/close.png'/>
                </div>
                <div style='position: absolute; bottom: 0; top: 32px; margin: 4px; padding: 10px; left: 0; right: 0;'>
                    #{body}
                    <span style='position: absolute; display: block; left: 4px; bottom: 4px; color: #FFA0A0;' id='crypt-message''></span>
                    <input disabled='true' style='position: absolute; display: block; right: 4px; bottom: 4px;' id='crypt-btn' type='button' value='#{action}'/>
                </div>
            </div>
        ")
        $('body').append( @frame )
        if action == "Cancel"
            $('#crypt-btn').attr('disabled',false).click => @hide()
        else
            $('#crypt-btn').click => @run()
        # Resize handler
        $(window).resize => @layout()
        # Close handler
        $('#crypt-close').click => @hide()
        @layout()
 
    alert: (msg) ->
        $('#crypt-message').html( msg )

    run: ->
            if @encrypted
                successs = false
                for i in [0...@nodes.length]
                    text = @texts[i]
                    node = @nodes[i]

                    hash = text[0...64]
                    text = text[64...]
                    text = Aes.Ctr.decrypt( text, @key(), 256)
                    newHash = Sha256.hash text
                    if hash == newHash
                        @updateNode node, text
                        success = true
                if not success
                    @alert "Invalid key"
                    return false
            else
                if @parse()
                    if not @text
                        @alert("Text is empty")
                        return false
                    hash = Sha256.hash @text
                    @updateNode @node, HELP + @dump( hash + Aes.Ctr.encrypt( @text, @key(), 256) )
            @hide()

    dump: (text) ->
        i = 0
        out = ""
        for ch in CRYPTO_HEADER + text + CRYPTO_FOOTER
            out += ch
            i += 1
            if (i % 5) == 0 then out += ' '
            if (i % 60 ) == 0 then out += '\n'
        out

    # Encryption key
    key: ->
        $('#crypt-key').attr('value')

    # Update text 
    updateNode: (node, value)->
        if node.is('textarea') or node.is('input')
            node.val( value )
        else
            node.html( value.replace /\n/g,'<br/>' )


    # Traverse document and collect all encrypted blocks to collection
    findEncrypted: ->
        # Collection of elements and related text blocks
        [nodes, texts] = [[],[]]

        # Extract encoded block from element and put it to collection
        found = (elem,txt) ->
            txt = txt.replace /[\n ]/g,''
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
                elem = $(node.parentNode)
                skip = found( elem, elem.text() )
            else
                # Element node
                if (node.nodeType == 1 && !/(script|style)/i.test(node.tagName))
                    # Text area or input
                    if /(input|textarea)/i.test( node.tagName )
                        elem = $(node)
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
                    traverseBody( $(this).contents().find('body') )
                catch e


        traverseBody $('body')
    
        return [nodes,texts]


    # Return input element and text (simple heuristic used)
    findInput: ->
        # Check for gmail first
        # Plain textarea
        node = $('#canvas_frame').contents().find('textarea[name=body]:visible')
        if node.length then return [node, node.val()]
        # Rich formatting
        node = $('#canvas_frame').contents().find('iframe.editable').contents().find('body')
        if node.length then return [node, node.html()]
        # Fail otherways if we on gmail
        if $('#canvas_frame').length then return [undefined,undefined]
        # Return textarea if only one
        node = $('textarea')
        if node.length == 1 then return [node, node.val()]
        # If many textareas, then select focused one
        if node.length > 1 then node = $('textarea:focus')
        if node.length == 1 then return [node, node.val()]
        # else select focused input
        node = $('input[type=text]:focus')
        if node.length == 1 then return [node, node.val()]
        # Fail finally
        return [undefined,undefined]
 
    parse: ->
        [@nodes, @texts] = @findEncrypted()
        [@node,  @text]  = @findInput()
        @encrypted = @nodes.length > 0
        return @encrypted or @node != undefined

    # Hide dialog
    hide: ->
        @frame.remove()
        window.CRYPT_GUI = undefined

    # Update dialog position
    layout: ->
        @frame.css {'top': ($(window).height() - @height) / 2 + 'px', 'left':($(window).width() - @width) / 2 + 'px', 'width':@width + 'px' , 'height':@height + 'px' }

show = ->
    if window.CRYPT_GUI
       window.CRYPT_GUI.hide()
    else
       window.CRYPT_GUI = new Popup( BASE_URL, 400, 105 )

# Entry point
main = ->
    if window.CRYPT_LOADED
        show()
    else
        # Load javascript dependencies
        scripts = ['jquery.min.js','AES.js','base64.js','utf8.js']
        count = scripts.length

        #if typeof jQuery == "undefined" or jQuery.fn.jquery != '1.4.2'
        #    scripts.push 'jquery.min.js'

        ready = ->
            count -= 1
            if count == 0
                window.CRYPT_LOADED =true
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
