BASE_URL="http://localhost:3000"

HELP="This message is encrypted. Visit #{BASE_URL} to learn how to deal with it.\n\n"

CRYPTO_HEADER="ENCT1"

CRYPTO_FOOTER="IWEMS"

# Popup dialog
class Popup

    # Create dialog
    constructor: (@base, @width, @height) ->
        if @parse()
            [title, action] =  if @encrypted then ["Enter decryption key","Decrypt"] else ["Enter encryption key","Encrypt"]
            controls = "<input type='text' style='position: absolute; display: block; top: 4px; left: 4px; right: 4px; bottom: 32px;' id='crypt-key'/>"
        else
            [title, action] = ["Letter not found","Cancel"]
            controls = "Please switch to plain text if you compose it in GMail rich formatting mode."

        @frame = $("
            <div style='position: fixed; z-index: 9999; background: #355664; border: solid gray 1px; moz-border-radius: 10px; -webkit-border-radius: 10px; border-radius: 10px'>
                <div style='position: absolute; left: 0; right: 0; color: white; margin: 4px; height: 32px;'>
                    <b style='padding: 8px; float: left;'>#{title}</b>
                    <img style='border: none; float: right;' id='crypt-close' src='#{@base}/close.png'/>
                </div>
                <div style='position: absolute; bottom: 0; top: 32px; margin: 4px; padding: 10px; left: 0; right: 0;'>
                    #{controls}
                    <span style='position: absolute; display: block; left: 4px; bottom: 4px; color: #FFA0A0;' id='crypt-message''></span>
                    <input disabled='true' style='position: absolute; display: block; right: 4px; bottom: 4px;' id='crypt-encode' type='button' value='#{action}'/>
                </div>
            </div>
        ")
        $('body').append( @frame )
        @layout()
        # Resize handler
        $(window).resize => @layout()
        # Close handler
        $('#crypt-close').click => @hide()
        # Encrypt handler
        $('#crypt-key').focus().keyup (e)=>
            enabled = @key() != ''
            $('#crypt-encode').attr('disabled', not enabled )
            if (e.which == 27) then return @hide()
            if (e.which == 13 and enabled) then return @run()

        $('#crypt-encode').click => @run()


    alert: (msg) ->
        $('#crypt-message').html( msg )

    run: ->
            if @encrypted
                while @encrypted
                    hash = @txt[0...64]
                    text = @txt[64...]
                    text = Aes.Ctr.decrypt( text, @key(), 256)
                    newHash = Sha256.hash text
                    if hash == newHash
                        @updateText text
                    else
                        @alert "Invalid key"
                        return false
                    break unless @parse()
            else
                if @parse()
                    if not @txt
                        @alert("Text is empty")
                        return false
                    hash = Sha256.hash @txt
                    @updateText HELP + @dump( hash + Aes.Ctr.encrypt( @txt, @key(), 256) )
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
    updateText: (value)->
        if @msg.is('textarea')
            @msg.val( value )
        else
            @msg.html( value.replace /\n/g,'<br/>' )

    parse: ->
        @msg = $('#canvas_frame').contents().find( "*:contains('#{CRYPTO_HEADER.trim()}'):last:visible" )
        if @msg.length
            @txt = @msg.get(0).textContent||@msg.get(0).innerText
        else
            @msg = $('body').find( "*:contains('#{CRYPTO_HEADER.trim()}'):last:visible" )
            if @msg.length
                @txt = @msg.get(0).textContent||@msg.get(0).innerText
            else
                @msg = $('#canvas_frame').contents().find('textarea[name=body]')
                if @msg.length
                    @txt = @msg.val()
                else
                    @msg = $('textarea')
                    if @msg.length
                        @txt = @msg.val()
                    else
                        return false

        return false unless @msg.length

        if @txt.indexOf( CRYPTO_HEADER ) >= 0
            @txt = @txt.replace /[\n <>]/g,''
            hdr = @txt.indexOf( CRYPTO_HEADER )
            ftr = @txt.indexOf( CRYPTO_FOOTER )
            @txt = @txt[ hdr + CRYPTO_HEADER.length ... ftr ]
            @encrypted = true
        else
            @encrypted = false

        true

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
