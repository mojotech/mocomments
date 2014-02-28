(function() {
  console.log("hello from a require'd coffee file (via assets/js/_helper.coffee)");

}).call(this);

(function() {
  var showComment;

  require.config({
    paths: {
      jquery: '//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.0/jquery.min',
      parse: 'http://www.parsecdn.com/js/parse-1.2.17.min'
    }
  });

  require(['jquery', 'parse'], function($) {
    var Comment, Commojo, Page;
    Parse.initialize("ZPbImnCfvuyidc6cJjI6dVSq5nOJJp5OWMiUQh6w", "8VImXPt6ggcOTkW11QYuxaogLb8QLEl9HzS4zwt3");
    Page = Parse.Object.extend("Page");
    Comment = Parse.Object.extend("Comment", {
      initialize: function(attrs, options) {
        return console.log('initialize');
      },
      display: function() {
        return "<div class='comment'>" + (this.get('commenter')) + ": " + (this.get('body')) + "</div>";
      }
    });
    Commojo = function(page) {
      return Parse.Collection.extend({
        model: Comment,
        query: (new Parse.Query(Comment)).equalTo('page', page),
        addComment: function(index, commentBody, name) {
          var comment;
          comment = {
            page: page,
            elIndex: index,
            body: commentBody,
            commenter: name
          };
          return this.create(comment);
        }
      });
    };
    $('p').on('click', function() {
      var comment, name;
      name = prompt('Name');
      comment = prompt('Enter comment');
      return commojo.addComment($(this).index(), comment, name);
    });
    return $(function() {
      var query;
      query = new Parse.Query(Page);
      query.equalTo('url', window.location.href);
      return query.find({
        success: function(results) {
          if (results.length) {
            window.page = results[0];
            window.commojo = new (Commojo(page))();
            return commojo.fetch({
              success: function(comments) {
                console.log(comments);
                comments.each(showComment);
                return commojo.on('add', showComment);
              }
            });
          } else {
            window.page = new Page();
            return page.save({
              url: window.location.href
            }).then(function() {
              return window.commojo = new (Commojo(page))();
            });
          }
        }
      });
    });
  });

  showComment = function(comment) {
    return $('p').eq(comment.get('elIndex') - 1).append(comment.display());
  };

}).call(this);
