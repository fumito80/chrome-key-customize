class HeaderView extends HeaderBaseView
  onClickSettings: ->
    chrome.runtime.openOptionsPage()

class KeyConfigView extends KeyConfigBaseView

class KeyConfigSetView extends KeyConfigSetBaseView
  scrollingBottomBegin: 5
  # Collection Events
  onAddRender: (model) ->
    keyConfigView = new KeyConfigView(model: model)
    tbody = @$("tbody")[0]
    if /^C/.test(model.id) && lastFocused
      divAddNew = lastFocused.nextSibling || null
    tbody.insertBefore keyConfigView.render(@model.get("kbdtype"), @model.get("lang")).el, divAddNew
    tbody.insertBefore $(@tmplBorder)[0], divAddNew

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

  if ($(".fixed-table-container-inner")[0].scrollHeight - window.innerHeight - 60) > 5
    $("footer").addClass("scrolling")
    $(".scrollEnd").show()
