class HeaderView extends HeaderBaseView
  onClickSettings: ->
    chrome.runtime.openOptionsPage()

class KeyConfigView extends KeyConfigBaseView
  events: _.extend
    "click .run": "onClickRun"
    KeyConfigBaseView.prototype.events
  onChangeCtxmenu: ->
  onClickRun: ->
  tmplDesc: _.template """
    <button class="btn btn-outline-primary btn-sm run" title="Run command">Run<i class="icon-circle-arrow-right"></i></button>
  """

class KeyConfigSetView extends KeyConfigSetBaseView
  scrollingBottomBegin: 5
  # Collection Events
  onAddRender: (model) ->
    keyConfigView = new KeyConfigView model: model
    tbody = @$("tbody")[0]
    tbody.insertBefore keyConfigView.render(@model.get("kbdtype"), @model.get("lang")).el, null
    tbody.insertBefore $(@tmplBorder)[0], null

$ = jQuery
$ ->
  [keyCodes, scHelp, scHelpSect] = andy.getConfig()
  saveData = andy.local

  keys = keyCodes[saveData.config.kbdtype].keys;

  config = new Config saveData.config
  keyConfigSet = new KeyConfigSet()

  headerView = new HeaderView
    model: config
  config.trigger "change:lang"

  keyConfigSetView = new KeyConfigSetView
    model: config
    collection: keyConfigSet

  keyConfigSetView.render saveData.keyConfigSet

  windowOnResize()
