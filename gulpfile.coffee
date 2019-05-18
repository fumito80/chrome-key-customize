{ src, dest, series } = require 'gulp'
coffee = require 'gulp-coffee'
uglify = require('gulp-uglify-es').default
concat = require 'gulp-concat'
tap    = require 'gulp-tap'
zipfld = require 'zip-folder'
del    = require 'del'
rename = require 'gulp-rename'

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
  compile src [
    'coffee/*.coffee'
    '!coffee/functions*'
    '!coffee/options*'
    '!coffee/background.coffee'
    '!coffee/popup.coffee'
  ]

compileOptions = ->
  compile src([
    'coffee/functions.coffee'
    'coffee/optionsClasses.coffee'
    'coffee/optionsExtends.coffee'
    'coffee/options.coffee'
  ]).pipe \
    concat 'options.coffee'

compileBackground = ->
  compile src([
    'coffee/functions.coffee'
    'coffee/background.coffee'
  ]).pipe \
    concat 'background.coffee'

compilePopup = ->
  compile src([
    'coffee/functions.coffee'
    'coffee/optionsClasses.coffee'
    'coffee/popup.coffee'
  ]).pipe \
    concat 'popup.coffee'

clean = (cb) -> del ['dist'], cb

build = series(
  clean
  compileOptions
  compileBackground
  compilePopup
  compileOther
  cp
  zip
)

exports.src = cp

exports.coffee = series(
  compileOptions
  compileBackground
  compilePopup
  compileOther
)

exports.default = exports.prd = build

# nmh
nmh_clean = (cb) ->
  console.log process.env.LOCALAPPDATA + '/Shortcutware'
  del [process.env.LOCALAPPDATA + '/Shortcutware/Flexkbd64.*'], force: true, cb

nmh_cp_dll = ->
  src 'nmhost/Flexkbd64_dll.dll'
    .pipe rename 'Flexkbd64.dll'
    .pipe dest process.env.LOCALAPPDATA + '/Shortcutware'

nmh_cp_exe = ->
  src 'nmhost/Flexkbd64.exe'
    .pipe dest process.env.LOCALAPPDATA + '/Shortcutware'

exports.nmh = series(
  nmh_clean
  nmh_cp_dll
  nmh_cp_exe
)
