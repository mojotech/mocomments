#= require "_helper"

# requirejs makes life a lot easier when dealing with more than one
# javascript file and any sort of dependencies, and loads faster.

# for more info on require config, see http://requirejs.org/docs/api.html#config
require.config
  paths:
    jquery: '//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.0/jquery.min'
    parse: 'http://www.parsecdn.com/js/parse-1.2.17.min'

require ['jquery', 'parse'], ($) ->
  Parse.initialize("ZPbImnCfvuyidc6cJjI6dVSq5nOJJp5OWMiUQh6w", "8VImXPt6ggcOTkW11QYuxaogLb8QLEl9HzS4zwt3")

  Page = Parse.Object.extend "Page"


  Comment = Parse.Object.extend "Comment",
    {
      initialize: (attrs, options) ->
        console.log 'initialize'
      display: ->
        "<div class='comment'>#{ @get('commenter') }: #{ @get('body') }</div>"
    }

  Commojo = (page) ->
    Parse.Collection.extend
      model: Comment
      query: (new Parse.Query(Comment)).equalTo('page', page)
      addComment: (index, commentBody, name) ->
        comment =
          page: page
          elIndex: index
          body: commentBody
          commenter: name
        @create(comment)

  $('p').on 'click', ->
    name = prompt('Name')
    comment = prompt('Enter comment')
    commojo.addComment $(@).index(), comment, name

  $ ->
    query = new Parse.Query(Page)
    query.equalTo('url', window.location.href)
    query.find
      success: (results) ->
        if results.length
          window.page = results[0]
          window.commojo = new (Commojo(page))()
          commojo.fetch
            success: (comments) ->
              console.log comments
              comments.each showComment
              commojo.on 'add', showComment
        else
          window.page = new Page()
          page.save(url: window.location.href).then ->
            window.commojo = new (Commojo(page))()


showComment = (comment) ->
  $('p').eq(comment.get('elIndex') - 1).append comment.display()
