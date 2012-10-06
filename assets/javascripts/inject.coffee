BASE_URL="http://localhost:3000"

# Entry point
startup = ->
    return window.encipher.startup() if window.encipher
    # Load javascript dependencies
    scripts = ['encipher.js', 'AES.js','sha1.js','pbkdf2.js','base64.js','utf8.js']
    # Load jQuery if not loaded already
    if typeof jQuery == "undefined" then scripts.push 'jquery.min.js'
    count = scripts.length

    ready = ->
        count -= 1
        if count == 0
            # Avoid conflicts if jquery is own
            if 'jquery.min.js' in scripts then $.noConflict()
            # JQuery focus selector
            jQuery.expr[':'].focus = ( elem ) -> return elem == document.activeElement && ( elem.type || elem.href )
            window.encipher = new Encipher( BASE_URL )
            window.encipher.startup()

    for script in scripts
        script_tag = document.createElement('script')
        script_tag.setAttribute "type","text/javascript"
        script_tag.setAttribute "src", BASE_URL + "/javascripts/" + script
        script_tag.onload = ready
        script_tag.onreadystatechange = ->
            if this.readyState == 'complete' or this.readyState == 'loaded' then ready()
        document.getElementsByTagName("head")[0].appendChild(script_tag)

startup()
