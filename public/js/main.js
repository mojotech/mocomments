(function() {


}).call(this);

(function() {
  var Comment, Comments, Scripts, Twitter, View,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  require.config({
    paths: {
      jquery: '//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.0/jquery.min'
    }
  });

  require(['jquery'], function($) {
    return new Comojo({
      el: 'p.commentable',
      env: 'dev'
    });
  });

  window.Comojo = (function() {
    function Comojo(options) {
      this._showComment = __bind(this._showComment, this);
      this._setupCommentEntry = __bind(this._setupCommentEntry, this);
      this._bindClicks = __bind(this._bindClicks, this);
      var _this = this;
      this.options = $.extend({
        el: 'p',
        url: window.location.href,
        ouathio: {
          key: '6bTbWgdrEePCI7uTh9We_BPmULs'
        },
        parse: {
          id: 'ZPbImnCfvuyidc6cJjI6dVSq5nOJJp5OWMiUQh6w',
          key: '8VImXPt6ggcOTkW11QYuxaogLb8QLEl9HzS4zwt3'
        }
      }, options);
      Scripts.fetch().then(function() {
        Parse.initialize(_this.options.parse.id, _this.options.parse.key);
        return _this._createPage(Parse.Object.extend("Page"), _this._bindClicks);
      });
    }

    Comojo.prototype._createPage = function(Page, cb) {
      var query,
        _this = this;
      query = new Parse.Query(Page);
      query.equalTo('url', this.options.url);
      return query.find().then(function(results) {
        var page;
        page = results[0] || new Page();
        if (results.length) {
          _this.comments = _this._setupComments(page);
          _this.comments.fetch();
        } else {
          page.save({
            url: _this.options.url
          }).then(function(comments) {
            return _this.comments = _this._setupComments(page, comments);
          });
        }
        return cb(page);
      });
    };

    Comojo.prototype._setupComments = function(page) {
      var comments;
      comments = new (Comments(page))();
      return comments.on('add', this._showComment);
    };

    Comojo.prototype._bindClicks = function(page) {
      var _this = this;
      return $(this.options.el).on('click', function(e) {
        var clicked;
        clicked = $(e.target);
        return _this._ensureAuth(function(user) {
          return _this._setupCommentEntry(user, clicked, page);
        });
      });
    };

    Comojo.prototype._setupCommentEntry = function(user, clicked, page) {
      var inputComment, onKeyPress,
        _this = this;
      $('.input-comment').off('keydown', onKeyPress);
      $('.comment-entry').remove();
      $('body').append(View.entry.html(user));
      $(this.options.el).css({
        '-webkit-transition': 'margin-left 100ms',
        "margin-left": '-250px',
        "width": $(this.options.el).width()
      });
      $('.comment-entry').css(View.entry.css(clicked));
      inputComment = $('.comment-entry .input-comment');
      inputComment.focus();
      this.comments.filter(function(f) {
        return f.get('elIndex') === clicked.index();
      }).forEach(this._showComment);
      onKeyPress = function(e) {
        if (e.keyCode === 13) {
          e.preventDefault();
          _this.comments.create({
            page: page,
            elIndex: clicked.index(),
            body: $(e.target).val(),
            commenter: {
              name: user.screen_name,
              avatar: user.profile_image_url
            }
          });
          inputComment.off('keydown', onKeyPress);
          return $('.entry').remove();
        }
      };
      return inputComment.on('keydown', onKeyPress);
    };

    Comojo.prototype._ensureAuth = function(cb) {
      var _this = this;
      if (this.user) {
        return cb(this.user);
      } else {
        Twitter.initialize(this.options.ouathio.key);
        return Twitter.getUser(function(u) {
          _this.user = u;
          return cb(u);
        });
      }
    };

    Comojo.prototype._showComment = function(comment) {
      return $('.comment-entry .comments').append(comment.display());
    };

    return Comojo;

  })();

  View = {
    entry: {
      html: function(user) {
        return "<div class='comment-entry'>         <img class='entry' src='" + user.profile_image_url + "' />         <textarea class='input-comment entry' placeholder='Sassy fucking comment...'           style = 'border: none; border-bottom: 1px solid grey; outline: none; re'          />         <div class='comments'></div>      </div>";
      },
      css: function(target) {
        return {
          position: 'absolute',
          width: 250,
          top: target.position().top,
          right: 0,
          "z-index": 9999,
          "background-color": 'rgba(255,255,255,0.9)'
        };
      }
    },
    comment: {
      html: function() {
        var c;
        c = this.get('commenter');
        return "<div class='comment'>         <img src='" + c.avatar + "'/>         <p>" + c.name + ": " + (this.get('body')) + "</p>      </div>";
      }
    }
  };

  Scripts = {
    resources: ['//cdn.jsdelivr.net/parse/1.2.9/parse.js', 'https://oauth.io//auth/download/latest/oauth.min.js'],
    fetch: function() {
      return $.when.apply($, this.resources.map($.getScript));
    }
  };

  Twitter = {
    initialize: function(key) {
      return OAuth.initialize(key);
    },
    getUser: function(cb) {
      return cb({
        screen_name: 'aesny',
        profile_image_url: 'http://pbs.twimg.com/profile_images/1628839301/309180_1980408664990_1086360060_31761796_2384751_n_normal.jpg'
      });
    }
  };

  Comments = function(page) {
    var comment;
    comment = Comment();
    return Parse.Collection.extend({
      model: comment,
      query: (new Parse.Query(comment)).equalTo('page', page)
    });
  };

  Comment = function() {
    return Parse.Object.extend("Comment", {
      display: function() {
        return View.comment.html.apply(this);
      }
    });
  };

}).call(this);
