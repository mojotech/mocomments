_ = _ or null
commentsView = {}

class window.Comojo
  resources: ['//cdn.jsdelivr.net/parse/1.2.9/parse.js', 'https://oauth.io//auth/download/latest/oauth.min.js' ]
  constructor: (options) ->
    @options = $.extend
      el: 'p'
      width: 250
      url: window.location.href
      ouathio:
        key: '6bTbWgdrEePCI7uTh9We_BPmULs'
      parse:
        id: 'ZPbImnCfvuyidc6cJjI6dVSq5nOJJp5OWMiUQh6w'
        key: '8VImXPt6ggcOTkW11QYuxaogLb8QLEl9HzS4zwt3'
    , options

    $container   = $(@options.container)
    $commentable = $container.find(@options.commentable)

    $commentable.addClass 'mc-indicated'

    getScripts(@resources).then =>
      Parse.initialize @options.parse.id, @options.parse.key
      _ ?= Parse._
      createPage(Parse.Object.extend("Page"), @options)
        .then(setupComments(@options.url))
        .then addIndicators @options,
          $commentable: $commentable
          $container: $container

createPage = (Page, options) ->
  deferrable (d) ->
    (new Parse.Query(Page))
      .equalTo('url', options.url)
      .find()
      .then (results) ->
        d.resolve results[0] or new Page(), !!results.length

addIndicators = (options, els) ->
  (comments, page) ->
    counts = countsByProp comments, 'elIndex'
    els.$commentable.each (i, el) ->
      $(el).append templates.indicator text: indicatorText(counts[i])
    els.$commentable.on 'click', '.mc-indicator', (e) =>
      index = els.$commentable.index($target(e).parent())
      onIndicatorClick e, page, comments, index, els, options

onIndicatorClick = (e, page, comments, index, els, options) ->
  getUser options, (user) ->
    commentsView.remove?()
    commentsView = setupCommentEntryView(user, $(e.target).parent(), page, comments, index, els, options)
    $('body').append commentsView.render().el
    $('.mc-input-comment').focus()
    moveContainer(els.$container, options.width)

setupCommentEntryView = (user, clicked, page, comments, index, els, options) ->
  new (CommentsView(page, clicked, els, options))
    model: $.extend user,
      target: clicked
      comments:
        raw: comments
        filtered: filterByIndex comments, index

setupComments = (url) ->
  (page, existingPage) ->
    deferrable (d) ->
      if existingPage
        getComments(page).then resolveComments(d)
      else
        page.save(url: url).then ->
          # ideally don't call getComments as we know it will be empty
          getComments(page).then resolveComments(d)

resolveComments = (d) ->
  (comments, page) ->
    d.resolve comments, page

getComments = (page) ->
  deferrable (d) ->
    (new (Comments page)())
      .fetch()
      .then (comments) ->
        d.resolve comments, page

moveContainer = ($container, distance) ->
  right = if r = $container.css('right') is 'auto' then 0 else parseInt(r, 10)
  $container.css
    'position': 'relative'
    'left': 'auto'
    'right': right
  $container.css
    '-webkit-transition': 'right 150ms'
    "right": Math.max(distance - ($('body').width() - $container[0].getBoundingClientRect().right), right)
    "width": $container.width()

indicatorText = (count) ->
  count or '+'

countsByProp = (collection, prop) ->
  byProp = collection.groupBy (item) -> item.get(prop)
  _.object _.keys(byProp), _.map (byProp), (v, k) ->
    v.length

CommentsView = (page, clicked, els, options) -> Parse.View.extend
  className: 'mc-comment-entry'

  template: templates.comment_entry

  events:
    'input .mc-input-comment': 'autoGrow'
    'keydown .mc-input-comment': 'onKeyPress'
    'click .mc-save-link': '_attemptSave'
    'click .mc-close-link': 'close'

  render: ->
    @$el
      .html(@template(@model))
      .css commentsViewStyle(clicked, options)

    _.defer =>
      $('body').on 'click.mc-close-comment-entry', @close.bind(this)
    @

  autoGrow: autoGrow

  onKeyPress: (e) ->
    onEnter e, @_attemptSave.bind(this)

  close: (e) ->
    preventDefault e
    return if shouldNotTriggerClose $target(e)
    $('body').off 'click.mc-close-comment-entry'
    $container.attr 'style', ' '
    @remove()

  _attemptSave: (e) ->
    hardStop(e) if e

    return unless val(@$('.mc-input-comment'))

    body = val(@$('.mc-input-comment'))
    index = els.$commentable.index(clicked)
    comments = @model.comments.raw

    displayNewComment saveComment(newComment(body, index, @model, page), comments),
      $comments: @$('.mc-comments')
      $indicator: $(clicked).find '.mc-indicator'
      $entry: @$('.mc-entry')
      count: _.size filterByIndex comments, index

shouldNotTriggerClose = (target) ->
  target.hasClass('mc-indicator') or target.hasClass('mc-comment-entry') or
  ($('.mc-comment-entry').has(_.first(target)).length and not target.hasClass('mc-close-link'))

commentsViewStyle = (clicked, options) ->
  position: 'absolute'
  width: options.width
  top: clicked.offset().top
  right: 0
  "z-index": 9999

val = (el) -> el.val()

displayNewComment = (comment, opts) ->
  opts.$comments.append comment.display()
  opts.$indicator.text opts.count
  opts.$entry.remove()

stopImmediatePropagation = (e) ->
  e.stopImmediatePropagation()

hardStop = (e) ->
  stopImmediatePropagation(e)
  preventDefault(e)

newComment = (body, index, model, page) ->
  page: page
  elIndex: index
  body: body
  commenter:
    name: model.screen_name
    avatar: model.profile_image_url

saveComment = (comment, comments) ->
  comments.create comment
  comments.last()

preventDefault = (e) ->
  e.preventDefault()

keyCode = (e) ->
  e.keyCode

onEnter = (e, cb) ->
  if isEnter(keyCode(e))
    cb()

isEnter = (keyCode) ->
  keyCode is 13

$target = (e) ->
  $(e.target)

autoGrow = (e) ->
  $t = $target(e)
  $t.height ''
  $t.height $t.prop 'scrollHeight'

filterByIndex = (collection, index) ->
  filter(collection)(byIndex(index))

filter = (collection) ->
  (action) ->
    collection.filter action

byProperty = (property, value) ->
  (m) ->
    m.get(property) is value

byIndex = (index) ->
  byProperty('elIndex', index)

deferrable = (fn) ->
  d = $.Deferred()
  fn d
  d.promise()

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

getScripts = (scripts) ->
  $.when.apply $, scripts.map $.getScript

getUser = (options, cb) ->
  if u = localStorage.getItem('comojoUser')
    return cb JSON.parse u
  else
    OAuth.initialize options.ouathio.key
    OAuth.popup 'twitter', (error, result) ->
      result.get('/1.1/account/settings.json').done (data) ->
        result.get
          url: '/1.1/users/show.json'
          data:
            screen_name: data.screen_name
          success: (user) ->
            localStorage.setItem 'comojoUser', JSON.stringify(user)
            cb(user)
