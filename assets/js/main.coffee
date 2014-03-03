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
    @commentsView.remove() if @commentsView
    @commentsView = new (CommentsView(page, clicked))
      model: $.extend user,
        target: clicked
        comments:
          raw: @comments
          filtered: @comments.filter (f) ->
            f.get('elIndex') is clicked.index()
    $('body').append @commentsView.render().el
    $('.input-comment').focus()
    $(@options.el).css
      '-webkit-transition': 'margin-left 100ms'
      "margin-left": '-250px'
      "width": $(@options.el).width()

  _ensureAuth: (cb) ->
    if @user
      cb(@user)
    else
      Twitter.initialize @options.ouathio.key
      Twitter.getUser (u) =>
        @user = u
        cb(u)

View =
  entry:
    html: templates.comment_entry
    css: (target) ->

  comment:
    html: -> templates.comment({
        c: @get('commenter')
        body: @get('body')
      })


CommentsView = (page, clicked) -> Parse.View.extend
  className: 'comment-entry'

  template: templates.comment_entry

  events:
    'input .input-comment': 'autoGrow'
    'keydown .input-comment': 'onKeyPress'

  render: ->
    @$el.html(@template(@model))
    @$el.css
      position: 'absolute'
      width: 250
      top: clicked.position().top
      right: 0
      "z-index": 9999
    @

  autoGrow: (e) ->
    $t = $(e.target)
    $t.height ''
    $t.height $t.prop 'scrollHeight'

  onKeyPress: (e) ->
    if e.keyCode is 13
      e.preventDefault()
      @model.comments.raw.create
        page: page
        elIndex: clicked.index()
        body: $(e.target).val()
        commenter:
          name: @model.screen_name
          avatar: @model.profile_image_url
      @$('.comments').append @model.comments.raw.last().display()
      @$('.entry').remove()


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
