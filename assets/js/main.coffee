#= require "comojo"

require.config
  paths:
    jquery: '//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.0/jquery.min'
require ['jquery'], ($) ->
  new Comojo
    el: 'p.commentable'
    env: 'dev'

class window.Comojo
  constructor: (options) ->
    @options = $.extend
      el: 'p'
      url: window.location.href
      ouathio:
        key: '6bTbWgdrEePCI7uTh9We_BPmULs'
      parse:
        id: 'ZPbImnCfvuyidc6cJjI6dVSq5nOJJp5OWMiUQh6w'
        key: '8VImXPt6ggcOTkW11QYuxaogLb8QLEl9HzS4zwt3'
    , options

    Scripts.fetch().then =>
      Parse.initialize @options.parse.id, @options.parse.key
      @_createPage Parse.Object.extend("Page"), @_bindClicks

  _createPage: (Page, cb) ->
    query = new Parse.Query(Page)
    query.equalTo 'url', @options.url
    query.find().then (results) =>
      page = results[0] or new Page()
      if results.length
        @comments = @_setupComments page
        @comments.fetch()
      else
        page.save(url: @options.url).then (comments) =>
          @comments = @_setupComments page, comments
      cb page

  _setupComments: (page) ->
    comments = new (Comments page)()
    comments.on 'add', @_showComment

  _bindClicks: (page) =>
    $(@options.el).on 'click', (e) =>
      clicked = $ e.target
      @_ensureAuth (user) =>
        @_setupCommentEntry user, clicked, page

  _setupCommentEntry: (user, clicked, page) =>
    $('.input-comment').off 'keydown', onKeyPress
    $('.comment-entry').remove()
    $('body').append View.entry.html(user)
    $(@options.el).css
      '-webkit-transition': 'margin-left 100ms'
      "margin-left": '-250px'
      "width": $(@options.el).width()
    $('.comment-entry').css View.entry.css(clicked)
    inputComment = $ '.comment-entry .input-comment'
    inputComment.focus()
    @comments
      .filter (f) ->
        f.get('elIndex') is clicked.index()
      .forEach @_showComment
    onKeyPress = (e) =>
      if e.keyCode is 13
        e.preventDefault()
        @comments.create
          page: page
          elIndex: clicked.index()
          body: $(e.target).val()
          commenter:
            name: user.screen_name
            avatar: user.profile_image_url
        inputComment.off 'keydown', onKeyPress
        $('.entry').remove()
        # $(@options.el).attr 'style', ''
    inputComment.on 'keydown', onKeyPress

  _ensureAuth: (cb) ->
    if @user
      cb(@user)
    else
      Twitter.initialize @options.ouathio.key
      Twitter.getUser (u) =>
        @user = u
        cb(u)

  _showComment: (comment) =>
    $('.comment-entry .comments').append comment.display()

View =
  entry:
    html: (user) ->
      "<div class='comment-entry'> \
        <img class='entry' src='#{user.profile_image_url}' style = 'border-radius: 50%;'/> \
        <textarea class='input-comment entry' placeholder='Sassy fucking comment...' \
          style = 'border: none; border-bottom: 1px solid grey; outline: none; re'
          /> \
        <div class='comments'></div>
      </div>"
    css: (target) ->
      position: 'absolute'
      width: 250
      top: target.position().top
      right: 0
      "z-index": 9999
      "background-color": 'rgba(255,255,255,0.9)'
  comment:
    html: ->
      c = @get('commenter')
      "<div class='comment'> \
        <img src='#{ c.avatar }' style='border-radius: 50%' /> \
        <p>#{ c.name }: #{ @get('body') }</p>
      </div>"

Scripts =
  resources: ['//cdn.jsdelivr.net/parse/1.2.9/parse.js', 'https://oauth.io//auth/download/latest/oauth.min.js' ]
  fetch: ->
    $.when.apply $, @resources.map $.getScript

Twitter =
  initialize: (key) ->
    OAuth.initialize key
  getUser: (cb) ->
    if u = localStorage.getItem('comojoUser')
      return cb JSON.parse u
    OAuth.popup 'twitter', (error, result) ->
      result.get('/1.1/account/settings.json').done (data) ->
        result.get
          url: '/1.1/users/show.json',
          data:
            screen_name: data.screen_name
          success: (user) ->
            localStorage.setItem 'comojoUser', JSON.stringify(user)
            cb(user)

Comments = (page) ->
  comment = Comment()
  Parse.Collection.extend
    model: comment
    query: (new Parse.Query comment).equalTo 'page', page

Comment = ->
  Parse.Object.extend "Comment",
    display: -> View.comment.html.apply(this)
