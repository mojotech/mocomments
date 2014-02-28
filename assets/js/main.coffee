#= require "_helper"

# requirejs makes life a lot easier when dealing with more than one
# javascript file and any sort of dependencies, and loads faster.

# for more info on require config, see http://requirejs.org/docs/api.html#config
require.config
  paths:
    jquery: '//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.0/jquery.min'
require ['jquery'], ($) ->
  new Comojo()

class Comojo
    constructor: (options) ->
      $.getScript '//cdn.jsdelivr.net/parse/1.2.9/parse.js', =>
        Parse.initialize "ZPbImnCfvuyidc6cJjI6dVSq5nOJJp5OWMiUQh6w", "8VImXPt6ggcOTkW11QYuxaogLb8QLEl9HzS4zwt3"

        @options = $.extend
          el: 'p'
        , options

        @_Page = Parse.Object.extend "Page"

        @_Comment = Parse.Object.extend "Comment",
          display: ->
            "<div class='comment'>#{ @get('commenter') }: #{ @get('body') }</div>"

        query = new Parse.Query(@_Page)
        query.equalTo('url', window.location.href)
        query.find
          success: @_onFindPages

    _onFindPages: (results) =>
      page = results[0] or new @_Page()
      if results.length
        @comments = @_setupComments(page)
        @comments.fetch
          success: (comments) =>
            comments.each (comment) => @_showComment(comment)
      else
        page.save(url: window.location.href).then (comments) ->
          @_setupComments(page, comments)
      @_bindClicks(page)

    _setupComments: (page) =>
      comments = new (@_Comments(page))()
      comments.on 'add', (comment) => @_showComment(comment)
      comments

    _Comments: (page) ->
      Parse.Collection.extend
        model: @_Comment
        query: (new Parse.Query(@_Comment)).equalTo('page', page)

    _bindClicks: (page) ->
      $(@options.el).on 'click', (e) =>
        name = prompt('Name')
        comment = prompt('Enter comment')
        @comments.create
          page: page
          elIndex: $(e.target).index()
          body: comment
          commenter: name

    _showComment: (comment) ->
      $(@options.el).eq(comment.get('elIndex') - 1).append comment.display()
