(function() {
  console.log("hello from a require'd coffee file (via assets/js/_helper.coffee)");

}).call(this);

(function() {
  var Comojo,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  require.config({
    paths: {
      jquery: '//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.0/jquery.min'
    }
  });

  require(['jquery'], function($) {
    return new Comojo({
      el: 'p'
    });
  });

  Comojo = (function() {
    function Comojo(options) {
      this._onFindPages = __bind(this._onFindPages, this);
      var _this = this;
      $.when.apply($, [$.getScript('//cdn.jsdelivr.net/parse/1.2.9/parse.js'), $.getScript('https://oauth.io//auth/download/latest/oauth.min.js')]).then(function() {
        var query;
        Parse.initialize("ZPbImnCfvuyidc6cJjI6dVSq5nOJJp5OWMiUQh6w", "8VImXPt6ggcOTkW11QYuxaogLb8QLEl9HzS4zwt3");
        _this.options = $.extend({
          el: 'p'
        }, options);
        _this._Page = Parse.Object.extend("Page");
        _this._Comment = Parse.Object.extend("Comment", {
          display: function() {
            return "<div class='comment'>" + (this.get('commenter')) + ": " + (this.get('body')) + "</div>";
          }
        });
        query = new Parse.Query(_this._Page);
        query.equalTo('url', window.location.href);
        return query.find({
          success: _this._onFindPages
        });
      });
    }

    Comojo.prototype._onFindPages = function(results) {
      var page,
        _this = this;
      page = results[0] || new this._Page();
      if (results.length) {
        this.comments = this._setupComments(page);
        this.comments.fetch({
          success: function(comments) {
            return comments.each(function(comment) {
              return _this._showComment(comment);
            });
          }
        });
      } else {
        page.save({
          url: window.location.href
        }).then(function(comments) {
          return _this.comments = _this._setupComments(page, comments);
        });
      }
      return this._bindClicks(page);
    };

    Comojo.prototype._setupComments = function(page) {
      var comments,
        _this = this;
      comments = new (this._Comments(page))();
      comments.on('add', function(comment) {
        return _this._showComment(comment);
      });
      return comments;
    };

    Comojo.prototype._Comments = function(page) {
      return Parse.Collection.extend({
        model: this._Comment,
        query: (new Parse.Query(this._Comment)).equalTo('page', page)
      });
    };

    Comojo.prototype._bindClicks = function(page) {
      var _this = this;
      return $(this.options.el).on('click', function(e) {
        return _this._ensureAuth(function() {
          var target;
          console.log(_this.user);
          $('body').append("<div class='comment-entry'><img src='" + _this.user.profile_image_url + "' /><h3>" + _this.user.screen_name + "</h3><label>Comment</label><textarea class='input-comment' /></div>");
          target = $(e.target);
          $(window).scrollTop(target.position().top);
          $('.comment-entry').css({
            position: 'absolute',
            width: target.outerWidth(true),
            height: $(document).height() - target.outerHeight(true),
            "z-index": 9999,
            top: target.position().top + target.outerHeight(true),
            left: target.position().left,
            "background-color": 'rgba(255,255,255,0.9)'
          });
          return $('.comment-entry .input-comment').on('keydown', function(e) {
            if (e.keyCode === 13) {
              e.preventDefault();
              _this.comments.create({
                page: page,
                elIndex: target.index(),
                body: $('.input-comment').val(),
                commenter: _this.user.screen_name
              });
              return $('.comment-entry').remove();
            }
          });
        });
      });
    };

    Comojo.prototype._ensureAuth = function(cb) {
      var t;
      t = this;
      if (t.user != null) {
        return cb();
      } else {
        OAuth.initialize('6bTbWgdrEePCI7uTh9We_BPmULs');
        return OAuth.popup('twitter', function(error, result) {
          return result.get('/1.1/account/settings.json').done(function(data) {
            return result.get({
              url: '/1.1/users/show.json',
              data: {
                screen_name: data.screen_name
              }
            }).done(function(data) {
              t.user = data;
              return cb();
            });
          });
        });
      }
    };

    Comojo.prototype._showComment = function(comment) {
      return $(this.options.el).eq(comment.get('elIndex') - 1).append(comment.display());
    };

    return Comojo;

  })();

}).call(this);
