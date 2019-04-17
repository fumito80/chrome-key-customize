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
    "submit form"        : "onSubmitForm"
    "click  .icon-remove": "onClickIconRemove"
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
      stop: => @onStopDrag()
    @el.style.left = Math.round((window.innerWidth  - @el.offsetWidth)  / 2) + "px"
    @el.style.top = Math.max(0, Math.round((window.innerHeight - @el.offsetHeight) / 2)) + "px"
    @$(".caption").focus()
    $(".backscreen").show()
    true
  onStopDrag: -> # Virtual
  onClickIconRemove: ->
    @hidePopup()
  onHidePopup: ->
    if @$el.is(":visible")
      $(".backscreen").hide()
      @$el.hide()
      @model?.trigger "setSelected", false
  hidePopup: ->
    #router.showRootPage()
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
    # ctx = document.getCSSCanvasContext("2d", "triangle", 10, 6);
    # ctx.translate(.5, .5)
    # ctx.fillStyle = "#000000"
    # ctx.beginPath()
    # ctx.moveTo(8, 0)
    # ctx.lineTo(8, .5)
    # ctx.lineTo(8/2-.5, 8/2+.5)
    # ctx.lineTo(0, .5)
    # ctx.lineTo(0, 0)
    # ctx.closePath()
    # ctx.fill()
    # ctx.stroke()
    @$(".result_outer").niceScroll
      cursorwidth: 12
      cursorborderradius: 6
      smoothscroll: true
      cursoropacitymin: .1
      cursoropacitymax: .6
    @elResult$ = @$(".result")
  onShowPopup: (name, model) ->
    unless super(name, model)
      @$(".result_outer").getNiceScroll().hide()
      return false
    @$(".result_outer").getNiceScroll().show()
    true
  onStopDrag: ->
    @$(".result_outer").getNiceScroll().resize()
  onHidePopup: ->
    if @$el.is(":visible")
      @$(".result_outer").getNiceScroll().hide()
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
    "click .copyExp"   : "onClickCopy"
    "click .saveSync"  : "onClickSaveSync"
    "click .loadSync"  : "onClickLoadSync"
    "click .paste"     : "onClickPaste"
    "click .impReplace": "onClickReplace"
    "click .impMerge"  : "onClickMerge"
    "click .impRestore": "onClickRestore"
    "click .tabs a"    : "onClickTab"
    "click .clear"     : "onClickClear"
    "click .btnLoadIcon" : "onClickLoadIcon"
    "change .loadIcon" : "onChangeIcon"
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
    @$el.append @tmplHelp @
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
    newTab = event.currentTarget.className
    unless (currentTab$ = @$("div." + newTab)).is(":visible")
      @$("div.tabExp,div.tabImp").hide()
      currentTab$.show()
      @$(".tabs li").removeClass "current"
      @$(".tabs li:has(a.#{newTab})").addClass "current"
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
      (resp) ->
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
  insertCSS:      ["custom", "Inject CSS", [{value:"allFrames", caption:"All frames"}], "CSS", ""]
  execJS:         ["custom", "Inject JavaScript", [
    {value:"allFrames" ,  caption:"All frames"}
    {value:"coffee"    ,  caption:"CoffeeScript"}
    {value:"jquery"    ,  caption:"jQuery"}
    {value:"useUtilObj", caption:"""Use <a href="helpview.html#utilobj" target="helpview">utility object</a>"""}
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
      #unless caption = @$(".caption").val()
      #  caption = content.split("\n")[0]
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
    "click input[value='coffee']": "onClickChkCoffee"
    "click .tabs a"              : "onClickSwitchCoffee"
    PopupBaseView.prototype.events
  constructor: (options) ->
    super()
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
    super(options)
    @$(".content_outer").resizable
      minWidth: 650
      minHeight: 100
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
    @$el.append @tmplHelp @
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
      if @options.name is "execJS" && options.coffee
        content = if @$(".tabs li:has(a.x-coffeescript)").hasClass("current") then content else @coffee
        result = andy.coffee2JS @model.id, content
        unless result.success
          unless confirm "A compilation error has occurred, but do you continue?\n\n  Line: #{result.errLine}\n  Error: #{result.err}"
            return false
      if @options.name isnt "execJS" || @$(".tabs li:has(a.x-coffeescript)").hasClass("current")
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
      @$(".tabs").css visibility: "inherit"
      @cmMode = "x-coffeescript"
      @$(".tabs li").removeClass "current"
      @$(".tabs li:has(a[class='#{@cmMode}'])").addClass "current"
    else
      @$(".tabs").css visibility: "hidden"
      @cmMode = "javascript"
      @editer.setOption "readOnly", false
      if @$(".tabs li:has(a.javascript)").hasClass("current")
        @editer.clearHistory()
    @editer.setOption "mode", "text/" + @cmMode
  onClickSwitchCoffee: (event) ->
    unless (className = event.currentTarget.className) is @cmMode
      if readOnly = (className is "javascript")
        try
          value = CoffeeScript.compile (@coffee = @editer.getValue()), bare: "on"
          @undoData = @editer.getHistory()
        catch e
          alert "A compilation error has occurred.\n\n  Line: #{e.location.first_line+1}\n  Error: #{e.message}"
          return
        #@editer.setOption "theme", "elegant"
      else
        value = @coffee
        #@editer.setOption "theme", "default"
      @editer.setValue ""
      @editer.setOption "mode", "text/" + (@cmMode = className)
      @editer.setValue value
      @editer.setOption "readOnly", readOnly
      if @cmMode is "x-coffeescript"
        @editer.clearHistory()
        @editer.setHistory @undoData
      @$(".tabs li").removeClass "current"
      @$(".tabs li:has(a[class='#{@cmMode}'])").addClass "current"
  hidePopup: ->
    @trigger "setEditerSize", @$(".content_outer").width(), @$(".content_outer").height()
    super()
  tmplOptions: _.template """
    <label>
      <input type="checkbox" value="<%=value%>" <%=checked%>> <%=caption%>
    </label><br>
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
    @$el.append @tmplHelp @
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
    @$(".url").text url.substring(0, 1024) + if @options.url.length > 1024 then " ..."
    @$(".findStr").val @options.findStr || url
    @$("input[value='#{(@options?.openmode || 'newtab')}']").get(0)?.checked = true
    @$(".tabpos").val "last"
    if @options.openmode in ["left", "right", "first", "last"]
      @$("input[value='newtab']")[0].checked = true
      @$(".tabpos").val @options.openmode
    (elFindtab = @$("input[value='findtab']")[0]).checked = if (findtab = @options.findtab) is undefined then true else findtab
    @onClickFindTab currentTarget: elFindtab
    @$("input[value='noActivate']")[0].checked = @options.noActivate
    @$el.append @tmplHelp @
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
    else
      @$el.hide()
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
  onSubmitForm: ->
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
    windowOnResize()
    event.stopPropagation()
  onClickExpandIcon: (event) ->
    expanded = (target$ = $(event.currentTarget).parent()).hasClass("expanded")
    if expanded
      target$.removeClass("expanded")
    else
      target$.addClass("expanded")
    windowOnResize()
    event.stopPropagation()
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
    @$el.append @tmplHelp @
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
    Add entries to context menu for <span class="ctxmenu-icon"><i class="<%=icon%>"></i></span><strong><%=contextName%></strong><%=folder%><br>from the shortcuts that you selected.
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
    # ctx = document.getCSSCanvasContext("2d", "empty", 18, 18);
    # ctx.strokeStyle = "#CC0000"
    # ctx.lineWidth = "2"
    # ctx.lineCap = "round"
    # ctx.beginPath()
    # ctx.moveTo 1, 1
    # ctx.lineTo 17, 17
    # ctx.moveTo 1, 17
    # ctx.lineTo 17, 1
    # ctx.stroke()
    # ctx = document.getCSSCanvasContext("2d", "updown", 26, 24);
    # ctx.fillStyle = "rgb(122, 122, 160)"
    # ctx.lineWidth = "2"
    # ctx.lineCap = "round"
    # ctx.lineJoin = "round"
    # ctx.strokeStyle = "#333333"
    # for i in [0..1]
    #   ctx.beginPath()
    #   ctx.moveTo 1, 5
    #   ctx.lineTo 5, 1
    #   ctx.lineTo 9, 5
    #   ctx.moveTo 5, 1
    #   ctx.lineTo 5, 9
    #   ctx.stroke()
    #   ctx.translate 18, 18
    #   ctx.rotate(180 * Math.PI / 180);
    @collection.comparator = (model) -> model.get "order"
  render: ->
    height = window.innerHeight - 60 #height
    @$(".result_outer").height(height - 35)
    @$el.height(height)
    # @$("input.rootTitle").val @model.get("ctxRootTitle") || ""
    @setContextMenu()
    @setSortable ".folders", ".title,.menuCaption", @onUpdateFolder
    @setSortable ".ctxMenus", ".menuCaption", @onUpdateMenu
    $.each @$(".editButtons button"), (i, el) =>
      @disableButton _.map(document.querySelectorAll(".editButtons button"), (el) -> el.className.match(/^(\w+)\s/)[1])
    @$el.append @tmplHelp @
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
    @enableButton ["rename", "remove", "newmenu"]
    @disableButton ["newfolder"]
    @onClickRen event
  onKeydownCaption: (event) ->
    if event.originalEvent.keyIdentifier is "F2"
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
  enableButton: (buttonClasses) ->
    buttonClasses.forEach (className) ->
      @$("button." + className).removeClass("disabled").removeAttr("disabled")
  disableButton: (buttonClasses) ->
    buttonClasses.forEach (className) ->
      @$("button." + className).addClass("disabled").attr("disabled", "disabled")
  onClickItem: (event) ->
    switch event.currentTarget.className
      when "contexts"
        @enableButton  ["newmenu", "newfolder"]
        @disableButton ["rename", "remove"]
      when "title"
        @enableButton  ["rename", "remove", "newmenu"]
        @disableButton ["newfolder"]
      when "menuCaption"
        @enableButton  ["rename", "remove"]
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
      <form class="editCaption"><input type="text"></form>
      <div class="ctxMenus"></div>
    </div>
    """
  tmplMenuItem: _.template """
    <div class="ctxMenuItem<%=route%>" id="<%=id%>">
      <span class="menuCaption" tabindex="0" title="<%=shortcut%>"><%=caption%><div class="sortable"></div></span>
      <form class="editCaption"><input type="text"></form>
    </div>
    """
gMaxItems = 100
defaultSleep = 100
lastFocused = null
loading = true

WebFontConfig =
  google: families: ['Noto+Sans::latin']

modeDisp =
  remap:    ["Remap"      , "icon-random"]
  command:  ["Command..." , "icon-cog"]
  bookmark: ["Bookmark...", "icon-bookmark-empty"]
  #keydown:  ["KeyDown"    , "icon-font"]
  disabled: ["Disabled"   , "icon-ban-circle"]
  sleep:    ["Sleep"      , "icon-eye-close"]
  comment:  ["Comment"    , "icon-comment-alt"]
  through:  ["Pause"      , "icon-pause", "nodisp"]

bmOpenMode =
  current:   "Open in current tab"
  newtab:    "Open in new tab"
  newwin:    "Open in new window"
  panel:     "Open as panel window"
  incognito: "Open in incognito window"
  left:      "Open in new tab to left of the current tab"
  right:     "Open in new tab to right of the current tab"
  first:     "Open in new tab to first position"
  last:      "Open in new tab to last position"

escape = (html) ->
  entity =
  "&": "&amp;"
  "<": "&lt;"
  ">": "&gt;"
  html.replace /[&<>]/g, (match) ->
    entity[match]

modifierKeys  = ["Ctrl", "Alt", "Shift", "Win", "MouseL", "MouseR", "MouseM"]
modifierInits = ["c"   , "a"  , "s"    , "w"]

decodeKbdEvent = (kbdCode) ->
  unless kbdCode
    return null
  modifiers = parseInt(kbdCode.substring(0, 2), 16)
  scanCode = kbdCode.substring(2)
  if keyIdentifier = keys[scanCode]
    keyCombo = []
    ###
    for i in [0...modifierKeys.length]
      keyCombo.push modifierKeys[i] if modifiers & Math.pow(2, i)
    ###
    keyCombo.push modifierKeys[0] if modifiers & 1
    keyCombo.push modifierKeys[2] if modifiers & 4
    keyCombo.push modifierKeys[1] if modifiers & 2
    keyCombo.push modifierKeys[3] if modifiers & 8
    keyCombo.push modifierKeys[4] if modifiers & 16
    keyCombo.push modifierKeys[5] if modifiers & 32
    keyCombo.push modifierKeys[6] if modifiers & 64
    if modifiers & 4
      keyCombo.push keyIdentifier[1] || keyIdentifier[0]
    else
      keyCombo.push keyIdentifier[0]
    keyCombo.join(" + ")

transKbdEvent = (value) ->
  modifiers = parseInt(value.substring(0, 2), 16)
  keyCombo = []
  for i in [0...modifierInits.length]
    keyCombo.push modifierInits[i] if modifiers & Math.pow(2, i)
  scanCode = value.substring(2)
  keyIdenfiers = keys[scanCode]
  "[" + keyCombo.join("") + "]" + keyIdenfiers[0]

HeaderView = Backbone.View.extend
  scHelpUrl: "https://support.google.com/chrome/answer/157179?hl="
  # Backbone Buitin Events
  el: "div.header"
  events:
    "click .addKeyConfig": "onClickAddKeyConfig"
    "click .ctxmgr"      : "onClickCtxmgr"
    "click .settings"    : "onClickSettings"
  initialize: (options) ->
    @$(".addKeyConfig,.ctxmgr,.scHelp,.helpview,.settings").show()
    @model.on "change:lang", @onChangeLang, @
  # DOM Events
  onClickAddKeyConfig: (event) ->
    @trigger "clickAddKeyConfig", (event)
  onClickCtxmgr: ->
    @trigger "showPopup", "ctxMenuManager"
  onClickSettings: ->
    @trigger "showPopup", "settings"
  onEnterCtxMenuSelMode: ->
    @$("button").attr("disabled", "disabled").addClass("disabled")
  onLeaveCtxMenuSelMode: ->
    @$("button").removeAttr("disabled").removeClass("disabled")
  onChangeLang: ->
    @$(".scHelp")
      .text("Keyboard shortcuts")
      .attr "href", @scHelpUrl + @model.get("lang")

Config = Backbone.Model.extend {}

KeyConfig = Backbone.Model.extend
  idAttribute: "new"
  defaults:
    mode: "remap"

KeyConfigSet = Backbone.Collection.extend model: KeyConfig

KeyConfigView = Backbone.View.extend

  kbdtype: null
  optionKeys: []

  # Backbone Buitin Events
  events:
    "click .origin,.new"   : "onClickInput"
    "click div.mode"       : "onClickMode"
    "click .selectMode div": "onChangeMode"
    "click .edit"          : "onClickEdit"
    "click .addCommand"    : "onClickAddCommand"
    "click .copySC"        : "onClickCopySC"
    "click div.ctxmenu"    : "onClickCtxMenu"
    "click .pause"         : "onClickPause"
    "click .resume"        : "onClickResume"
    "click .delete"        : "onClickDelete"
    "click .editSleep"     : "onClickEditSleep"
    "click input.memo,.inputSleep": "onClickInputMemo"
    "click button.cog"     : "onClickCog"
    "click .updown a"      : "onClickUpDownChild"
    "focus .new,.origin"   : "onFocusKeyInput"
    "focus .inputSleep"    : "onClickInputMemo"
    "keydown"              : "onKeydown"
    "submit  .memo"        : "onSubmitMemo"
    "submit  .formSleep"   : "onSubmitSleep"
    "blur  .selectMode"    : "onBlurSelectMode"
    "blur  .selectCog"     : "onBlurSelectCog"
    "blur  input.memo"     : "onBlurInputMemo"
    "blur  .inputSleep"    : "onBlurInputSleep"
    "mouseover"            : "onMouseOverChild"
    "mouseout"             : "onMouseOutChild"
    "mouseover .formLoadIcon": "onMouseOverLoadIcon"
    "mouseout  .formLoadIcon": "onMouseOutLoadIcon"
    #"change .loadIcon"       : "onChangeIcon"

  initialize: (options) ->
    @optionKeys = _.keys modeDisp
    @model.on
      "change:new":      @onChangeNew
      "change:bookmark": @onChangeBookmark
      "change:command":  @onChangeCommand
      "change:ctxMenu":  @onChangeCtxmenu
      "setFocus":        @onClickInput
      "remove":          @onRemove
      "setUnselectable": @onSetUnselectable
      "setRowspan":      @onSetRowspan
      "updatePosition" : @onUpdatePosition
      "setSelected":     @onSetSelected
      "getDescription":  @onGetDescription
      "triggerEventCtxMenuSelected": @onTriggerCtxMenuSelected
      @
    @model.collection.on
      "kbdEvent":        @onKbdEvent
      "changeKbd":       @onChangeKbd
      "changeLang":      @onChangeLang
      "updateOrderByEl": @onUpdateOrderByEl
      "mouseoverchild" : @onMouseOverChild
      "mouseoutchild" :  @onMouseOutChild
      @

  render: (kbdtype, lang) ->
    @kbdtype = kbdtype
    @lang = lang
    @setElement @template options: modeDisp
    mode = @model.get("mode")
    if /^C/.test @model.id
      @$el
        .addClass("child").find("th:first-child").remove().end()
        .find(".disabled").hide()
    else if !@setKbdValue(@$(".new"), @model.id)
      @state = "invalid"
    else
      @$el.find(".sleep").hide()
      @onSetRowspan()
    unless @$el.hasClass("parent") || @$el.hasClass("child")
      @$el.find(".comment").hide()
    @setKbdValue @$(".origin"), @model.get("origin")
    @onChangeMode null, mode
    @

  # Model Events
  onChangeBookmark: ->
    @onChangeMode null, "bookmark"

  onChangeCommand: ->
    @onChangeMode null, "command"

  onChangeCtxmenu: ->
    if (ctxMenu = @model.get("ctxMenu")) && !@$el.hasClass("child")
      unless ctxMenu.parentId is "route"
        @model.collection.trigger "getCtxMenuContexts", container = parentId: ctxMenu.parentId
        ctxMenu.contexts = container.contexts || ctxMenu.contexts
      @$("td.ctxmenu").html """<div class="ctxmenu-icon" title="Context menu for #{ctxMenu.contexts}\n Title: #{ctxMenu.caption}"><i class="#{tmplCtxMenus[ctxMenu.contexts][1]}"></i></div>"""
      @$("div.ctxmenu")[0].childNodes[1].nodeValue = " Edit context menu..."
    else if @model.get("mode") isnt "disabled" && !@$el.hasClass("child")
      @$("td.ctxmenu").empty()
      @$("div.ctxmenu")[0].childNodes[1].nodeValue = " Create context menu..."
    @trigger "resizeInput"

  onRemove: ->
    if parentId = @model.get "parentId"
      @model.collection.trigger "mouseoutchild", parentId
    @model.collection.off null, null, @
    @model.off null, null, @
    @off null, null, null
    @remove()

  onSetUnselectable: (unSelectable) ->
    if unSelectable
      @$el.addClass "unselectable"
    else
      @$el.removeClass "unselectable"

  onTriggerCtxMenuSelected: ->
    if @$el.hasClass("unselectable")
      @$el.removeClass "ui-selected unselectable"
    else if @$el.hasClass("ui-selected")
      @$el.removeClass "ui-selected"
      shortcut = decodeKbdEvent @model.id
      @trigger "addCtxMenu",
        id: @model.id
        caption: @getDescription() || shortcut
        shortcut: shortcut

  onSetRowspan: ->
    if (models = @model.collection.where(parentId: @model.id)).length > 0
      @$el.addClass("parent").find(".selectMode .comment").show().end().find(".disabled").hide()
      @$("th:first-child").attr "rowspan", models.length + 1
      @model.set "batch", true
    else
      @$el.removeClass("parent")
      @$("th:first-child").removeAttr "rowspan"
      @model.unset "batch"
      unless @$el.hasClass "child"
        @$(".selectMode .comment").hide().end().find(".disabled").show()
        @$("ul.updown").remove()

  onSetSelected: (selected) ->
    if selected
      @$el.addClass "ui-selected"
    else
      @$el.removeClass "ui-selected"

  onGetDescription: (container) ->
    container.desc = @getDescription()

  onChangeNew: (model) ->
    andy.changePK @model.id, model.previous("new")

  # Collection Events
  onKbdEvent: (value) ->
    input$ = @$("div:focus")
    if input$.length > 0
      if input$.hasClass "new"
        if @model.id isnt value && @model.collection.findWhere(new: value)
          $("#tiptip_content").text("\"#{decodeKbdEvent(value)}\" already exists.")
          input$.tipTip()
          return
        @model.collection.where(parentId: @model.id).forEach (child) ->
          child.set "parentId", value
      else # Origin
        scanCode = ~~value.substring(2)
        if scanCode >= 0x200 || scanCode is 0x15D
          return
      @setKbdValue input$, value
      @model.set input$[0].className.match(/(new|origin)/)[0], value
      @setDesc()
      @trigger "resizeInput"
      if input$.hasClass("new") && @model.has("ctxMenu")
        @trigger "remakeCtxMenu", dfd: $.Deferred()

  onChangeKbd: (kbdtype) ->
    @kbdtype = kbdtype
    @setKbdValue @$(".new"), @model.id
    @setKbdValue @$(".origin"), @model.get("origin")

  onChangeLang: (lang) ->
    @lang = lang
    @setDesc()

  onUpdateOrderByEl: ->
    @model.set "order", @$el.parent().children().index(@$el)

  onUpdatePosition: ->
    @$el.parent()[0].insertBefore @el, (@$el.parent().children().eq(@model.get("order")).get(0) || null)

  # DOM Events
  onKeydown: (event) ->
    if event.target.tagName in ["TEXTAREA", "INPUT", "SELECT"]
      return
    if @$("div:focus").hasClass("new")
      @trigger "getConfigValue", "singleKey", container = {}
      unless container.result
        return
    if keynames = keyIdentifiers[@kbdtype][event.originalEvent.keyIdentifier]
      if event.originalEvent.shiftKey
        unless keyname = keynames[1]
          return
        scCode = "04"
      else
        keyname = keynames[0]
        scCode = "00"
      for i in [0...keys.length]
        if keys[i] && (keyname is keys[i][0] || keyname is keys[i][1])
          scanCode = i
          break
      if scanCode
        @onKbdEvent(scCode + i)

  onClickCopySC: (event) ->
    if (mode = @model.get("mode")) is "through"
      mode = @model.get "lastMode"
    if (children = @model.collection.where parentId: @model.id).length > 0
      mode = "batch"
    if mode is "remap"
      method = "keydown"
      scCode = @model.get("origin")
      desc = @$(".desc").find(".content,.memo").text()
    else
      method = "send"
      scCode = @model.id
      desc = @$(".desc").find(".content,.command,.commandCaption,.bookmark,.memo").text()
    command = @$("td.options .mode").text().replace "Remap", ""
    command = " " + command + ":" if command
    keyCombo = (decodeKbdEvent scCode).replace /\s/g, ""
    desc = " " + desc if desc
    body = "scd.#{method}('#{transKbdEvent(scCode)}');"
    text = body + " /* " + keyCombo + command + desc + " */"
    chrome.runtime.sendMessage
      action: "setClipboard"
      value1: text
      (msg) ->

  getDescription: ->
    if @model.get("mode") is "remap"
      desc = @$(".desc").find(".content,.memo").text()
    else
      desc = @$(".desc").find(".content,.command,.commandCaption,.bookmark,.memo").text().replace(/\s+/g, " ")
    $.trim(desc)

  onClickCtxMenu: ->
    @trigger "showPopup", "ctxMenuOptions", @model.id

  onClickInputMemo: (event) ->
    event.stopPropagation()
    #event.preventDefault()

  onSubmitMemo: ->
    @$("form.memo").hide()
    @model.set "memo": @$("div.memo").show().html(escape @$("input.memo").val()).text()
    endEdit()
    false

  onClickMode: (event) ->
    if event.currentTarget.getAttribute("title") is "Pause"
      return
    if @$(".selectMode").toggle().is(":visible")
      @$(".selectMode").focus()
      @$(".mode").addClass("selecting")
    else
      @$(".mode").removeClass("selecting")
    event.stopPropagation()

  onChangeMode: (event, mode) ->
    if event
      @$(".mode").removeClass("selecting")
      mode = event.currentTarget.className
      @$(".selectMode").hide()
      if mode in ["bookmark", "command"]
        @trigger "showPopup", mode, @model.id
        return
    @model.set "mode", mode
    @setDispMode mode
    @setDesc()
    @trigger "resizeInput"

  onBlurSelectMode: ->
    @$(".selectMode").hide()
    @$(".mode").removeClass("selecting")

  onFocusKeyInput: ->
    lastFocused = @el

  onClickInput: (event, selector) ->
    if (event)
      $(event.currentTarget).focus()
    else if selector
      @$(selector).focus()
    else
      @$(".origin").focus()
    event?.stopPropagation()

  onBlurInputMemo: ->
    @onSubmitMemo()

  onClickCog: (event) ->
    if @$(".selectCog").toggle().is(":visible")
      @$(".selectCog").focus()
      $(event.currentTarget).addClass("selecting")
    else
      $(event.currentTarget).removeClass("selecting")
    event.stopPropagation()

  onBlurSelectCog: ->
    if @loadIconHovered
      setTimeout((->
        @$(".selectCog").hide()
        @$("button.cog").removeClass("selecting")
      ), 1000)
    else
      @$(".selectCog").hide()
      @$("button.cog").removeClass("selecting")

  onClickEdit: (event) ->
    if (mode = @model.get "mode") is "through"
      mode = @model.get "lastMode"
    switch mode
      when "bookmark"
        @trigger "showPopup", "bookmarkOptions", @model.id
      when "command"
        if @model.get("command").name is "openExtProg"
          @trigger "showPopup", "optionExtProg", @model.id
        else
          @trigger "showPopup", "commandOptions", @model.id
      else #when "remap", "through", "disabled"
        (memo = @$("div.memo")).toggle()
        editing = (input$ = @$("form.memo").toggle().find("input.memo")).is(":visible")
        if editing
          input$.focus().val memo.text()
          startEdit()
        else
          @onSubmitMemo()
        event.stopPropagation()

  onClickAddCommand: ->
    if /^C/.test(parentId = @model.get("new"))
      parentId = @model.get "parentId"
    lastFocused = @el
    @model.collection.add
      "new": getUuid("C")
      "origin": if ~~parentId.substring(2) >= 0x200 then "0130" else parentId
      "parentId": parentId
    if @$el.hasClass "parent"
      @setDispMode @model.get "mode"
      unless @$("ul.updown").length > 0
        @$(".desc").append @tmplUpDown

  onMouseOverChild: (event, id) ->
    if id is @model.id
      @$el.addClass "hover"
    if event && (parentId = @model.get "parentId")
      @model.collection.trigger "mouseoverchild", null, parentId

  onMouseOutChild: (event, id) ->
    if id is @model.id
      @$el.removeClass "hover"
    if event && (parentId = @model.get "parentId")
      @model.collection.trigger "mouseoutchild", null, parentId

  onClickPause: ->
    @model.set("lastMode", @model.get("mode"))
    @onChangeMode(null, "through")
    if ctxMenu = @model.get "ctxMenu"
      andy.updateCtxMenu @model.id, ctxMenu, true

  onClickResume: ->
    @onChangeMode(null, @model.get("lastMode"))
    if ctxMenu = @model.get "ctxMenu"
      andy.updateCtxMenu @model.id, ctxMenu, false

  onClickDelete: ->
    if parentId = @model.get "parentId"
      switch @model.get("mode")
        when "remap"
          desc = "Shortcut key: " + decodeKbdEvent(@model.get "origin") + "\n Description: \"#{@getDescription()}\""
        when "sleep"
          desc = "Sleep " + @model.get("sleep") + " msec"
        else
          desc = "Description: \"#{@getDescription()}\""
      children = []
      msg = "Are you sure you want to delete this child command?\n\n " + desc
    else
      if (children = @model.collection.where(parentId: @model.id)).length > 0
        msg = "Are you sure you want to delete this shortcut and all child commands?"
      else
        msg = "Are you sure you want to delete this shortcut?"
      shortcut = decodeKbdEvent @model.id
      msg += "\n\n Shortcut key: #{shortcut}\n Description: \"#{@getDescription()}\""
    if confirm msg
      children.forEach (child) =>
        @trigger "removeConfig", child
      collection = @model.collection
      @trigger "removeConfig", @model
      if parentId
        collection.get(parentId).trigger "setRowspan"
    else
      @$(".selectCog").blur()

  onClickUpDownChild: (event) ->
    changeParent = ->
      childId = childModel.id
      childModel.set "new", "temp"
      childModel.unset "parentId"
      parentModel.set "new", childId
      parentModel.set "parentId", parentId
      childModel.set "new", parentId
      newParent$.removeClass("child").find(".disabled").show().end()
        .prepend(newChild$.find("th:first-child"))
        .find("td.ctxmenu").append(newChild$.find("div.ctxmenu-icon")).end()
        .find(".desc").find(".ctxmenu,.copySC").show()
      newChild$
        .removeClass("parent hover").addClass("child").find(".disabled").hide().end()
        .find(".desc").find(".ctxmenu,.copySC").hide()
      if ctxMenu = parentModel.get("ctxMenu")
        childModel.set "ctxMenu", ctxMenu
        parentModel.unset "ctxMenu"
      if childModel.get("mode") is "through"
        newParent$.find(".new").addClass "through"
      else
        newParent$.find(".new").removeClass "through"
    order = -1
    parentId = @model.get("parentId") || @model.id
    models = [parentModel = @model.collection.get(parentId)].concat @model.collection.where(parentId: parentId)
    $.each models, (i, model) =>
      if model.id is @model.id
        order = i
        false
    if event.currentTarget.title is "up" && order > 0
      (newChild$ = @$el.prev()).before newParent$ = @$el
      if order is 1
        childModel = @model
        changeParent()
      @trigger "updateChildPos"
    else if event.currentTarget.title is "down" && models.length > (order + 1)
      (newChild$ = @$el).before (newParent$ = @$el.next())
      if order is 0
        childModel = models[1]
        changeParent()
      @trigger "updateChildPos"

  onClickEditSleep: ->
    @$(".dispSleep").hide()
    @$(".inputSleep").show().val(@model.get "sleep")
    setTimeout((=> @$(".inputSleep").focus()), 0)

  onSubmitSleep: ->
    value = (inputSleep = @$(".inputSleep")).val() || 100
    minValue = inputSleep.attr("min")
    maxValue = inputSleep.attr("max")
    type = /(Sleep|Zoom)/.exec((dispSleep = @$(".dispSleep").show()).attr("title"))[0]
    value = Math.round(Math.min(Math.max(minValue, value), maxValue))

    if type is "Sleep"
      title = "Sleep #{value} msec"
    else if /^Zooms /.test type
      title = "Zooms  #{value} %"

    @$(".dispSleep").show().html(value).attr "title", title
    @model.set "sleep": value
    @$(".inputSleep").hide()
    false

  onBlurInputSleep: ->
    @onSubmitSleep()

  onMouseOverLoadIcon: ->
    @loadIconHovered = true

  onMouseOutLoadIcon: ->
    @loadIconHovered = false

  onChangeIcon: ->
    files = @$(".loadIcon").get(0).files
    if files and files.length
      file = files[0]
      if file.size > 32000
        alert "Max file size is 32KB"
      else if /image\/png/.test(file.type)
        reader = new FileReader()
        reader.onload = (e) =>
          @$(".toolbarIcon").attr "src", e.target.result
        reader.readAsDataURL file
      else
        alert "Not a png image."
    @$(".loadIcon").replaceWith "<input type=\"file\" class=\"loadIcon\" />"

  # Object Method
  setDispMode: (mode) ->
    @$(".mode")
      .attr("title", modeDisp[mode][0].replace("...", ""))
      .find(".icon")[0].className = "icon " + modeDisp[mode][1]
    if mode is "through"
      mode = @model.get("lastMode") + " through"
    @$(".new,.origin,.icon-arrow-right")
      .removeClass(@optionKeys.join(" "))
      .addClass mode
    if /remap/.test mode
      @$("th:first,th:eq(1)").removeAttr("colspan").css("padding", "").find("i").show()
      @$("th:eq(1),th:eq(2),th .origin").show().find("i").show()
    else
      if @$el.hasClass "child"
        @$("th:first").css("padding", "16px 0").find("i").hide()
        @$("th .origin").hide()
      else if @$el.hasClass "parent"
        @$("th:first").removeAttr("colspan")
        @$("th:eq(1),th:eq(2)").show()
        @$("th:eq(1)").css("padding", "18px 0").find("i").hide()
        @$("th .origin").hide()
      else
        @$("th:first").attr("colspan", "3")
        @$("th:eq(1),th:eq(2)").hide()

  setKbdValue: (input$, value) ->
    if value is "00768"
      input$.html """<span title="Toolbar Button"><img src="images/toolbarIcon.png" class="toolbarIcon"></span>"""
      true
    else if result = decodeKbdEvent value
      input$.html _.map(result.split(" + "), (s) -> "<span>#{s}</span>").join("+")
      true
    else
      false

  setDesc: ->
    (tdDesc = @$(".desc")).empty()
    editOption = iconName: "", command: ""
    if (mode = @model.get("mode")) is "through"
      pause = true
      mode = @model.get "lastMode"
    switch mode
      when "sleep"
        unless sleep = @model.get("sleep")
          @model.set "sleep", sleep = 100
        tdDesc.append @tmplSleep sleep: sleep
      when "bookmark"
        bookmark = @model.get("bookmark")
        tdDesc.append @tmplBookmark
          openmode: bmOpenMode[bookmark.openmode]
          url: bookmark.url
          title: bookmark.title
        editOption = iconName: "icon-pencil", command: "Edit bookmark..."
      when "command"
        desc = (commandDisp = commandsDisp[commandName = (command = @model.get("command")).name])[1]
        if commandDisp[2]
          content3row = []
          #command = @model.get("command")
          lines = command.content?.split("\n") || []
          for i in [0...lines.length]
            if i > 2
              content3row[i-1] += " ..."
              break
            else
              content3row.push lines[i].replace(/"/g, "'")
          tdDesc.append @tmplCommandCustom
            ctg: commandDisp[3]
            desc: desc
            content3row: content3row.join("\n")
            caption: command.caption
          editOption = iconName: "icon-pencil", command: "Edit command..."
        else if commandName is "zoomFixed"
          unless zoom = @model.get("sleep")
            @model.set "sleep", zoom = 100
          tdDesc.append @tmplZoomFixed
            zoom: zoom
        else if commandName is "zoomInc"
          unless zoom = @model.get("sleep")
            @model.set "sleep", zoom = 10
          tdDesc.append @tmplZoomInc
            zoom: zoom
        else
          tdDesc.append @tmplCommand desc: desc, ctg: commandDisp[0].substring(0,1).toUpperCase() + commandDisp[0].substring(1)
      when "remap", "disabled"
        if mode is "remap"
          keycombo = @$(".origin").text()
        else
          keycombo = @$(".new").text()
        keycombo = (keycombo.replace /\s/g, "").toUpperCase()
        unless help = scHelp[keycombo]
          if /^CTRL\+[2-7]$/.test keycombo
            help = scHelp["CTRL+1"]
        if help　&& help[@lang]
          for i in [0...help[@lang].length]
            test = help[@lang][i].match /(^\w+)\^(.+)/
            key = RegExp.$1
            content = RegExp.$2
            tdDesc.append(@tmplHelp
                sectDesc: scHelpSect[key]
                sectKey:  key
                scHelp:   content
              ).find(".sectInit").tooltip position: {my: "left+10 top-60"}, tooltipClass: "tooltipClass"
    if tdDesc.html() is ""
      tdDesc.append @tmplMemo memo: @model.get("memo")
      editOption = iconName: "icon-pencil", command: "Edit description"
    tdDesc.append @tmplDesc editOption
    if mode is "disabled"
      @$(".addKey,.copySC,.seprater.1st,div.ctxmenu,.addCommand").hide()
    if editOption.iconName is ""
      tdDesc.find(".edit").hide()
    if pause
      tdDesc.find(".pause").hide()
    else
      tdDesc.find(".resume").hide()
    if @model.get("new") is "00768"
      tdDesc.find(".ctxmenu").hide()
      #tdDesc.find(".menuChangeIcon").show().html """
      #    <form class="formLoadIcon">
      #      <input type="file" class="loadIcon">
      #      <div class="changeIcon"><i class="fa fa-refresh"></i> Change toolbar icon(.png)...</div>
      #    </form>
      #  """
    if @$el.hasClass "child"
      tdDesc.find(".ctxmenu,.copySC").hide()
    if @$el.hasClass("child") || @$el.hasClass("parent")
      tdDesc.append @tmplUpDown
    if @model.get("new") is "00768"
      @model.set "title", @getDescription()

    @onChangeCtxmenu()

  tmplDesc: _.template """
    <button class="cog small" title="menu"><i class="icon-caret-down"></i></button>
    <div class="selectCog" tabIndex="0">
      <div class="edit"><i class="<%=iconName%>"></i> <%=command%></div>
      <div class="addCommand"><i class="icon-plus"></i> Add command</div>
      <div class="ctxmenu"><i class="icon-reorder"></i> Create context menu...</div>
      <!--<div class="copySC"><i class="icon-copy"></i> Copy script</div>-->
      <div class="menuChangeIcon"></div>
      <span class="seprater 1st"><hr style="margin:3px 1px" noshade></span>
      <div class="pause"><i class="icon-pause"></i> Pause</div>
      <div class="resume"><i class="icon-play"></i> Resume</div>
      <span class="seprater"><hr style="margin:3px 1px" noshade></span>
      <div class="delete"><i class="icon-trash"></i> Delete</div>
    </div>
    """

  tmplUpDown: """
    <ul class="button-bar updown">
      <li class="first"><a href="#" title="up"><i class="icon-chevron-up"></i></a></li>
  	  <li class="last"><a href="#" title="down"><i class="icon-chevron-down"></i></a></li>
  	</ul>
    """

  tmplMemo: _.template """
    <form class="memo">
      <input type="text" class="memo">
    </form>
    <div class="memo"><%=memo%></div>
    """

  tmplSleep: _.template """
    <form class="formSleep">
      <div class="floatL">Sleep&nbsp;</div>
      <input type="number" class="inputSleep" min="0" max="60000" step="10" required>
      <span class="dispSleep" title="Sleep <%=sleep%> msec"><%=sleep%></span>&nbsp;msec
      <i class="icon-pencil editSleep" title="Edit sleep msec(0-60000)"></i>
    </form>
    """

  tmplZoomFixed: _.template """
    <div class="ctgIcon Tab">Tab</div><div class="command">
      <form class="formSleep">
        <div class="floatL">Zoom page&nbsp;</div><input type="number" class="inputSleep" min="25" max="500" step="1" required>
        <span class="dispSleep" title="Zoom page <%=zoom%> %"><%=zoom%></span>&nbsp;%
        <i class="icon-pencil editSleep" title="Edit zoom factor % between 25 and 500"></i>
      </form>
    </div>
    """
  tmplZoomInc: _.template """
    <div class="ctgIcon Tab">Tab</div><div class="command">
      <form class="formSleep">
        <div class="floatL">Zoom page - increments&nbsp;</div><input type="number" class="inputSleep" min="-100" max="100" step="1" required>
        <span class="dispSleep" title="Zoom page - increments <%=zoom%> %"><%=zoom%></span>&nbsp;%
        <i class="icon-pencil editSleep" title="Edit increments % between -100 and 100"></i>
      </form>
    </div>
    """

  tmplBookmark: _.template """
    <div class="bookmark" title="<%=url%>\n[<%=openmode%>]" style="background-image:-webkit-image-set(url(chrome://favicon/size/16@1x/<%=url%>) 1x);"><%=title%></div>
    """

  tmplCommand: _.template """<div class="ctgIcon <%=ctg%>"><%=ctg%></div><div class="command"><%=desc%></div>"""

  tmplCommandCustom: _.template """
    <div class="ctgIcon <%=ctg%>" title="<%=desc%>"><%=ctg%></div><div class="commandCaption" title="<%=content3row%>"><%=caption%></div>
    """

  tmplHelp: _.template """
    <div class="sectInit" title="<%=sectDesc%>"><%=sectKey%></div><div class="content"><%=scHelp%></div>
    """

  template: _.template """
    <tr class="data">
      <th>
        <div class="new" tabIndex="0"></div>
        <div class="grpbartop"></div>
        <div class="grpbarbtm"></div>
      </th>
      <th>
        <i class="icon-arrow-right"></i>
      </th>
      <th class="tdOrigin">
        <div class="origin" tabIndex="-1"></div>
      </th>
      <td class="options">
        <div class="mode"><i class="icon"></i><span></span><i class="icon-caret-down"></i></div>
        <div class="selectMode" tabIndex="0">
          <% _.each(options, function(option, key) { if (option[2] != "nodisp") { %>
          <div class="<%=key%>"><i class="icon <%=option[1]%>"></i> <%=option[0]%></div>
          <% }}); %>
        </div>
      <td class="ctxmenu"></td>
      <td class="desc"></td>
      <td class="blank">&nbsp;</td>
    </tr>
    """

KeyConfigSetView = Backbone.View.extend
  placeholder: "Enter new shortcut key"

  # Backbone Buitin Events
  el: "table.keyConfigSetView"

  events:
    "click .addnew": "onClickAddnew"
    "blur  .addnew": "onBlurAddnew"
    "click"        : "onClickBlank"
    "click .scrollEnd i": "onClickScrollEnd"

  initialize: (options) ->
    @model.on "change:lang"   , @onChangeLang   , @
    @model.on "change:kbdtype", @onChangeKbdtype, @
    @collection.comparator = (model) ->
      model.get "order"
    @collection.on
      add:      @onAddRender
      kbdEvent: @onKbdEvent
      @

  render: (keyConfigSet) ->
    @$el.append @template()
    @collection.set keyConfigSet
    @$("tbody").sortable
      delay: 300
      scroll: true
      cancel: "tr.border,tr.child,input"
      placeholder: "ui-placeholder"
      forceHelperSize: true
      forcePlaceholderSize: true
      cursor: "move"
      start: =>
        @onStartSort()
      stop: (event, ui) =>
        @redrawTable()
        ui.item.effect("highlight", 1500)[0].scrollIntoViewIfNeeded true
    $(".fixed-table-container-inner")
      .on "scroll", (event) ->
        #console.log @scrollTop + ": " + (@scrollHeight - @offsetHeight)
        if @scrollTop < 10
          $(".header-background").removeClass("scrolling")
        else
          $(".header-background").addClass("scrolling")
          $(".scrollEnd").show()
        if @scrollTop + 120 > @scrollHeight - @offsetHeight
          $(".footer").removeClass("scrolling")
        else
          $(".footer").addClass("scrolling")
          $(".scrollEnd").show()
      .niceScroll
        #cursorcolor: "#1E90FF"
        cursorwidth: 13
        cursorborderradius: 2
        smoothscroll: true
        cursoropacitymin: .3
        cursoropacitymax: .7
        zindex: 999998
    @niceScroll = $(".fixed-table-container-inner").getNiceScroll()
    loading = false
    @redrawTable()
    @

  # Collection Events
  onAddRender: (model) ->
    keyConfigView = new KeyConfigView(model: model)
    keyConfigView.on "removeConfig"  , @onChildRemoveConfig, @
    keyConfigView.on "resizeInput"   , @onChildResizeInput , @
    keyConfigView.on "showPopup"     , @onShowPopup        , @
    keyConfigView.on "addCtxMenu"    , @onAddCtxMenu       , @
    keyConfigView.on "updateChildPos", @redrawTable        , @
    keyConfigView.on "remakeCtxMenu" , @onRemakeCtxMenu    , @
    keyConfigView.on "getConfigValue", @onGetConfigValue   , @
    divAddNew = @$("tr.addnew")[0] || null
    tbody = @$("tbody")[0]
    if /^C/.test(model.id) && lastFocused
      divAddNew = lastFocused.nextSibling || null
    tbody.insertBefore keyConfigView.render(@model.get("kbdtype"), @model.get("lang")).el, divAddNew
    tbody.insertBefore $(@tmplBorder)[0], divAddNew
    if keyConfigView.state is "invalid"
      @onChildRemoveConfig model
    if divAddNew || /^C/.test(model.id) && !loading
      @$("div.addnew").blur()
      @redrawTable()
    if /^C/.test(model.id) && lastFocused
      lastFocused = null
      @collection.get(model.get "parentId").trigger "setRowspan"
      setTimeout((-> model.trigger "setFocus"), 0)

  onKbdEvent: (value) ->
    if @$(".addnew").length is 0
      if (target = @$(".new:focus,.origin:focus")).length is 0
        if model = @collection.get(value)
          model.trigger "setFocus", null, ".new"
          return
        else
          unless @onClickAddKeyConfig()
            return
      else
        return
    if @collection.findWhere(new: value)
      $("#tiptip_content").text("\"#{decodeKbdEvent(value)}\" already exists.")
      @$("div.addnew").tipTip()
      return
    @collection.add newitem = new KeyConfig
      new: value
      origin: if ~~value.substring(2) >= 0x200 then "0130" else value
    @$("tbody")
      .sortable("enable")
      .sortable("refresh")
    windowOnResize()
    @onChildResizeInput()
    newitem.trigger "setFocus"

  # Child Model Events
  onChildRemoveConfig: (model) ->
    @collection.remove model
    @redrawTable()
    windowOnResize()
    @onChildResizeInput()

  onChildResizeInput: ->
    @$(".th_inner").css("left", 0)
    setTimeout((=> @$(".th_inner").css("left", "")), 0)

  onShowPopup: (name, id) ->
    @trigger "showPopup", name, id

  onRemakeCtxMenu: (container) ->
    andy.remakeCtxMenu(@getSaveData(), container.rootTitle).done ->
      container.dfd.resolve()

  onAddCtxMenu: (ctxMenu) ->
    @trigger "addCtxMenu", ctxMenu

  onTriggerEventSelected: ->
    @collection.models.forEach (model) ->
      model.trigger "triggerEventCtxMenuSelected"
    @redrawTable()

  onSetCtxMenus: (ctxMenus) ->
    @collection.models.forEach (model) ->
      model.unset("ctxMenu")
    ctxMenus.forEach (ctxMenu) =>
      model = @collection.get ctxMenu.id
      model.set "ctxMenu", ctxMenu

  onGetCtxMenues: (container) ->
    container.ctxMenus = []
    @collection.models.forEach (model) ->
      if ctxMenu = model.get "ctxMenu"
        container.ctxMenus.push
          id: model.id
          caption: ctxMenu.caption
          contexts: ctxMenu.contexts
          parentId: ctxMenu.parentId
          shortcut: decodeKbdEvent model.id
          order: ctxMenu.order || 999
    container.ctxMenus.sort (a, b) -> a.order - b.order

  onEnterCtxMenuSelMode: (entried) ->
    @$("button").attr("disabled", "disabled").addClass("disabled")
    @collection.models.forEach (model) ->
      model.trigger "setUnselectable", if model.id in entried then true else false
    @$("tbody")
      .sortable("disable")
      .selectable
        cancel: "tr:has(div.ctxmenu-icon)"
        filter: "tr"
      .find("tr:has(div.mode[title='Disabled'])").addClass("unselectable").end()
      .find("tr:has(div.ctxmenu-icon)").addClass("unselectable").end()
      .find("div.mode,div.new,div.origin").addClass("unselectable").end()
    @onStartSort()

  onLeaveCtxMenuSelMode: (cancel) ->
    @$("button").removeAttr("disabled").removeClass("disabled")
    @$("tbody")
      .selectable("destroy")
      .sortable("enable")
      .find("div.unselectable").removeClass("unselectable").end()
    if cancel
      @$("tr").removeClass("ui-selected unselectable")
      @redrawTable()

  onGetEditerSize: (container) ->
    if editerSize = @model.get "editerSize"
      container.width = editerSize.width
      container.height = editerSize.height

  onSetEditerSize: (width, height) ->
    @model.set "editerSize",
      width:  width
      height: height

  onGetSaveData: (container) ->
    container.data = @getSaveData()

  onSetSaveData: (newData) ->
    @collection.remove @collection.findWhere new: @placeholder
    @model.set newData.config
    ctxMenuManagerView.collection.reset newData.ctxMenuFolderSet
    while model = @collection.at(0)
      @collection.remove(model)
    loading = true
    @collection.set newData.keyConfigSet
    @redrawTable()
    @collection.models.forEach (model) ->
      if model.get("mode") is "command"
        command = model.get("command")
        if command.name is "execJS" && command.coffee
          andy.coffee2JS model.get("new"), command.content
    andy.remakeCtxMenu @getSaveData()
    loading = false
    windowOnResize()

  onGetConfigValue: (key, container) ->
    container.result = @model.get(key)

  # DOM Events
  onClickScrollEnd: (event) ->
    scrollable = $(".fixed-table-container-inner")
    if /icon-double-angle-up/.test event.target.className
      scrollTop = 0
    else
      scrollTop = scrollable[0].scrollHeight
    scrollable.animate {scrollTop: scrollTop}, 200

  onKeyDown: (event) ->
    unless @model.get "singleKey"
      return
    if (elActive = document.activeElement) && (elActive.tagName in ["TEXTAREA", "INPUT", "SELECT"])
      return
    if keynames = keyIdentifiers[@model.get "kbdtype"][event.originalEvent.keyIdentifier]
      if event.originalEvent.shiftKey
        unless keyname = keynames[1]
          return
        scCode = "04"
      else
        keyname = keynames[0]
        scCode = "00"
      for i in [0...keys.length]
        if keys[i] && (keyname is keys[i][0] || keyname is keys[i][1])
          scanCode = i
          break
      if scanCode
        @onKbdEvent(scCode + i)

  onClickAddKeyConfig: (event) ->
    if @$(".addnew").length > 0
      return
    if @collection.length > gMaxItems
      $("#tiptip_content").text("You have reached the maximum number of items. (Max #{gMaxItems} items)")
      $(event.currentTarget).tipTip defaultPosition: "bottom"
      return false
    newItem$ = $(@tmplAddNew placeholder: @placeholder)
    if /child/.test lastFocused?.className
      lastFocused = $(lastFocused).prevAll(".parent:first")[0]
    @$("tbody")[0].insertBefore newItem$[0], lastFocused
    newItem$.find(".addnew").focus()[0].scrollIntoViewIfNeeded()
    @$("tbody").sortable "disable"
    windowOnResize()

  onClickBlank: ->
    @$(":focus").blur()
    lastFocused = null

  onClickAddnew: (event) ->
    event.stopPropagation()

  onBlurAddnew: ->
    @$(".addnew").remove()
    @$("tbody").sortable "enable"
    windowOnResize()

  onChangeLang: ->
    @collection.trigger "changeLang", @model.get("lang")

  onChangeKbdtype: ->
    @collection.trigger "changeKbd", @model.get("kbdtype")

  onStartSort: ->
    @$("tr.child").hide()
    @$(".ui-placeholder").nextAll("tr.border:first,tr.border:last").remove()
    @$(".parent th:first-child").removeAttr "rowspan"

  # Object Method
  redrawTable: ->
    @$("tr.child").show()
    @$("tr.border").remove()
    @collection.models.forEach (model) =>
      model.trigger "setRowspan"
    $("#sortarea").append @$("tr.data")
    @collection.trigger "updateOrderByEl"
    @collection.sort()
    @collection.models.forEach (model) =>
      if parentId = model.get "parentId"
        model.set "order", 999
    @collection.sort()
    @collection.models.forEach (model) =>
      if parentId = model.get "parentId"
        model.set "order", @collection.get(parentId).get("order")
    @collection.sort()
    $.each @collection.models, (i, model) =>
      model.set "order", i
      model.trigger "updatePosition"
    $.each $("#sortarea tr"), (i, tr) =>
      @$("tbody").append tr
    @$("tr.last").removeClass "last"
    $.each @$("tbody > tr"), (i, tr) =>
      unless /child/.test tr.nextSibling?.className
        (tr$ = $(tr)).after @tmplBorder
        if /child/.test tr.className
          tr$.addClass "last"

  getSaveData: ->
    @collection.remove @collection.findWhere new: @placeholder
    config: @model.toJSON()
    ctxMenuFolderSet: ctxMenuManagerView.collection.sort().toJSON()
    keyConfigSet: @collection.toJSON()

  tmplAddNew: _.template """
    <tr class="addnew">
      <th colspan="3">
        <div class="new addnew" tabIndex="0"><%=placeholder%></div>
      </th>
      <td></td><td></td><td></td><td class="blank"></td>
    </tr>
    """

  tmplBorder: """
    <tr class="border">
      <td colspan="6"><div class="border"></div></td>
      <td></td>
    </tr>
    """

  template: _.template """
    <thead>
      <tr>
        <th>
          <div class="th_inner">Shortcut key [<i class="icon-arrow-right"></i> Dest key ]</div>
        </th>
        <th></th>
        <th></th>
        <th>
          <div class="th_inner options">Mode</div>
        </th>
        <th class="ctxmenu"></th>
        <th>
          <div class="th_inner desc">Description</div>
          <div class="scrollEnd top"><i class="icon-double-angle-up" title="Scroll to Top"></i></div>
          <div class="scrollEnd bottom"><i class="icon-double-angle-down" title="Scroll to Bottom"></i></div>
        </th>
      </tr>
    </thead>
    <tbody></tbody>
    """

Router = Backbone.Router.extend
  initialize: (options) ->
    {@collection} = options
    @popupType =
      "bookmark"       : "popup"
      "command"        : "popup"
      "bookmarkOptions": "editable"
      "commandOptions" : "editable"
      "optionExtProg"  : "editable"
      "ctxMenuOptions" : "editable"
      "ctxMenuManager" : "editable"
      "settings"       : "editable"
  routes:
    "popup/:name(/:id)(/:option1)(/:option2)"   : "showPopup"
    "editable/:name(/:id)(/:option1)(/:option2)": "showPopup"
    "(:any)": "onNavigateRootPage"
  showPopup: (name, id, option1, option2) ->
    if id
      model = @collection.get id
    @trigger "showPopup", name, model, option1, option2
  onNavigateRootPage: ->
    @navigate "/"
    @trigger "hidePopup"
  onNavigatePopup: (name, id) ->
    params = ""
    Array.prototype.slice.call(arguments, 1).forEach (param) ->
      params += "/" + param if param
    @navigate @popupType[name] + "/" + name + params, {trigger: true}

marginBottom = 0
resizeTimer = false
windowOnResize = ->
  if resizeTimer
    clearTimeout resizeTimer
  resizeTimer = setTimeout((->
    tableHeight = window.innerHeight - document.querySelector(".header").offsetHeight - marginBottom
    document.querySelector(".fixed-table-container").style.height = tableHeight + "px"
    $(".fixed-table-container-inner").getNiceScroll().resize()
    $(".result_outer").getNiceScroll().resize()
  ), 200)

startEdit = ->
  andy.startEdit()
  return

endEdit = ->
  andy.endEdit()
  return

andy = chrome.extension.getBackgroundPage().andy

$ = jQuery
$ ->
  keyCodes = andy.getKeyCodes()
  scHelp   = andy.getScHelp()
  scHelpSect = andy.getScHelpSect()
  saveData = andy.local

  config = new Config saveData.config
  keyConfigSet = new KeyConfigSet()

  router = new Router
    collection: keyConfigSet

  headerView = new HeaderView
    model: config

  settingsView = new SettingsView
    model: config

  keyConfigSetView = new KeyConfigSetView
    model: config
    collection: keyConfigSet

  new BookmarksView {}
  new BookmarkOptionsView {}
  new CommandsView {}
  commandOptionsView = new CommandOptionsView {}
  new OptionExtProgView {}
  ctxMenuFolderSet = new CtxMenuFolderSet()
  ctxMenuOptionsView = new CtxMenuOptionsView
    collection: ctxMenuFolderSet
  ctxMenuManagerView = new CtxMenuManagerView
    model: config
    collection: ctxMenuFolderSet

  headerView.on         "showPopup"           , router.onNavigatePopup                 , router
  keyConfigSetView.on   "showPopup"           , router.onNavigatePopup                 , router
  headerView.on         "clickAddKeyConfig"   , keyConfigSetView.onClickAddKeyConfig   , keyConfigSetView
  ctxMenuOptionsView.on "getCtxMenues"        , keyConfigSetView.onGetCtxMenues        , keyConfigSetView
  ctxMenuOptionsView.on "remakeCtxMenu"       , keyConfigSetView.onRemakeCtxMenu       , keyConfigSetView
  ctxMenuManagerView.on "getCtxMenues"        , keyConfigSetView.onGetCtxMenues        , keyConfigSetView
  ctxMenuManagerView.on "remakeCtxMenu"       , keyConfigSetView.onRemakeCtxMenu       , keyConfigSetView
  keyConfigSet.on       "getCtxMenuContexts"  , ctxMenuManagerView.onGetCtxMenuContexts, ctxMenuManagerView
  ctxMenuManagerView.on "enterCtxMenuSelMode" , keyConfigSetView.onEnterCtxMenuSelMode , keyConfigSetView
  ctxMenuManagerView.on "enterCtxMenuSelMode" , headerView.onEnterCtxMenuSelMode       , headerView
  ctxMenuManagerView.on "leaveCtxMenuSelMode" , keyConfigSetView.onLeaveCtxMenuSelMode , keyConfigSetView
  ctxMenuManagerView.on "leaveCtxMenuSelMode" , headerView.onLeaveCtxMenuSelMode       , headerView
  ctxMenuManagerView.on "triggerEventSelected", keyConfigSetView.onTriggerEventSelected, keyConfigSetView
  ctxMenuManagerView.on "setCtxMenus"         , keyConfigSetView.onSetCtxMenus         , keyConfigSetView
  commandOptionsView.on "getEditerSize"       , keyConfigSetView.onGetEditerSize       , keyConfigSetView
  commandOptionsView.on "setEditerSize"       , keyConfigSetView.onSetEditerSize       , keyConfigSetView
  settingsView.on       "getSaveData"         , keyConfigSetView.onGetSaveData         , keyConfigSetView
  settingsView.on       "setSaveData"         , keyConfigSetView.onSetSaveData         , keyConfigSetView

  ctxMenuFolderSet.reset  saveData.ctxMenuFolderSet
  keyConfigSetView.render saveData.keyConfigSet

  chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
    switch request.action
      when "kbdEvent"
        keyConfigSetView.collection.trigger "kbdEvent", request.value
      when "saveConfig"
        andy.saveConfig keyConfigSetView.getSaveData()

  $(window)
    .on "unload", ->
      andy.saveConfig keyConfigSetView.getSaveData()
    .on "resize", ->
      windowOnResize()
    .on "click", ->
      lastFocused = null
    .on "keydown", (event) ->
      keyConfigSetView.onKeyDown event

  windowOnResize()

  scrollContainer = $(".fixed-table-container-inner")[0]
  if (scrollContainer.scrollHeight - scrollContainer.offsetHeight) > 40
    $(".footer").addClass("scrolling")
    $(".scrollEnd").show()

  Backbone.history.start pushState: false
