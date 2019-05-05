{ src, dest, series } = require 'gulp'
coffee = require 'gulp-coffee'
uglify = require('gulp-uglify-es').default
concat = require 'gulp-concat'
tap    = require 'gulp-tap'
zipfld = require 'zip-folder'
del    = require 'del'

uglifyOrThru = ->
  if process.argv.includes 'prd'
    uglify()
  else
    tap (file) -> console.log 'Skip uglify: ' + file.path

zip = (done) ->
  if process.argv.includes 'prd'
    manifest = JSON.parse require('fs').readFileSync('./dist/manifest.json')
    zipfld './dist', "./zipped/kbd.#{manifest.version}.zip", (err) ->
      done(err)
  else
    console.log 'Skip zipped'
    done()

cp = ->
  src 'src/**/*.*'
    .pipe dest 'dist'

compile = (source, coffeeOp = {}) ->
  source
    .pipe coffee coffeeOp
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
  # compileBare
  compileMerged
  compileOther
  cp
  zip
)

exports.src = cp

exports.coffee = series(
  compileMerged
  compileOther
)

exports.default = exports.prd = build
