(function(){
  window.templates = window.templates || {};
  function attrs(obj, escaped){
  var buf = []
    , terse = obj.terse;

  delete obj.terse;
  var keys = Object.keys(obj)
    , len = keys.length;

  if (len) {
    buf.push('');
    for (var i = 0; i < len; ++i) {
      var key = keys[i]
        , val = obj[key];

      if ('boolean' == typeof val || null == val) {
        if (val) {
          terse
            ? buf.push(key)
            : buf.push(key + '="' + key + '"');
        }
      } else if (0 == key.indexOf('data') && 'string' != typeof val) {
        buf.push(key + "='" + JSON.stringify(val) + "'");
      } else if ('class' == key) {
        if (escaped && escaped[key]){
          if (val = escape(joinClasses(val))) {
            buf.push(key + '="' + val + '"');
          }
        } else {
          if (val = joinClasses(val)) {
            buf.push(key + '="' + val + '"');
          }
        }
      } else if (escaped && escaped[key]) {
        buf.push(key + '="' + escape(val) + '"');
      } else {
        buf.push(key + '="' + val + '"');
      }
    }
  }

  return buf.join(' ');
}
function escape(html){
  return String(html)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
function nulls(val) { return val != null && val !== '' }
function joinClasses(val) { return Array.isArray(val) ? val.map(joinClasses).filter(nulls).join(' ') : val; }
var jade = {
  attrs: attrs,
  escape: escape 
};templates['comment'] = function anonymous(locals) {
var buf = [];
var locals_ = (locals || {}),c = locals_.c,body = locals_.body;buf.push("<div class=\"mc-comment\"><div class=\"mc-comment-info\"><img" + (jade.attrs({ 'src':("" + (c.avatar) + ""), "class": [('mc-comment-photo')] }, {"src":true})) + "/><h4 class=\"mc-comment-author-name\">" + (jade.escape((jade.interp = c.name) == null ? '' : jade.interp)) + "</h4></div><p class=\"mc-comment-body\">" + (jade.escape((jade.interp = body) == null ? '' : jade.interp)) + "</p></div>");;return buf.join("");
};
templates['comment_entry'] = function anonymous(locals) {
var buf = [];
var locals_ = (locals || {}),profile_image_url = locals_.profile_image_url,comments = locals_.comments;buf.push("<img" + (jade.attrs({ 'src':(profile_image_url), "class": [('mc-entry'),('mc-comment-photo')] }, {"src":true})) + "/><textarea placeholder=\"Leave a note...\" class=\"mc-input-comment mc-entry\"></textarea><a href=\"#save\" class=\"mc-save-link entry mc-comment-link\">Save</a><a href=\"\" class=\"mc-close-link mc-comment-link\">Close</a><div class=\"mc-comments\">");
// iterate comments.filtered
;(function(){
  var $$obj = comments.filtered;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var comment = $$obj[$index];

buf.push(null == (jade.interp = comment.display()) ? "" : jade.interp);
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var comment = $$obj[$index];

buf.push(null == (jade.interp = comment.display()) ? "" : jade.interp);
    }

  }
}).call(this);

buf.push("</div>");;return buf.join("");
};
templates['indicator'] = function anonymous(locals) {
var buf = [];
var locals_ = (locals || {}),count = locals_.count;buf.push("<div" + (jade.attrs({ "class": [('mc-indicator'),(count != "+" ? "mc-faded" : "")] }, {"class":true})) + ">" + (jade.escape(null == (jade.interp = count) ? "" : jade.interp)) + "</div>");;return buf.join("");
};
})();