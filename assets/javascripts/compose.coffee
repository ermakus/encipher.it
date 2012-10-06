window.fbAsyncInit = ->
    FB.init
        appId:'159179810783818'
    FB.XFBML.parse(document.getElementById('like'))

window.googleAsyncInit = ->

window.extractCipher = (message)->
    parts = (message or "").match /.*(EnCt2.*IwEmS).*/
    return parts and parts[1]

window.compressLink = (message, cb)->
    parts = (message or "").match /.*(https?:\/\/.*#EnCt2.*IwEmS).*/
    link = parts and parts[1]
    return cb(null, message) if not link
    gapi.client.load 'urlshortener', 'v1', ->
        request = gapi.client.urlshortener.url.insert
            'resource':
                'longUrl': link
        resp = request.execute (resp)->
            if resp.error
                cb(resp.error, message)
            else
                cb(null, message.replace( link, resp.id ) )

$ ->
    # Composer box
    composer = $('#txt')

    composer.click ->
        if composer.val() == 'Sample text'
              composer.val("")
              #composer.unbind()

    setInterval( ->
        compressLink composer.val(), (error, message)->
            if not error
                composer.val(message)
            else
                console.log error.message
    , 1000)

    # Copy to clipboard
    clip = new ZeroClipboard.Client()
    clip.glue('copy')
    clip.addEventListener 'onComplete', (client, text) ->
        $('body').css('background-color': "#213e4a")
        setTimeout ->
                $('body').css 'background-color' : "#355664"
        , 300
    clip.addEventListener 'onMouseDown', (client)->
        clip.setText( composer.val() )
    $(window).resize ->
        clip.reposition()

    # Send to socials
    $('.gmail').click ->
        window.open "https://mail.google.com/mail/?view=cm&ui=2&tf=0&fs=1&to=&su=" +
                    "&body=" + encodeURIComponent(composer.val())

    $('.twitter').click ->
        window.open "https://twitter.com/home?status=" + encodeURIComponent(composer.val())

    $('.facebook').click ->
        FB.ui(
            method: 'send'
            name: "Click here to read encrypted message"
            link: "http://encipher.it/#" + extractCipher(composer.val())
        )

    cipher = extractCipher(window.location.hash)
    if cipher
        composer.val(cipher)
        $('#message').show()
        $('#help').hide()
        clip.reposition()

