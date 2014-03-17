var gulp    = require('gulp');
var concat  = require('gulp-concat');
var exec    = require('child_process').exec;
var uglify  = require('gulp-uglify');

gulp.task('default', ["compile"], function() {
  gulp.src(["public/js/templates.js", "public/js/main.js"])
    .pipe(concat("build.js"))
    .pipe(uglify({outSourceMap: false}))
    .pipe(gulp.dest('lib'));
});

gulp.task('compile', function(cb) {
  exec("./node_modules/roots/bin/roots compile", function() {
    cb();
  });
});
