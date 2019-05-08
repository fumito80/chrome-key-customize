keyCodes = {}
scHelp = null
scHelpSect = null
keys = null
router = null
keyConfigSetView = null
ctxMenuManagerView = null

PopupBaseView = Backbone.View.extend
  initialize: (options) ->
    router.on "showPopup", @onShowPopup, @
    router.on "hidePopup", @onHidePopup, @
    router.listenTo @, "showPopup", router.onNavigatePopup
    router.listenTo @, "hidePopup", router.onNavigateRootPage
  events:
    "submit form"  : "onSubmitForm"
    "click .cancel": "onClickCancel"
  render: -> # Virtual
  onSubmitForm: -> # Virtual
  onShowPopup: (name, model) ->
    unless name is @name
      @$el.hide()
      return false
    if model
      if @optionsName
        @options = model.get @optionsName
      order = ""
      if /^C/.test modelId = model.get("new")
        shortcut = decodeKbdEvent parentId = model.get "parentId"
        $.each model.collection.where(parentId: parentId), (i, model) ->
          if model.id is modelId
            order = "-#" + (i + 1)
            false
      else
        shortcut = decodeKbdEvent modelId
      @$(".shortcut").html _.map(shortcut.split(" + "), (s) -> "<span>#{s}</span>").join("+") + order
      model.trigger "setSelected", true
      @model = model
    @render()
    @$el.show().draggable
      cursor: "move"
      delay: 200
      cancel: "input,textarea,button,select,option,.bookmarkPanel,span.contexts,span.menuCaption,span.title,div.CodeMirror"
      start: => @onStartDrag()
      stop: => @onStopDrag()
    @el.style.left = Math.round((window.innerWidth  - @el.offsetWidth)  / 2) + "px"
    @el.style.top = Math.max(0, Math.round((window.innerHeight - @el.offsetHeight) / 2)) + "px"
    @$(".caption").focus()
    $(".backscreen").show()
    true
  onStartDrag: -> # Virtual
  onStopDrag: -> # Virtual
  onClickCancel: ->
    @hidePopup()
  onHidePopup: ->
    if @$el.is(":visible")
      $(".backscreen").hide()
      @$el.hide()
      @model?.trigger "setSelected", false
      @$(".help").remove()
  hidePopup: ->
    @trigger "hidePopup"
  tmplHelp: _.template """
    <a href="helpview.html#<%=name%>" target="_blank" class="help" title="help">
      <i class="icon-question-sign" title="Help"></i>
    </a>
    """

class ExplorerBaseView extends PopupBaseView
  events: _.extend
    "click .expand-icon": "onClickExpandIcon"
    "click .expandAll"  : "onClickExpandAll"
    PopupBaseView.prototype.events
  constructor: (options) ->
    super(options)
    unless options.skipNiceScroll
      @setNiceScroll()
  setNiceScroll: ->
    @$(".result_outer").niceScroll
      cursorwidth: 12
      cursorborderradius: 6
      smoothscroll: true
      cursoropacitymin: .1
      cursoropacitymax: .6
    @elResult$ = @$(".result")
  showNiceScroll: ->
    @$(".result_outer").getNiceScroll().show().resize()
  hideNiceScroll: ->
    @$(".result_outer").getNiceScroll().hide()
  onShowPopup: (name, model) ->
    unless super(name, model)
      @hideNiceScroll()
      return false
    @showNiceScroll()
    true
  onStartDrag: ->
    @hideNiceScroll()
  onStopDrag: ->
    @showNiceScroll()
  onHidePopup: ->
    if @$el.is(":visible")
      @hideNiceScroll()
      super()
  onClickExpandAll: ->
    if @$(".expandAll").is(":checked")
      @$(".folder,.contexts").addClass("opened expanded")
    else
      @$(".folder,.contexts").removeClass("opened expanded")
      @$(".folder[data-id='1']").addClass "expanded"
    windowOnResize()

langs =
  "en": ["English"]
  "ja": ["Japanese"]

