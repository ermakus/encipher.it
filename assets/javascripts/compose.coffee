window.encipher = new Encipher()

window.fbAsyncInit = ->
    FB.init
        appId:'159179810783818'
    FB.XFBML.parse(document.getElementById('like'))


$(document).ready ->

    # Composer box
    composer = $('#txt')

    composer.click ->
        if composer.val() == 'Sample text'
              composer.val("")
              composer.unbind()

    if FlashDetect.majorAtLeast(9)
        # Copy to clipboard
        clip = new ZeroClipboard.Client()
        clip.glue('copy','copyholder')
        clip.addEventListener 'onComplete', (client, text) ->
            $('body').css('background-color': "#213e4a")
            setTimeout ->
                    $('body').css 'background-color' : "#355664"
            , 300
        clip.addEventListener 'onMouseDown', (client)->
            clip.setText( composer.val() )
    else
        $('#copyholder').click ->
            window.prompt "Copy to clipboard: Ctrl+C, Enter", composer.val()

    $('.close').click ->
        $(this).parent().remove()

    window.encipher.success = (mode, cipher)->
        $('.cmd').hide()
        $('.' + mode).show()

    $('.cmd').hide()
    $('.plain').show()

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
            link: composer.val()
        )
