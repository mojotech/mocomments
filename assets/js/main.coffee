#= require "comojo"

require.config
  paths:
    jquery: '//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.0/jquery.min'

require ['jquery'], ($) ->
  new Comojo
    commentable: 'p.commentable'
    container: '.contain'
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

    @$container = $(@options.container)
    @$commentable = @$container.find(@options.commentable)

    @$commentable.addClass 'mc-indicated'
    Scripts.fetch().then =>
      Parse.initialize @options.parse.id, @options.parse.key
      @_ = Parse._
      @_createPage Parse.Object.extend("Page"), @_bindClicks

  _createPage: (Page, cb) ->
    query = new Parse.Query(Page)
    query.equalTo 'url', @options.url
    query.find().then (results) =>
      page = results[0] or new Page()
      if results.length
        @comments = @_setupComments page
        @comments.fetch().then @_addIndicators
      else
        page.save(url: @options.url).then (comments) =>
          @comments = @_setupComments page, comments
      cb page

  _addIndicators: (comments) =>
    countsByEl = @_countsByEl(comments)
    @$commentable.each (i, el) ->
      $(el).append templates.indicator(count: (countsByEl[i] or '+'))

  _countsByEl: (comments) ->
    commentsByGroup = comments.groupBy((comment) -> comment.get('elIndex'))
    @_.object @_.keys(commentsByGroup), @_.map (commentsByGroup), (v, k) ->
      v.length

  _setupComments: (page) ->
    comments = new (Comments page)()
    comments.on 'add', @_showComment

  _bindClicks: (page) =>
    @$commentable.on 'click', '.indicator', (e) =>
      clicked = $(e.target).parent()
      @_ensureAuth (user) =>
        @_setupCommentEntry user, clicked, page

  _setupCommentEntry: (user, clicked, page) =>
    @commentsView.remove() if @commentsView
    @commentsView = new (CommentsView(page, clicked, @$container, @$commentable))
      model: $.extend user,
        target: clicked
        comments:
          raw: @comments
          filtered: @comments.filter (f) =>
            f.get('elIndex') is @$commentable.index(clicked)
    $('body').append @commentsView.render().el
    $('.input-comment').focus()
    @$container.css
      'position': 'relative'
      'left': 0
    @$container.css
      '-webkit-transition': 'left 150ms'
      "left": "-150px"
      "width": @$commentable.width()

  _ensureAuth: (cb) ->
    if @user
      cb(@user)
    else
      Twitter.initialize @options.ouathio.key
      Twitter.getUser (u) =>
        @user = u
        cb(u)

CommentsView = (page, clicked, $container, $commentable) -> Parse.View.extend
  className: 'comment-entry'

  template: templates.comment_entry

  events:
    'input .input-comment': 'autoGrow'
    'keydown .input-comment': 'onKeyPress'
    'click .save-link': 'save'
    'click .close-link': 'close'

  render: ->
    @$el.html(@template(@model))
    @$el.css
      position: 'absolute'
      width: 250
      top: clicked.offset().top
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
      @save()

  close: (e) ->
    e.preventDefault()
    $container.attr 'style', ' '
    @remove()

  save: (e) ->
    e.preventDefault() if e
    @model.comments.raw.create
      page: page
      elIndex: $commentable.index(clicked)
      body: @$('.input-comment').val()
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
    display: ->
      templates.comment
        c: @get('commenter')
        body: @get('body')
