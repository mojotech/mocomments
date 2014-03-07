#= require "comojo"

require.config
  paths:
    jquery: '//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.0/jquery.min'

require ['jquery'], ($) ->
  new Comojo
    commentable: 'p.commentable'
    container: '.contain'

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
        @comments = new (Comments page)()
        @comments.fetch().then @_addIndicators
      else
        page.save(url: @options.url).then =>
          @comments = new (Comments page)()
      cb page

  _addIndicators: (comments) =>
    countsByEl = @_countsByEl(comments)
    @$commentable.each (i, el) ->
      $(el).append templates.indicator(count: (countsByEl[i] or '+'))

  _countsByEl: (comments) ->
    commentsByGroup = comments.groupBy((comment) -> comment.get('elIndex'))
    @_.object @_.keys(commentsByGroup), @_.map (commentsByGroup), (v, k) ->
      v.length

  _bindClicks: (page) =>
    @$commentable.on 'click', '.mc-indicator', (e) =>
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
    $('.mc-input-comment').focus()
    right = if r = @$container.css('right') is 'auto' then 0 else parseInt(r, 10)
    @$container.css
      'position': 'relative'
      'left': 'auto'
      'right': right
    @$container.css
      '-webkit-transition': 'right 150ms'
      "right": Math.max(250 - ($('body').width() - @$container[0].getBoundingClientRect().right), right)
      "width": @$container.width()

  _ensureAuth: (cb) ->
    if @user
      cb(@user)
    else
      Twitter.initialize @options.ouathio.key
      Twitter.getUser (u) =>
        @user = u
        cb(u)

CommentsView = (page, clicked, $container, $commentable) -> Parse.View.extend
  className: 'mc-comment-entry'

  template: templates.comment_entry

  events:
    'input .mc-input-comment': 'autoGrow'
    'keydown .mc-input-comment': 'onKeyPress'
    'click .mc-save-link': 'save'
    'click .mc-close-link': 'close'

  render: ->
    @$el.html(@template(@model))
    @$el.css
      position: 'absolute'
      width: 250
      top: clicked.offset().top
      right: 0
      "z-index": 9999
    Parse._.defer => $('body').on 'click.mc-close-comment-entry', (e) => @close e
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
    e.preventDefault() if e
    if $(e.target).hasClass('mc-indicator') or $(e.target).hasClass('mc-comment-entry') or ($('.mc-comment-entry').has(e.target).length and not $(e.target).hasClass('mc-close-link'))
      return false
    $('body').off 'click.mc-close-comment-entry'
    $container.attr 'style', ' '
    @remove()

  save: (e) ->
    if e
      e.stopImmediatePropagation()
      e.preventDefault()
    return unless body = @$('.mc-input-comment').val()
    @model.comments.raw.create
      page: page
      elIndex: $commentable.index(clicked)
      body: body
      commenter:
        name: @model.screen_name
        avatar: @model.profile_image_url
    @$('.mc-comments').append @model.comments.raw.last().display()
    $(clicked).find('.mc-indicator').text(@$('.mc-comments .mc-comment').length)
    @$('.mc-entry').remove()


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
