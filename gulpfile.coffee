{ src, dest, series } = require 'gulp'
coffee = require 'gulp-coffee'
babel  = require 'gulp-babel'
uglify = require('gulp-uglify-es').default
concat = require 'gulp-concat'
tap    = require 'gulp-tap'
zipfld = require 'zip-folder'
del    = require 'del'
gulpif = require 'gulp-if'

uglifyOrThru = ->
  if process.argv.includes 'dev'
    tap (file) -> console.log 'Skip uglify: ' + file.path
  else
    uglify()

zip = (done) ->
  if process.argv.includes 'dev'
    console.log 'Skip zipped'
    done()
  else
    manifest = JSON.parse require('fs').readFileSync('./dist/manifest.json')
    zipfld './dist', "./zipped/kbd.#{manifest.version}.zip", (err) ->
      done(err)

cp = ->
  src 'src/**/*.*'
    .pipe dest 'dist'

compile = (source, coffeeOp = {}) ->
  source
    .pipe coffee coffeeOp
    # .pipe babel()
    .pipe uglifyOrThru()
    .pipe dest 'dist'

compileOther = ->
  compile src ['coffee/*.coffee', '!coffee/options*', '!coffee/keyidentifiers.coffee']

compileMerged = ->
  compile src(['coffee/optionsExtends.coffee', 'coffee/options.coffee']).pipe \
    concat 'options.coffee'

compileBare = ->
  compile src(['coffee/keyidentifiers.coffee']),
  "bare": true

clean = (cb) -> del ['dist'], cb

build = series(
  clean
  compileBare
  compileMerged
  compileOther
  cp
  zip
)

exports.default = exports.dev = build
