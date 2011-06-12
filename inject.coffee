BASE_URL="http://localhost:3000"

HELP="This message is encrypted. Visit #{BASE_URL} to learn how to deal with it.\n"

CRYPTO_HEADER="-----BEGIN-ENCRYPTED-MESSAGE-----"

CRYPTO_FOOTER="-----END-ENCRYPTED-MESSAGE-----"


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
            <div style='position: fixed; z-index: 9999; background: #BCF; border: solid gray 1px;'>
                <div style='position: absolute; left: 0; right: 0; background: #C8D6FF; margin: 4px; height: 32px;'>
                    <b>#{title}</b>
`                   <img style='border: none; float: right;' id='crypt-close' src='#{@base}/close.png'/>
                </div>
                <div style='position: absolute; bottom: 0; top: 32px; margin: 4px; padding: 10px; background: white; left: 0; right: 0;'>
                    #{controls}
                    <input style='position: absolute; display: block; right: 4px; bottom: 4px;' id='crypt-encode' type='button' value='#{action}'/>
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
        $('#crypt-key').focus()
        $('#crypt-encode').click =>
            if @encrypted
                while @encrypted
                    @updateText Aes.Ctr.decrypt( @txt, @key(), 256)
                    break unless @parse()
            else
                if @parse()
                    @updateText HELP + "\n" + CRYPTO_HEADER + "\n" + Aes.Ctr.encrypt( @txt, @key(), 256) + "\n" + CRYPTO_FOOTER
            @hide()

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
        @msg = $('#canvas_frame').contents().find( "*:contains('#{CRYPTO_HEADER.trim()}'):last" )
        if @msg.length
            @txt = @msg.get(0).textContent||@msg.get(0).innerText
        else
            @msg = $('body').find( "*:contains('#{CRYPTO_HEADER.trim()}'):last" )
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
       window.CRYPT_GUI = new Popup( BASE_URL, 400, 110 )

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
