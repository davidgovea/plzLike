(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (function($, window, document) {
    var PlzLike, defaults, pluginName;
    pluginName = "plzLike";
    defaults = {
      appId: '',
      page: '',
      fbScope: 'user_likes,email',
      width: null,
      height: null,
      firebaseUrl: '',
      firebaseNs: "plzlike-entrants",
      webhookUrl: '',
      method: 'POST'
    };
    PlzLike = (function() {
      var _this = this;

      function PlzLike(element, options) {
        this.element = element;
        this.changeView = __bind(this.changeView, this);
        this._submitPost = __bind(this._submitPost, this);
        this._submitFirebase = __bind(this._submitFirebase, this);
        this.settings = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = pluginName;
        this.init();
      }

      PlzLike.prototype.init = function() {
        var _this = this;
        $(this.element).addClass('plzlike-container');
        this.changeView('loading');
        this.loadFB(function() {
          _this.fetchPageId(function() {
            return _this.changeView('begin');
          });
          _this.fbAuthSubscribe();
          return _this.initClickHandlers();
        });
        if (this.settings.firebaseUrl) {
          return this.firebase = new Firebase(this.settings.firebaseUrl);
        }
      };

      PlzLike.prototype.loadFB = function(done) {
        var _this = this;
        if (window.FB != null) {
          return setTimeout(done, 0);
        } else {
          return $.getScript('//connect.facebook.net/en_UK/all.js', function() {
            FB.init({
              appId: _this.settings.appId,
              status: false,
              xfbml: false
            });
            return done();
          });
        }
      };

      PlzLike.prototype.fetchPageId = function(done) {
        var _this = this;
        return FB.api("/" + this.settings.page, function(res) {
          _this.settings.pageId = res.id;
          return done();
        });
      };

      PlzLike.prototype.fbAuthSubscribe = function() {
        var _this = this;
        return FB.Event.subscribe('auth.authResponseChange', function(res) {
          var _ref;
          if (res.status === 'connected') {
            _this.userId = (_ref = res.authResponse) != null ? _ref.userID : void 0;
            return FB.api("/me/likes/" + _this.settings.pageId, function(likeData) {
              var _ref1;
              if ((_ref1 = likeData.data) != null ? _ref1.length : void 0) {
                return _this.changeView('liked');
              } else {
                _this.changeView('like');
                return FB.Event.subscribe('edge.create', function(href, widget) {
                  debugger;
                  if (href.match(new RegExp(_this.settings.page, 'i'))) {
                    return _this.changeView('liked');
                  }
                });
              }
            });
          } else {
            return alert("You must connect with our app to enter");
          }
        });
      };

      PlzLike.prototype.initClickHandlers = function() {
        var $el,
          _this = this;
        $el = $(this.element);
        $el.on('click', '.plzlike-begin button', function(evt) {
          evt.preventDefault();
          evt.stopPropagation();
          return FB.login((function(res) {}), {
            scope: _this.settings.fbScope
          });
        });
        return $el.on('click', '.plzlike-liked button', function(evt) {
          evt.preventDefault();
          evt.stopPropagation();
          return _this.submit();
        });
      };

      PlzLike.prototype.submit = function() {
        var complete,
          _this = this;
        complete = function(err) {
          this.changeView('done');
          debugger;
        };
        return FB.api('/me', function(userData) {
          var submitFn;
          if (_this.firebase) {
            submitFn = _this._submitFirebase;
          } else if (_this.settings.webhookUrl) {
            submitFn = _this._submitPost;
          } else {
            throw new Error("No data store configured");
          }
          return submitFn(userData, complete);
        });
      };

      PlzLike.prototype._submitFirebase = function(data, done) {
        var userRecord,
          _this = this;
        userRecord = this.firebase.child("" + this.settings.firebaseNs + "/" + this.userId);
        return userRecord.on('value', function(snapshot) {
          if ((snapshot != null ? snapshot.val() : void 0) != null) {
            return _this.changeView('dupe');
          } else {
            return userRecord.set(data, done);
          }
        });
      };

      PlzLike.prototype._submitPost = function(data, done) {
        var _this = this;
        return $.ajax({
          url: this.settings.webhookUrl,
          method: this.settings.method,
          data: data,
          success: function(res) {
            var _ref;
            if ((_ref = res.code) === 409 || _ref === 420 || _ref === 429) {
              return _this.changeView('dupe');
            } else {
              return done();
            }
          },
          error: function(jqXHR, code, text) {
            return done(new Error(text));
          }
        });
      };

      PlzLike.prototype.changeView = function(name) {
        var $el, $incoming, existing;
        $el = $(this.element);
        existing = $el.find(".plzlike-" + name);
        if (existing.length) {
          $incoming = existing;
        } else {
          $incoming = $("<div class='plzlike-" + name + "'>" + (this.templates[name].call(this)) + "</div>");
          $el.append($incoming);
        }
        $el.find('.plzlike-active').removeClass('plzlike-active');
        if (typeof FB !== "undefined" && FB !== null) {
          FB.XFBML.parse($incoming.get(0));
        }
        return setTimeout((function() {
          return $incoming.addClass('plzlike-active');
        }), 0);
      };

      PlzLike.prototype.templates = {
        loading: function() {
          return "LOADING";
        },
        begin: function() {
          return "<button>Get started</button>";
        },
        like: function() {
          var _ref, _ref1;
          return "<div class=\"fb-like-box\"\n	data-href=\"http://www.facebook.com/" + this.settings.pageId + "\"\n	data-width=\"" + ((_ref = this.settings.width) != null ? _ref : $(this.element).width()) + "\"\n	data-height=\"" + (((_ref1 = this.settings.height) != null ? _ref1 : $(this.element).height()) || '') + "\"\n	data-colorscheme=\"light\"\n	data-show-faces=\"true\"\n	data-header=\"false\"\n	data-stream=\"false\"\n	data-show-border=\"false\">\n</div>";
        },
        liked: function() {
          return "<button>Submit entry</button>\n<div class=\"disclaimer\">\n	<small>This promotion is in no way sponsored, endorsed, administered by, or associated with Facebook.</small>\n</div>";
        },
        done: function() {
          return "THANKS\n<div class=\"fb-send\"\n	data-href=\"" + window.location.href + "\"\n	data-colorscheme='light'>\n</div>";
        },
        dupe: function() {
          return "Already entered";
        }
      };

      return PlzLike;

    }).call(this);
    return $.fn[pluginName] = function(options) {
      return this.each(function() {
        if (!$.data(this, "plugin_" + pluginName)) {
          return $.data(this, "plugin_" + pluginName, new PlzLike(this, options));
        }
      });
    };
  })(jQuery, window, document);

}).call(this);