class SettingsView extends PopupBaseView
  name: "settings"
  el: ".settingsView"
  defaultIcon: "images/default.png"
  events: _.extend
    "click .copyExp"     : "onClickCopy"
    "click .saveSync"    : "onClickSaveSync"
    "click .loadSync"    : "onClickLoadSync"
    "click .paste"       : "onClickPaste"
    "click .impReplace"  : "onClickReplace"
    "click .impMerge"    : "onClickMerge"
    "click .impRestore"  : "onClickRestore"
    "click .nav-tabs a"  : "onClickTab"
    "click .clear"       : "onClickClear"
    "click .btnLoadIcon" : "onClickLoadIcon"
    "change .loadIcon"   : "onChangeIcon"
    PopupBaseView.prototype.events
  constructor: (options) ->
    super(options)
    lang$ = @$(".lang")
    $.each langs, (key, item) =>
      lang$.append """<option value="#{key}">#{item[0]}</option>"""
    # キーボード設定
    keys = keyCodes[@model.get("kbdtype")].keys
    selectKbd$ = @$(".kbdtype")
    $.each keyCodes, (key, item) =>
      selectKbd$.append """<option value="#{key}">#{item.name}</option>"""
    @model.trigger "change:lang"
  render: ->
    @$(".singleKey")[0].checked = @model.get("singleKey")
    @$(".wheelSwitches")[0].checked = @model.get("wheelSwitches")
    @$(".sleepMSec").val @model.get("defaultSleep")
    @$(".kbdtype").val @model.get("kbdtype")
    @$(".lang").val (@model.get("lang") || "ja")
    @trigger "getSaveData", container = {}
    @saveData = container.data
    delete @saveData.config.version
    @$(".export").val jsonstr = JSON.stringify @saveData
    if (new Blob([jsonstr])).size >= 102400
      @$(".saveSync").attr "disabled", "disabled"
    else
      @$(".saveSync").removeAttr "disabled"
    @$(".tabs li:has(a.tabImp)").removeClass "current"
    @$(".tabs li:has(a.tabExp)").addClass "current"
    @$("div.tabImp").hide()
    @$("div.tabExp").show()
    unless @customIcon = @model.get("customIcon")
      @customIcon = @defaultIcon
    @$(".customIcon").attr "src", @customIcon
    @
  onShowPopup: (name) ->
    unless super(name)
      return
    @$(".loadIcon").replaceWith "<input type=\"file\" class=\"loadIcon\" accept=\"image/x-png\" />"
    @customIcon = null
    # @$el.append @tmplHelp @
  onSubmitForm: ->
    defaultSleep = ~~@$(".sleepMSec").val()
    if !defaultSleep?
      return false
    else
      defaultSleep = Math.min(1000, Math.max(0, defaultSleep))
    defaultSleep = Math.round defaultSleep
    @model.set
      defaultSleep: defaultSleep
      kbdtype: @$(".kbdtype").val()
      lang: @$(".lang").val()
      singleKey: @$(".singleKey").is(":checked")
      wheelSwitches: @$(".wheelSwitches").is(":checked")
    if @customIcon
      @model.set customIcon: @customIcon
    @hidePopup()
    location.reload()
    false
  onClickTab: (event) ->
    [, which, active] = /(tabImp|tabExp).*(active)/.exec(event.currentTarget.className) || [, '', '']
    unless active is "active"
      @$("div.tabExp, div.tabImp").toggle()
      @$(".nav-tabs a").toggleClass "active"
  onClickCopy: ->
    chrome.runtime.sendMessage
      action: "setClipboard"
      value1: @$(".export").val()
      (msg) ->
  onClickSaveSync: ->
    saved = ((new Date).toString()).match(/(.*?)\s\(/)[1]
    syncData = "saved": saved
    for i in [0...@saveData.keyConfigSet.length]
      syncData["sc" + (1000 + i)] = @saveData.keyConfigSet[i]
    syncData.config = @saveData.config
    syncData.ctxMenuFolderSet = @saveData.ctxMenuFolderSet
    chrome.storage.sync.clear =>
      if err = chrome.runtime.lastError
        alert err.message
      else
        chrome.storage.sync.set syncData, ->
          if err = chrome.runtime.lastError
            #if /QUOTA_BYTES_PER_ITEM/.test err.message
            #  chkData @saveData.keyConfigSet
            alert err.message
          else
            chrome.storage.sync.getBytesInUse null, (bytes) ->
              if bytes >= 1000
                bytes = Math.floor(bytes / 1000) + "," + bytes.toString().substr(-3)
              alert "Settings has been saved to Chrome Sync successfully.\n\n• Total bytes in use/capacity: #{bytes}/102,400"
  onClickLoadSync: ->
    chrome.storage.sync.get (syncData) =>
      saveData = {}
      saveData.saved = syncData.saved
      saveData.config = syncData.config
      saveData.ctxMenuFolderSet = syncData.ctxMenuFolderSet
      saveData.keyConfigSet = []
      i = 0
      while scData = syncData["sc" + (1000 + i++)]
        saveData.keyConfigSet.push scData
      @$(".import").val JSON.stringify saveData
  onClickReplace: ->
    #@chkImport()
    try
      saveData = JSON.parse @$(".import").val()
      keyConfigSet = []
      saveData.keyConfigSet?.forEach (item) ->
        unless /^..2/.test(item.new)
          keyConfigSet.push item
      saveData.keyConfigSet = keyConfigSet
      @$(".impRestore").removeAttr("disabled").removeClass "disabled"
      @trigger "setSaveData", saveData
      @lastSaveData = @saveData
      @render()
      alert "Settings imported"
    catch e
      alert e.message
  onClickPaste: ->
    chrome.runtime.sendMessage
      action: "getClipboard"
      (resp) =>
        @$(".import").val resp.data
  onClickRestore: ->
    @$(".import").val JSON.stringify @lastSaveData
  onClickClear: ->
    @$(".import").val("")
  onClickLoadIcon: (e) ->
    @$(".loadIcon").click()
    e.target.blur()
    false
  onChangeIcon: ->
    files = @$(".loadIcon").get(0).files
    if files and files.length
      file = files[0]
      if file.size > 32000
        alert "Max file size up to 32KB"
      if /image\/png/.test(file.type)
        reader = new FileReader()
        reader.onload = (e) =>
          @$(".customIcon").attr "src", @customIcon = e.target.result
        reader.readAsDataURL file
      else
        alert("Not a png image.")
  chkImport: ->
  chkData: (keyConfigSet) ->
    if (keyConfigSet || []).length > 0
      for i in [0...keyConfigSet.length]
        jsonstr = JSON.stringify keyConfigSet[i]
        if (new Blob([jsonstr])).size >= 4096
          keyConfigSet[i].new
          break

commandsDisp =
  createTab:      ["tab", "Create new tab"]
  createTabBG:    ["tab", "Create new tab in inactivate"]
  moveTabLeft:    ["tab", "Move current tab left"]
  moveTabRight:   ["tab", "Move current tab right"]
  moveTabFirst:   ["tab", "Move current tab to first position"]
  moveTabLast:    ["tab", "Move current tab to last position"]
  closeOtherTabs: ["tab", "Close other tabs"]
  closeTabsLeft:  ["tab", "Close tabs to the left"]
  closeTabsRight: ["tab", "Close tabs to the right"]
  duplicateTab:   ["tab", "Duplicate current tab"]
  pinTab:         ["tab", "Pin/Unpin current tab"]
  detachTab:      ["tab", "Detach current tab"]
  detachPanel:    ["tab", "Detach current tab as panel"]
  detachSecret:   ["tab", "Detach current tab in an incognito mode"]
  attachTab:      ["tab", "Attach current tab to a next window"]
  zoomFixed:      ["tab", "Zooms current tab by fixed zoom factor"]
  zoomInc:        ["tab", "Zooms current tab by increments zoom factor"]
  switchPrevWin:  ["win", "Switch to the previous window"]
  switchNextWin:  ["win", "Switch to the next window"]
  closeOtherWins: ["win", "Close other windows"]
  clearCache:     ["clr", "Clear browser's cache"]
  clearCookiesAll:["clr", "Clear browser's cookies and site data"]
  clearHistory:   ["clr", "Clear browsing history"]
  clearCookies:   ["clr", "Clear cookies for the current domain"]
  #clearHistoryS:  ["clr", "Delete specific browsing history", [], "Clr"]
  clearTabHistory:["clr", "Clear tab history by duplicating the URL"]
  pasteText:      ["custom", "Paste static text", [], "Clip"]
  #copyText:       ["clip", "Copy text with history", "Clip"]
  #showHistory:    ["clip", "Show copy history"     , "Clip"]
  openExtProg:    ["custom", "Open URL from external program", [], "Ext"]
  insertCSS:      ["custom", "Insert CSS", [{ value:"allFrames", caption:"All frames" }], "CSS", ""]
  execJS:         ["custom", "Execute Script", [
    { value:"jquery"    , caption:"jQuery" }
    { value:"coffee"    , caption:"CoffeeScript" }
    { value:"allFrames" , caption:"All frames" }
    { value:"useUtilObj", caption:"""Use <a href="helpview.html#utilobj" target="helpview">utility object</a>""" }
  ], "JS"]

catnames =
  tab: "Tab"
  win: "Window"
  clr: "Browsing data"
  clip: "Clipboard"
  custom: "Custom"

class OptionExtProgView extends PopupBaseView
  name: "optionExtProg"
  el: ".optionExtProg"
  events: _.extend
    "change input[name='program']": "onChangeProgram"
    PopupBaseView.prototype.events
  render: ->
    @$(".progPath").val ""
    if @options = @model.get("command")
      value = @options.content
      if (radio = @$("input[name='program'][value='#{value}']")).length is 0
        @$(".progPath").val value
        value = "other"
    else
      value = "iexplore"
    @$("input[name='program'][value='#{value}']")[0].checked = true
  onChangeProgram: (event) ->
    if @$("input[name='program'][value='other']").is(":checked")
      @$(".progPath").focus()
    else
      @$(".progPath").blur()
  onSubmitForm: ->
    if (content = @$("input[name='program']:checked").val()) is "other"
      caption = content = $.trim @$(".progPath").val()
    else
      caption = $.trim @$("input[name='program']:checked").parent().text()
    unless content is ""
      @model
        .set
          "command":
            _.extend
              name: "openExtProg"
              caption: caption
              content: content
          {silent: true}
        .trigger "change:command"
      @hidePopup()
    false

class CommandOptionsView extends ExplorerBaseView
  name: "commandOptions"
  el: ".commandOptions"
  optionsName: "command"
  events: _.extend
    "click input[value='coffee']"       : "onClickChkCoffee"
    "change input[name='coffeePreview']": "onClickSwitchCoffee"
    PopupBaseView.prototype.events
  constructor: (options) ->
    options.skipNiceScroll = true
    super(options)
    @editer = CodeMirror.fromTextArea $(".content")[0],
      mode: "text/javascript"
      theme: "default"
      tabSize: 4
      indentUnit: 4
      indentWithTabs: true
      #electricChars: true
      lineNumbers: true
      firstLineNumber: 1
      gutter: false
      fixedGutter: false
      matchBrackets: true
    $(".CodeMirror-scroll").addClass "result_outer"
    @editer.on "change", =>
      @onStopDrag()
    @editer.lineAtHeight 18
    @setNiceScroll()
    @$(".content_outer").resizable
      minWidth: 650
      minHeight: 100
      start: @hideNiceScroll.bind(@)
      stop: @showNiceScroll.bind(@)
  render: ->
    @optionsName = "command"
    if @commandName? and @commandName isnt @options?.name
      @options = name: @commandName
    @trigger "getEditerSize", container = {}
    if container.width
      @$(".content_outer").width(container.width).height(container.height)
    else
      @$(".content_outer").width(700).height(200)
    @$(".command").html commandsDisp[@options.name][1]
    @$(".caption").val(@options.caption)
    commandOption = @$(".inputs").empty()
    commandsDisp[@options.name][2].forEach (option) =>
      option.checked = ""
      if @options[option.value]
        option.checked = "checked"
      commandOption.append @tmplOptions option
    # @$el.append @tmplHelp @
    @editer.setOption "readOnly", false
    @onClickChkCoffee currentTarget: @$("input[value='coffee']")
  showPopup2: ->
    if @options.name is "pasteText"
      @cmMode = "plain"
    else if @options.name is "insertCSS"
      @cmMode = "css"
    else # execJS
      if @options.coffee
        @cmMode = "x-coffeescript"
      else
        @cmMode = "javascript"
    @editer.setOption "mode", "text/" + @cmMode
    @editer.setValue @options.content || ""
    @editer.clearHistory()
    if history = andy.getUndoData @model.id
      @editer.setHistory history
    if @options.content
      @editer.focus()
    else
      @$(".caption").focus()
  onShowPopup: (name, model, @commandName) ->
    if @name is name
      super(name, model)
      @showPopup2()
    else
      @$el.hide()
  onSubmitForm: ->
    unless (content = @$(".content").val()) is ""
      options = {}
      $.each @$(".inputs input[type='checkbox']"), (i, option) =>
        options[option.value] = option.checked
        return
      unless caption = @$(".caption").val()
        caption = content.split("\n")[0]
      cmMode = @$(".execJS input[name='coffeePreview']:checked").val()
      if @options.name is "execJS" && options.coffee
        content = if cmMode is "x-coffeescript" then content else @coffee
        result = andy.coffee2JS @model.id, content
        unless result.success
          line = result.errLine
          unless confirm "A compilation error has occurred, but do you continue?\n\n  Line: #{line}\n  Error: #{result.err}"
            @editer.focus()
            @editer.setSelection { "line": line, "ch": 0 },  { "line": line - 1, "ch": 0 }, { "scroll": true }
            return false
      if @options.name isnt "execJS" || cmMode is "x-coffeescript"
        @undoData = @editer.getHistory()
      andy.setUndoData @model.id, @undoData
      @model
        .set
          "command":
            _.extend
              name: @options.name
              caption: caption
              content: content
              options
          {silent: true}
        .trigger "change:command"
      @hidePopup()
    false
  onClickChkCoffee: (event) ->
    if $(event.currentTarget).is(":checked") && @options.name is "execJS"
      @$(".execJS").css visibility: "inherit"
      @cmMode = "x-coffeescript"
    else
      @$(".execJS").css visibility: "hidden"
      @cmMode = "javascript"
      @editer.setOption "readOnly", false
      if @$(".execJS input[name='coffeePreview']:checked").val() is "javascript"
        @editer.clearHistory()
    @$(".execJS input[name='coffeePreview'][value='#{@cmMode}']").prop("checked", true)
    @editer.setOption "mode", "text/" + @cmMode
  onClickSwitchCoffee: ->
    unless (cmMode = @$(".execJS input[name='coffeePreview']:checked").val()) is @cmMode
      if readOnly = (cmMode is "javascript")
        try
          value = CoffeeScript.compile (@coffee = @editer.getValue()), bare: "on"
          @undoData = @editer.getHistory()
        catch e
          line = e.location.first_line + 1
          @editer.setSelection { "line": line, "ch": 0 },  { "line": line - 1, "ch": 0 }, { "scroll": true }
          alert "A compilation error has occurred.\n\n  Line: #{line}\n  Error: #{e.message}"
          @$("#radioCoffee").prop("checked", true)
          @editer.focus()
          return
        #@editer.setOption "theme", "elegant"
      else
        value = @coffee
        #@editer.setOption "theme", "default"
      @editer.setValue ""
      @editer.setOption "mode", "text/" + (@cmMode = cmMode)
      @editer.setValue value
      @editer.setOption "readOnly", readOnly
      if @cmMode is "x-coffeescript"
        @editer.clearHistory()
        @editer.setHistory @undoData
      @$(".execJS input[name='coffeePreview'][value='#{@cmMode}']").prop("checked", true)
  hidePopup: ->
    @trigger "setEditerSize", @$(".content_outer").width(), @$(".content_outer").height()
    super()
  tmplOptions: _.template """
    <label>
      <input type="checkbox" value="<%=value%>" <%=checked%>> <%=caption%>
    </label>
    """

class CommandsView extends PopupBaseView
  name: "command"
  el: ".commands"
  optionsName: "command"
  render: ->
    target$ = @$(".commandRadios")
    target$.empty()
    categories = []
    for key of commandsDisp
      categories.push commandsDisp[key][0]
    categories = _.unique categories
    categories.forEach (cat) ->
      target$.append """<div class="cat#{cat}"><div class="catname">#{catnames[cat]}</div>"""
    for key of commandsDisp
      target$.find(".cat" + commandsDisp[key][0])
        .append @tmplItem
          key: key
          value: commandsDisp[key][1]
    @
  onShowPopup: (name, model) ->
    unless super(name, model)
      return
    @$(".radioCommand").val [@options.name] if @options
    # @$el.append @tmplHelp @
  onSubmitForm: ->
    if command = @$(".radioCommand:checked").val()
      if command is "openExtProg"
        @trigger "showPopup", "optionExtProg", @model.id
      else if commandsDisp[command][2]
        @trigger "showPopup", "commandOptions", @model.id, command
      else
        @hidePopup()
        @model
          .set({"command": name: command}, {silent: true})
          .trigger "change:command"
    false
  tmplItem: _.template """
    <div>
      <label>
        <input type="radio" name="radioCommand" class="radioCommand" value="<%=key%>">
        <%=value%>
      </label>
    </div>
    """

class BookmarkOptionsView extends PopupBaseView
  name: "bookmarkOptions"
  el:   ".bookmarkOptions"
  optionsName: "bookmark"
  events: _.extend
    "click input[value='findtab']": "onClickFindTab"
    "change input[name='openmode']:radio": "onChangeOpenmode"
    PopupBaseView.prototype.events
  render: ->
    if @newSite
      @options = @newSite
    @$(".bookmark").text @options.title
    url = @options.url
    if /^javascript:/i.test(url)
      unless @options.openmode
        @options.openmode = "current"
      $.each @$(".inputs").children(), (i, elem) ->
        $(elem).hide()
      @$(".bookmarkPanel").show()
    else
      $.each @$(".inputs").children(), (i, elem) ->
        $(elem).show()
      @$(".bookmark").css("background-image", "-webkit-image-set(url(chrome://favicon/size/16@1x/#{@options.url}) 1x)")
    @$(".url").text url #.substring(0, 1024) + if @options.url.length > 1024 then " ..."
      .niceScroll
        cursorwidth: 7
        cursorborderradius: 3
        cursoropacitymin: .3
        cursoropacitymax: .7
        zindex: 999998
    @$(".findStr").val @options.findStr || url
    @$("input[value='#{(@options?.openmode || 'newtab')}']").get(0)?.checked = true
    @$(".tabpos").val "last"
    if @options.openmode in ["left", "right", "first", "last"]
      @$("input[value='newtab']")[0].checked = true
      @$(".tabpos").val @options.openmode
    (elFindtab = @$("input[value='findtab']")[0]).checked = if (findtab = @options.findtab) is undefined then true else findtab
    @onClickFindTab currentTarget: elFindtab
    @$("input[value='noActivate']")[0].checked = @options.noActivate
    # @$el.append @tmplHelp @
  onShowPopup: (name, model, bmId) ->
    if @name is name
      @newSite = null
      if bmId
        chrome.bookmarks.get bmId, (treeNode) =>
          treeNode.forEach (node) =>
            @newSite = node
            super(name, model)
      else
        super(name, model)
      @$(".url").getNiceScroll().show()
    else
      @$el.hide()
  onHidePopup: ->
    @onStartDrag()
    super()
  onStartDrag: ->
    @$(".url").getNiceScroll().hide()
  onStopDrag: ->
    @$(".url").getNiceScroll().show().resize()
  onSubmitForm: ->
    options =
      findtab:  @$("input[value='findtab']").is(":checked")
      openmode: @$("input[name='openmode']:checked").attr("value")
      findStr:  @$(".findStr").val()
    $.each @$("form input[type='checkbox']"), (i, option) =>
      options[option.value] = option.checked
      return
    if options.openmode is "newtab"
      options.openmode = @$(".tabpos").val()
    @model
      .set({"bookmark": _.extend @options, options}, {silent: true})
      .trigger "change:bookmark"
    @hidePopup()
    false
  onChangeOpenmode: (event) ->
    openmode = @$("input[name='openmode']:checked").val()
    chkFindtab$ = @$("input[value='findtab']")
    if openmode is "findonly"
      chkFindtab$.attr("disabled", "disabled")[0].checked = true
    else
      chkFindtab$.removeAttr("disabled")
    @onClickFindTab currentTarget: checked: chkFindtab$[0].checked
  onClickFindTab: (event) ->
    if event.currentTarget.checked
      @$(".findStr").removeAttr("disabled")
    else
      @$(".findStr").attr("disabled", "disabled").blur()

class BookmarksView extends ExplorerBaseView
  name: "bookmark"
  el: ".bookmarks"
  events: _.extend
    "click  a"          : "onClickBookmark"
    "click .title"      : "onClickFolder"
    "click .expand-icon": "onClickExpandIcon"
    ExplorerBaseView.prototype.events
  render: ->
    height = window.innerHeight - 60
    @$(".result_outer").height(height - 35)
    @$el.height(height)
    if @$(".result").children().length is 0
      @onSubmitForm()
    @
  onShowPopup: (name, model) ->
    unless super(name, model)
      return
    if (target = @$("input.query")).val()
      target.focus()
  onSubmitForm: (event) ->
    @$(".result").empty()
    query = @$("input.query").focus().val()
    if query
      @$(".expandAll")[0].checked = true
    state = if @$(".expandAll").is(":checked") then "opened expanded" else ""
    chrome.bookmarks.getTree (treeNode) =>
      treeNode.forEach (node) =>
        @digBookmarks node, @elResult$, query, 0, state
      @elResult$.append recent = $(@tmplFolder("title": "Recent", "state": state, "indent": 0))
      recent.find(".title").prepend """<img src="images/star.png">"""
      chrome.bookmarks.getRecent 50, (treeNode) =>
        treeNode.forEach (node) =>
          @digBookmarks node, recent, query, 1, state
        if event
          @showNiceScroll()
    false
  digBookmarks: (node, parent, query, indent, state) ->
    if node.title
      node.state = state
      if node.children
        node.indent = indent
        parent.append newParent = $(@tmplFolder(node))
        parent = newParent
      else
        if !query || (node.title + " " + node.url).toUpperCase().indexOf(query.toUpperCase()) > -1
          node.indent = indent + 1
          parent.append $(@tmplLink(node))
    else
      indent--
    if node.children
      parent.parent().addClass("hasFolder")
      node.children.forEach (child) =>
        @digBookmarks child, parent, query, indent + 1, state
  onClickFolder: (event) ->
    visible = (target$ = $(event.currentTarget).parent()).hasClass("opened")
    if visible
      target$.removeClass("opened expanded")
    else
      target$.addClass("opened expanded")
    @showNiceScroll()
  onClickExpandIcon: (event) ->
    expanded = (target$ = $(event.currentTarget).parent()).hasClass("expanded")
    if expanded
      target$.removeClass("expanded")
    else
      target$.addClass("expanded")
    @showNiceScroll()
  onClickBookmark: (event) ->
    target$ = $(event.currentTarget)
    @trigger "showPopup", "bookmarkOptions", @model.id, target$.attr("data-id")
    false
  tmplFolder: _.template """
    <div class="folder <%=state%>" style="text-indent:<%=indent%>em">
      <span class="expand-icon"></span><span class="title"><%=title%></span>
    </div>
    """
  tmplLink: _.template """
    <div class="link" style="text-indent:<%=indent%>em;">
      <a href="#" title="<%=url%>" data-id="<%=id%>" style="background-image:-webkit-image-set(url('chrome://favicon/size/16@1x/<%=url%>') 1x);"><%=title%></a>
    </div>
    """

tmplCtxMenus =
  page:           ["Page", "icon-file-alt"]
  selection:      ["Selection text", "icon-font"]
  editable:       ["Editable element", "icon-edit"]
  link:           ["Link", "icon-link"]
  image:          ["Image", "icon-picture"]
  browser_action: ["Toolbar button", "icon-reorder"]
  all:            ["All", "icon-asterisk"]

getUuid = (init) ->
  S4 = ->
    (((1+Math.random())*0x10000)|0).toString(16).substring(1)
  init + [S4(), S4()].join("").toUpperCase() + (new Date / 1000 | 0)

class CtxMenuOptionsView extends PopupBaseView
  name: "ctxMenuOptions"
  el: ".ctxMenuOptions"
  events: _.extend
    "click  .done,.delete": "onClickSubmit"
    "change .selectParent": "onChangeSelectParent"
    "click  .selectParent": "onClickSelectParent"
    "focus  .parentName"  : "onFocusParentName"
    "blur   .parentName"  : "onBlurParentName"
    PopupBaseView.prototype.events
  render: ->
    if @ctxMenu = @model.get "ctxMenu"
      unless @ctxMenu.parentId is "route"
        @ctxMenu.contexts = @collection.get(@ctxMenu.parentId).get "contexts"
      desc = @ctxMenu.caption
    else
      @model.trigger "getDescription", container = {}
      desc = container.desc
    @$(".caption").val desc
    # @$el.append @tmplHelp @
    @$("input[value='#{((contexts = @ctxMenu?.contexts) || 'page')}']")[0].checked = true
    if @ctxMenu
      @$(".delete").addClass("orange").removeClass("disabled").removeAttr("disabled")
    else
      @$(".delete").removeClass("orange").addClass("disabled").attr("disabled", "disabled")
    lastParentId = (selectParent$ = @$(".selectParent")).val()
    ctxType = @$("input[name='ctxType']:checked").attr("value")
    selectParent$.html @tmplParentMenu
    @collection.models.forEach (model) ->
      selectParent$.append """<option value="#{model.id}">#{model.get("title")}</option>"""
    if parentId = @ctxMenu?.parentId
      selectParent$.val parentId
    else if selectParent$.find("option[value='#{lastParentId}']").length > 0  #lastParentId in container.parents
      selectParent$.val lastParentId
    else
      selectParent$.val "route"
    @$(".parentName").val("").hide()
  onChangeSelectParent: (event) ->
    if event.currentTarget.value isnt "new"
      @$(".parentName").hide()
    else
      @$(".parentName").show().focus()
  onClickSelectParent: (event) ->
    event.preventDefault()
  onFocusParentName: (event) ->
    @$(".selectParent").addClass "focus"
  onBlurParentName: ->
    @$(".selectParent").removeClass "focus"
  onSubmitForm: ->
    false
  onClickSubmit: (event) ->
    if (parentId = @$(".selectParent").val()) is "new"
      if (parentName = $.trim @$(".parentName").val()) is ""
        return false
    if (caption = $.trim @$(".caption").val()) is ""
      return false
    if /delete/.test event?.currentTarget.className
      unless confirm "Are you sure you want to delete this context menu?"
        return false
      @model.unset("ctxMenu")
    else
      ctxType = @$("input[name='ctxType']:checked").attr("value")
      if parentId is "route"
        @model.set("ctxMenu", caption: caption, contexts: ctxType, parentId: parentId, order: @ctxMenu?.order)
      else
        if parentId is "new"
          if model = @collection.findWhere(contexts: ctxType, title: parentName)
            parentId = model.id
        else
          parentName = @$(".selectParent option[value='#{parentId}']").text()
        unless @collection.findWhere(id: parentId, contexts: ctxType)
          @collection.add
            id: parentId = getUuid("T")
            contexts: ctxType
            title: parentName
        @model.set("ctxMenu", caption: caption, parentId: parentId, order: @ctxMenu?.order)
    @trigger "getCtxMenues", container = {}
    (_.difference @collection.pluck("id"), _.pluck(container.ctxMenus, "parentId")).forEach (id) =>
      @collection.remove @collection.get(id)
    (dfd = $.Deferred()).promise()
    @trigger "remakeCtxMenu", dfd: dfd
    dfd.done =>
      @hidePopup()
    false
  tmplParentMenu: """
    <option value="route">None(Root)</option>
    <option value="new">Create a new folder...</option>
    """

CtxMenuFolder = Backbone.Model.extend {}
CtxMenuFolderSet = Backbone.Collection.extend model: CtxMenuFolder

class CtxMenuGetterView extends PopupBaseView
  el: ".ctxMenusGetter"
  events: _.extend
    "click .add": "onClickAdd"
    "click .cancel": "onClickCancel"
    PopupBaseView.prototype.events
  constructor: (options) ->
    super(options)
    @$el
      .css(top: 0, right: "30px")
      .draggable
        cursor: "move"
        delay: 200
        cancel: "input,textarea,button,select,option"
  render: (message) ->
    @$(".message").html @tmplMessage message
    @$el.show(200)
    @
  onHidePopup: ->
    @$el.hide(200)
  onClickAdd: ->
    @$el.hide(200)
    @trigger "addCtxMenus"
  onClickCancel: ->
    @$el.hide(200)
    @trigger "addCtxMenus", true
  tmplMessage: _.template """
    Add entries to context menu for <strong><%=contextName%></strong><%=folder%><br>from the shortcuts that you selected.
    """

class CtxMenuManagerView extends ExplorerBaseView
  name: "ctxMenuManager"
  el: ".ctxMenuManager"
  events: _.extend
    "mousedown span[tabindex='0']": "onClickItem"
    "mousedown button,input,a": "onClickClickable"
    "mousedown .newmenu"  : "onClickNew"
    "mousedown .newfolder": "onClickNewFolder"
    "mousedown .rename"   : "onClickRen"
    "dblclick  .menuCaption,.title": "onClickRen"
    "keydown   .menuCaption,.title": "onKeydownCaption"
    "mousedown .remove"   : "onClickRemove"
    "submit .editCaption" : "doneEditCaption"
    "blur .editCaption input": "cancelEditCaption"
    "mousedown"           : "onClickBlank"
    "click .done"         : "onClickDone"
    ExplorerBaseView.prototype.events
  constructor: (options) ->
    super(options)
    @ctxMenuGetterView = new CtxMenuGetterView {}
    @ctxMenuGetterView.on "addCtxMenus", @onAddCtxMenus, @
    keyConfigSetView.on "addCtxMenu", @onAddCtxMenu, @
    @collection.comparator = (model) -> model.get "order"
  render: ->
    height = window.innerHeight - 60 #height
    @$(".result_outer").height(height - 35)
    @$el.height(height)
    # @$("input.rootTitle").val @model.get("ctxRootTitle") || ""
    @setContextMenu()
    @setSortable ".folders", ".title,.menuCaption", @onUpdateFolder
    @setSortable ".ctxMenus", ".menuCaption", @onUpdateMenu
    @disableButton XX(".editButtons button").map (el) -> el.className.replace(/\s+/g, '.')
    # @$el.append @tmplHelp @
    @
  onSubmitForm: ->
    false
  setSortable: (selector, handle, fnDoneUpdate) ->
    @$(selector).sortable
      scroll: true
      handle: handle
      connectWith: selector
      placeholder: "ui-placeholder"
      delay: 200
      update: (event, ui) => fnDoneUpdate event, ui, @
      start: (event, ui) => @onStartSort event, ui
      stop: (event, ui)  => @onStopSort event, ui, @
  setFolderDroppable: (target$) ->
    that = this
    target$.droppable
      accept: ".ctxMenuItem.route"
      tolerance: "pointer"
      hoverClass: "drop-folder-hover"
      over: -> $(".folders .ui-placeholder").hide()
      out: -> $(".folders .ui-placeholder").show()
      drop: (event, ui) ->
        ctxMenu$ = $(@).find(".ctxMenus")
        ui.draggable.hide "fast", ->
          that.onUpdateMenu null, item: $(@).appendTo(ctxMenu$).removeClass("route").show().find("span[tabindex='0']").focus(), that
  onUpdateFolder: (event, ui, view) ->
    if ui && _.filter(ui.item.parent().find(".title"), (title) -> title.textContent is ui.item.prevInfo?.text).length > 1
      alert("A folder with the name '#{ui.item.prevInfo.text}' already exists.")
      folders$ = view.$(".folders." + ui.item.prevInfo.contexts)
      ref = folders$.children().eq(ui.item.prevInfo.order).get(0) || null
      folders$[0].insertBefore ui.item[0], ref
      return
    $.each view.$(".folders"), (i, folders) ->
      if (folders$ = $(folders)).find(".folder,.ctxMenuItem").length > 0
        folders$.parents(".contexts").addClass("hasFolder")
      else
        folders$.parents(".contexts").removeClass("hasFolder")
    ui.item.focus() if ui
  onUpdateMenu: (event, ui, view) ->
    $.each view.$(".ctxMenus"), (i, menuItem) ->
      if (menuItem$ = $(menuItem)).find(".ctxMenuItem,.dummy").length > 0
        menuItem$.parents(".folder").addClass("hasFolder")
      else
        menuItem$.parents(".folder").removeClass("hasFolder")
    if ui
      ui.item.parents(".folder").addClass("hasFolder")
      ui.item.focus()
  onGetCtxMenuContexts: (container) ->
    container.contexts = @collection.get(container.parentId)?.get "contexts"
  onClickDone: ->
    newCtxMenu = []
    @collection.reset()
    $.each @$(".ctxMenuItem"), (i, el) =>
      menu$ = $(el)
      message = id: el.id
      message.caption = menu$.find(".menuCaption").text()
      message.order = i + 1
      message.parentId = menu$.parents(".folder").get(0)?.id || "route"
      contexts = menu$.parents(".folders")[0].className.match(/folders\s(\w+)/)[1]
      if message.parentId is "route"
        message.contexts = contexts
      else
        unless @collection.findWhere(id: message.parentId, contexts: contexts)
          @collection.add
            id: message.parentId
            contexts: contexts
            title: @$("#" + message.parentId + " .title").text()
      newCtxMenu.push message
    @trigger "setCtxMenus", newCtxMenu
    (dfd = $.Deferred()).promise()
    # @model.set "ctxRootTitle", rootTitle = @$("input.rootTitle").val().trim()
    # @trigger "remakeCtxMenu", {dfd: dfd, rootTitle: rootTitle}
    @trigger "remakeCtxMenu", dfd: dfd
    dfd.done =>
      @hidePopup()
    # andy.saveConfig keyConfigSetView.getSaveData()
    false
  onClickBlank: ->
    #@$(":focus").blur()
    #$.each @$(".editButtons button"), (i, el) =>
    #  @disableButton _.map(document.querySelectorAll(".editButtons button"), (el) -> el.className.match(/^(\w+)\s/)[1])
  onClickClickable: (event) ->
    event.stopPropagation()
    #event.preventDefault()
  onClickNew: (event) ->
    unless /contexts|title/.test (target$ = $(document.activeElement)).get(0)?.className
      return
    @activeFolder = {}
    if target$.hasClass("toolbarIcon")
      @activeFolder.folder = ""
      contexts$ = target$
      @activeFolder.parentId = "route"
      @activeFolder.contexts = "toolbarIcon"
      @activeFolder.selector = ".toolbarIcon .contexts"
    else if target$.hasClass("contexts")
      @activeFolder.folder = ""
      contexts$ = target$
      @activeFolder.parentId = "route"
      @activeFolder.contexts = (className = target$.parent()[0].className).match(/droppable\s(\w+)/)[1]
      @activeFolder.selector = "." + className.replace(/\s/g, ".") + " .contexts"
    else
      @activeFolder.folder = " in the folder '<strong>#{target$.text()}</strong>'"
      contexts$ = target$.parents("div.contexts").find("span.contexts")
      @activeFolder.parentId = target$.parent()[0].id
      @activeFolder.selector = "#" + @activeFolder.parentId + " .title"
    @activeFolder.icon = contexts$.find("i")[0].className
    @activeFolder.contextName = contexts$.text()
    setTimeout((=>
      @ctxMenuGetterView.render @activeFolder
    ), 0)
    entried = _.map(@$(".ctxMenuItem"), (el) -> el.id)
    @trigger "enterCtxMenuSelMode", entried
    @$(".result_outer").getNiceScroll().hide()
    @$el.hide()
    $(".backscreen").hide()
  onAddCtxMenu: (ctxMenu) ->
    @setContextMenuItem _.extend(ctxMenu, @activeFolder)
    @$("#" + ctxMenu.id).hide().show(300).effect("highlight", {color: '#fcc'}, 2000)
    @setSortable ".ctxMenus", ".menuCaption", @onUpdateMenu
    @$(".folders").sortable "refresh"
  onAddCtxMenus: (cancel) ->
    @trigger "leaveCtxMenuSelMode", cancel
    @$el.show()
    @$(".newmenu").focus()
    @$(".result_outer").getNiceScroll().show()
    $(".backscreen").show()
    @$(@activeFolder.selector).focus()
    if cancel
      return
    @trigger "triggerEventSelected"
    @onUpdateMenu null, null, @
    @onUpdateFolder null, null, @
    @$(@activeFolder.selector).focus()
  onClickNewFolder: (event) ->
    unless (target$ = $(document.activeElement)).hasClass("contexts")
      return
    folders$ = target$.parents(".contexts").find ".folders"
    (newFolder$ = $(@tmplFolder id: getUuid("T"), title: "").appendTo(folders$)).find(".title").focus()
    @setSortable ".ctxMenus", ".menuCaption", @onUpdateMenu
    @$(".folders").sortable "refresh"
    @setFolderDroppable newFolder$
    @disableButton ["rename", "remove", "newmenu"], false
    @disableButton ["newfolder"]
    @onClickRen event
  onKeydownCaption: (event) ->
    if event.originalEvent.key is "F2"
      @onClickRen event
  onClickRen: (event) ->
    unless /title|menuCaption/.test (target$ = $(document.activeElement))[0].className
      return
    editer$ = target$.hide().parent().find(".editCaption input:first").show()
    editer$.val(target$.text()).focus()
    event.preventDefault()
  escapeAmp: (text) ->
    text.replace(/&&/g, "^ampersand^").replace(/&/g, "").replace /^ampersand^/g, ""
  doneEditCaption: (event) ->
    if value = $.trim (editer$ = $(event.currentTarget).find("> input")).val()
      if (folder$ = editer$.parent().parent()).hasClass "folder"
        notExists = true
        $.each folder$.parent().find(".title"), (i, title) ->
          if folder$[0] isnt title.parentNode && title.textContent is value
            $("#tiptip_content").text("Folder '#{value}' already exists.")
            editer$.tipTip()
            return notExists = false
        return false if !notExists
    else
      editer$.blur()
      return false
    editer$.hide().parents("div:first").find("> .title,> .menuCaption").show().text(value).focus()
    false
  cancelEditCaption: (event) ->
    unless (target$ = $(event.currentTarget).hide().parents("div:first").find(".title,.menuCaption").show()).text()
      target$.parents(".folder").remove()
  onClickRemove: (event) ->
    unless /title|menuCaption/.test (active$ = $(document.activeElement))[0].className
      return
    active$.parent().remove()
    @onUpdateMenu null, null, @
    @onUpdateFolder null, null, @
  disableButton: (buttonClasses, disabled = true) ->
    selector = buttonClasses.map((className) -> "." + className).join(",")
    @$(selector).prop("disabled", disabled)
  onClickItem: (event) ->
    switch event.currentTarget.className
      when "contexts"
        @disableButton ["newmenu", "newfolder"], false
        @disableButton ["rename", "remove"]
      when "title"
        @disableButton ["rename", "remove", "newmenu"], false
        @disableButton ["newfolder"]
      when "menuCaption"
        @disableButton ["rename", "remove"], false
        @disableButton ["newmenu", "newfolder"]
    event.currentTarget.focus()
    event.preventDefault()
    event.stopPropagation()
  onHoverMoveItem: (event) ->
    #@$(event.currentTarget).find("> .updown").show()
  onHoverOffMoveItem: ->
    #@$(".updown").hide()
  onMouseoverDroppable: ->
    @$(".ctxMenus .ui-placeholder").hide()
  onStartSort: (event, ui) ->
    ui.item.find("span[tabindex='0']:first").focus()
    if /folder/.test ui.item[0].className
      ui.item.addClass("sorting").find(".ctxMenus").hide()
      ui.item.prevInfo =
        contexts: ui.item.parent()[0].className.match(/folders\s(\w+)/)[1]
        order: ui.item.parent().children().index(ui.item)
        text: ui.item.find(".title").text()
    #ui.find("> .updown").show()
  onStopSort: (event, ui, view) ->
    ui.item.find("span[tabindex='0']:first").focus()
    view.$(".folder").removeClass("sorting")
    view.$(".ctxMenus").show()
    #@$(".updown").hide()
  onClickExpandIcon: (event) ->
    @$(event.currentTarget).parents(".folder").focus()
    expanded = (target$ = $(event.currentTarget).parents(".contexts")).hasClass("expanded")
    if expanded
      target$.removeClass("expanded")
    else
      target$.addClass("expanded")
    windowOnResize()
    event.stopPropagation()
  setContextMenu: () ->
    @$(".result").empty()
    @trigger "getCtxMenues", container = {}
    ctxMenus = container.ctxMenus
    for key of tmplCtxMenus
      @elResult$.append context$ = $(@tmplContexts
        "contexts": key
        "dispname": tmplCtxMenus[key][0]
        "icon": tmplCtxMenus[key][1]
        )
      that = this
      context$.find(".droppable").droppable
        accept: ".ctxMenuItem:not(.route)"
        tolerance: "pointer"
        hoverClass: "drop-hover"
        over: -> $(".ctxMenus .ui-placeholder").hide()
        out: -> $(".ctxMenus .ui-placeholder").show()
        drop: (event, ui) ->
          target$ = $(".folders." + this.className.match(/droppable\s(\w+)/)[1])
          ui.draggable.hide "fast", ->
            that.onUpdateMenu null, item: $(this).appendTo(target$).addClass("route").show().find("span[tabindex='0']").focus(), that
    ctxMenus.forEach (ctxMenu) =>
      @setContextMenuItem ctxMenu
    @onUpdateMenu null, null, @
    @onUpdateFolder null, null, @
  setContextMenuItem: (ctxMenu) ->
    # if folder = @collection.get(ctxMenu.parentId)
    #   @$(".contexts .folders." + folder.get("contexts")).append @tmplFolder id: folder.id, title: folder.get("title")
    #   dest$ = @$("#" + ctxMenu.parentId + " .ctxMenus")
    #   @setFolderDroppable @$("#" + ctxMenu.parentId)
    #   ctxMenu.route = ""
    # else
    #   dest$ = @$(".contexts .folders." + ctxMenu.contexts)
    #   ctxMenu.route = " route"
    if ctxMenu.parentId is "route"
      dest$ = @$(".contexts .folders." + ctxMenu.contexts)
      ctxMenu.route = " route"
    else
      ctxMenu.route = ""
      unless (dest$ = @$("#" + ctxMenu.parentId + " .ctxMenus")).length > 0
        folder = @collection.get ctxMenu.parentId
        @$(".contexts .folders." + folder.get("contexts")).append @tmplFolder id: folder.id, title: folder.get("title")
        dest$ = @$("#" + ctxMenu.parentId + " .ctxMenus")
        @setFolderDroppable @$("#" + ctxMenu.parentId)
    dest$.append @tmplMenuItem ctxMenu
  tmplContexts: _.template """
    <div class="contexts">
      <div class="droppable <%=contexts%>">
        <span class="contexts" tabindex="0"><i class="<%=icon%> contextIcon"></i><%=dispname%></span>
      </div>
      <div class="folders <%=contexts%>"></div>
    </div>
    """
  tmplFolder: _.template """
    <div class="folder hasFolder" id="<%=id%>">
      <span class="title" tabindex="0"><div class="sortable"></div><%=title%></span>
      <div class="emptyFolder"></div>
      <form class="editCaption"><input type="text" class="form-control"></form>
      <div class="ctxMenus"></div>
    </div>
    """
  tmplMenuItem: _.template """
    <div class="ctxMenuItem<%=route%>" id="<%=id%>">
      <span class="menuCaption" tabindex="0" title="<%=shortcut%>"><%=caption%><div class="sortable"></div></span>
      <form class="editCaption"><input type="text" class="form-control"></form>
    </div>
    """
