#= require "_helper"

# requirejs makes life a lot easier when dealing with more than one
# javascript file and any sort of dependencies, and loads faster.

# for more info on require config, see http://requirejs.org/docs/api.html#config
require.config
  paths:
    jquery: '//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.0/jquery.min'
require ['jquery'], ($) ->
  new Comojo(el: 'p')

class Comojo
  constructor: (options) ->
    $.when.apply($, [$.getScript('//cdn.jsdelivr.net/parse/1.2.9/parse.js'), $.getScript('https://oauth.io//auth/download/latest/oauth.min.js')])
    .then =>
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
      page.save(url: window.location.href).then (comments) =>
        @comments = @_setupComments(page, comments)
    @_bindClicks(page)

  _setupComments: (page) ->
    comments = new (@_Comments(page))()
    comments.on 'add', (comment) => @_showComment(comment)
    comments

  _Comments: (page) ->
    Parse.Collection.extend
      model: @_Comment
      query: (new Parse.Query(@_Comment)).equalTo('page', page)

  _bindClicks: (page) ->
    $(@options.el).on 'click', (e) =>
      @_ensureAuth =>
        console.log @user
        $('body').append "<div class='comment-entry'><img src='#{@user.profile_image_url}' /><h3>#{@user.screen_name}</h3><label>Comment</label><textarea class='input-comment' /></div>"
        target = $(e.target)
        $(window).scrollTop target.position().top
        $('.comment-entry').css
          position: 'absolute'
          width: target.outerWidth(true)
          height: $(document).height() - target.outerHeight(true)
          "z-index": 9999
          top: target.position().top + target.outerHeight(true)
          left: target.position().left
          "background-color": 'rgba(255,255,255,0.9)'
        $('.comment-entry .input-comment').on 'keydown', (e) =>
          if e.keyCode is 13
            e.preventDefault()
            @comments.create
              page: page
              elIndex: target.index()
              body: $('.input-comment').val()
              commenter: @user.screen_name
            $('.comment-entry').remove()

  _ensureAuth: (cb) ->
    t = this
    if t.user?
      cb()
    else
      OAuth.initialize('6bTbWgdrEePCI7uTh9We_BPmULs')
      OAuth.popup 'twitter', (error, result) ->
        result.get('/1.1/account/settings.json').done (data) ->
          result.get(
            url: '/1.1/users/show.json',
            data:
              screen_name: data.screen_name
            ).done (data) ->
              t.user = data
              cb()


  _showComment: (comment) ->
    $(@options.el).eq(comment.get('elIndex') - 1).append comment.display()
