(function() {
  var BASE_URL, CRYPTO_FOOTER, CRYPTO_HEADER, HELP, Popup, main, show;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  BASE_URL = "http://localhost:3000";
  HELP = "This message is encrypted. Visit " + BASE_URL + " to learn how to deal with it.\n";
  CRYPTO_HEADER = "-----BEGIN-ENCRYPTED-MESSAGE-----";
  CRYPTO_FOOTER = "-----END-ENCRYPTED-MESSAGE-----";
  Popup = (function() {
    function Popup(base, width, height) {
      var action, controls, title, _ref, _ref2;
      this.base = base;
      this.width = width;
      this.height = height;
      if (this.parse()) {
        _ref = this.encrypted ? ["Enter decryption key", "Decrypt"] : ["Enter encryption key", "Encrypt"], title = _ref[0], action = _ref[1];
        controls = "<input type='text' style='position: absolute; display: block; top: 4px; left: 4px; right: 4px; bottom: 32px;' id='crypt-key'/>";
      } else {
        _ref2 = ["Letter not found", "Cancel"], title = _ref2[0], action = _ref2[1];
        controls = "Please switch to plain text if you compose it in GMail rich formatting mode.";
      }
      this.frame = $("            <div style='position: fixed; z-index: 9999; background: #BCF; border: solid gray 1px;'>                <div style='position: absolute; left: 0; right: 0; background: #C8D6FF; margin: 4px; height: 32px;'>                    <b>" + title + "</b>`                   <img style='border: none; float: right;' id='crypt-close' src='" + this.base + "/close.png'/>                </div>                <div style='position: absolute; bottom: 0; top: 32px; margin: 4px; padding: 10px; background: white; left: 0; right: 0;'>                    " + controls + "                    <input style='position: absolute; display: block; right: 4px; bottom: 4px;' id='crypt-encode' type='button' value='" + action + "'/>                </div>            </div>        ");
      $('body').append(this.frame);
      this.layout();
      $(window).resize(__bind(function() {
        return this.layout();
      }, this));
      $('#crypt-close').click(__bind(function() {
        return this.hide();
      }, this));
      $('#crypt-key').focus();
      $('#crypt-encode').click(__bind(function() {
        if (this.encrypted) {
          while (this.encrypted) {
            this.updateText(Aes.Ctr.decrypt(this.txt, this.key(), 256));
            if (!this.parse()) {
              break;
            }
          }
        } else {
          if (this.parse()) {
            this.updateText(HELP + "\n" + CRYPTO_HEADER + "\n" + Aes.Ctr.encrypt(this.txt, this.key(), 256) + "\n" + CRYPTO_FOOTER);
          }
        }
        return this.hide();
      }, this));
    }
    Popup.prototype.key = function() {
      return $('#crypt-key').attr('value');
    };
    Popup.prototype.updateText = function(value) {
      if (this.msg.is('textarea')) {
        return this.msg.val(value);
      } else {
        return this.msg.html(value.replace(/\n/g, '<br/>'));
      }
    };
    Popup.prototype.parse = function() {
      var ftr, hdr;
      this.msg = $('#canvas_frame').contents().find("*:contains('" + (CRYPTO_HEADER.trim()) + "'):last");
      if (this.msg.length) {
        this.txt = this.msg.get(0).textContent || this.msg.get(0).innerText;
      } else {
        this.msg = $('body').find("*:contains('" + (CRYPTO_HEADER.trim()) + "'):last");
        if (this.msg.length) {
          this.txt = this.msg.get(0).textContent || this.msg.get(0).innerText;
        } else {
          this.msg = $('#canvas_frame').contents().find('textarea[name=body]');
          if (this.msg.length) {
            this.txt = this.msg.val();
          } else {
            this.msg = $('textarea');
            if (this.msg.length) {
              this.txt = this.msg.val();
            } else {
              return false;
            }
          }
        }
      }
      if (!this.msg.length) {
        return false;
      }
      if (this.txt.indexOf(CRYPTO_HEADER) >= 0) {
        this.txt = this.txt.replace(/[\n <>]/g, '');
        hdr = this.txt.indexOf(CRYPTO_HEADER);
        ftr = this.txt.indexOf(CRYPTO_FOOTER);
        this.txt = this.txt.slice(hdr + CRYPTO_HEADER.length, ftr);
        this.encrypted = true;
      } else {
        this.encrypted = false;
      }
      return true;
    };
    Popup.prototype.hide = function() {
      this.frame.remove();
      return window.CRYPT_GUI = void 0;
    };
    Popup.prototype.layout = function() {
      return this.frame.css({
        'top': ($(window).height() - this.height) / 2 + 'px',
        'left': ($(window).width() - this.width) / 2 + 'px',
        'width': this.width + 'px',
        'height': this.height + 'px'
      });
    };
    return Popup;
  })();
  show = function() {
    if (window.CRYPT_GUI) {
      return window.CRYPT_GUI.hide();
    } else {
      return window.CRYPT_GUI = new Popup(BASE_URL, 400, 110);
    }
  };
  main = function() {
    var count, ready, script, script_tag, scripts, _i, _len, _results;
    if (window.CRYPT_LOADED) {
      return show();
    } else {
      scripts = ['jquery.min.js', 'AES.js', 'base64.js', 'utf8.js'];
      count = scripts.length;
      ready = function() {
        count -= 1;
        if (count === 0) {
          window.CRYPT_LOADED = true;
          return show();
        }
      };
      _results = [];
      for (_i = 0, _len = scripts.length; _i < _len; _i++) {
        script = scripts[_i];
        script_tag = document.createElement('script');
        script_tag.setAttribute("type", "text/javascript");
        script_tag.setAttribute("src", BASE_URL + "/javascripts/" + script);
        script_tag.onload = ready;
        script_tag.onreadystatechange = function() {
          if (this.readyState === 'complete' || this.readyState === 'loaded') {
            return ready();
          }
        };
        _results.push(document.getElementsByTagName("head")[0].appendChild(script_tag));
      }
      return _results;
    }
  };
  main();
}).call(this);
