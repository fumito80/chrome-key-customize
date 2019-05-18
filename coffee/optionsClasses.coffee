keyCodes = {}
scHelp = null
scHelpSect = null
keys = null
router = null
keyConfigSetView = null
ctxMenuManagerView = null
gMaxItems = 100
defaultSleep = 100
lastFocused = null
loading = true
andy = chrome.extension.getBackgroundPage().andy

modeDisp =
  remap:    ["Remap"      , "icon-random"]
  command:  ["Command..." , "icon-asterisk"]
  bookmark: ["Bookmark...", "icon-bookmark-empty"]
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
  discardTabs:    ["tab", "Discards unselected tabs from memory"]
  # historyGoBack:  ["tab", "Go back to the previous page from browsing history"]
  # historyForward: ["tab", "Go forward the next page from browsing history"]
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

escape = (html) ->
  entity =
    "&": "&amp;"
    "<": "&lt;"
    ">": "&gt;"
  html.replace /[&<>]/g, (match) ->
    entity[match]

modifierKeys  = ["Ctrl", "Alt", "Shift", "Win"] #, "MouseL", "MouseR", "MouseM"]
modifierInits = ["c"   , "a"  , "s"    , "w"]

HeaderBaseView = Backbone.View.extend
  scHelpUrl: "https://support.google.com/chrome/answer/157179?hl="
  # Backbone Buitin Events
  el: "header"
  events:
    "click .menu-main": "onClickMenu"
    "blur  .main-menu": "onBlurMenu"
    "click .settings" : "onClickSettings"
  initialize: ->
    @$(".menu-settings, .addKeyConfig").show()
  # DOM Events
  onClickMenu: (event) ->
    mainMenu = @$(".main-menu")
    if mainMenu.hasClass("blurNow")
      mainMenu.removeClass "blurNow"
      return
    mainMenu.toggleClass("selecting").focus()
  onBlurMenu: (event) ->
    target = event.relatedTarget || event.target
    if target.localName is "a"
      @$(".main-menu").focus()
      return
    (mainMenu = @$(".main-menu").removeClass("selecting"))
    if $(target).hasClass("menu-main")
      mainMenu.addClass("blurNow")

Config = Backbone.Model.extend {}

KeyConfig = Backbone.Model.extend
  idAttribute: "new"
  defaults:
    mode: "remap"

KeyConfigSet = Backbone.Collection.extend model: KeyConfig

KeyConfigBaseView = Backbone.View.extend

  kbdtype: null
  optionKeys: []

  # Backbone Buitin Events
  events:
    "mouseover"            : "onMouseOverChild"
    "mouseout"             : "onMouseOutChild"

  initialize: (options) ->
    @optionKeys = _.keys modeDisp
    @model.collection.on
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

  # Collection Events
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

  onChangeMode: (event, mode) ->
    if event
      @$(".mode").removeClass("selecting")
      mode = event.currentTarget.className
      if mode in ["bookmark", "command"]
        @trigger "showPopup", mode, @model.id
        return
    @model.set "mode", mode
    @setDispMode mode
    @setDesc()
    @trigger "resizeInput"

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

  # Object Method
  getDescription: ->
    if @model.get("mode") is "remap"
      desc = @$(".desc").find(".content,.memo").text()
    else
      desc = @$(".desc").find(".content,.command,.commandCaption,.bookmark,.memo").text().replace(/\s+/g, " ")
    $.trim(desc)

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
      @$("th:eq(1) > *, th:eq(2) > *").show()
    else
      @$("th:eq(1) > *, th:eq(2) > *").hide()

  setKbdValue: (input$, value) ->
    if value is "00768"
      input$.html """<span title="Toolbar Button"><img src="images/toolbarIcon.png" class="toolbarIcon"></span>"""
    else if result = decodeKbdEvent value
      input$.html _.map(result.split(" + "), (s) -> "<span>#{s}</span>").join("+")
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
        { name, content, caption } = @model.get("command")
        desc = (commandDisp = commandsDisp[name])[1]
        if commandDisp[2]
          content3row = []
          lines = content?.split("\n") || []
          for i in [0...lines.length]
            if i > 2
              content3row[i-1] += " ..."
              break
            else
              content3row.push lines[i].replace(/"/g, "'")
          tdDesc.append @tmplCommandCustom {
            ctg: commandDisp[3]
            desc
            content3row: content3row.join("\n")
            caption
          }
          editOption = iconName: "icon-pencil", command: "Edit command..."
        else if name is "zoomFixed"
          unless zoom = @model.get("sleep")
            @model.set "sleep", zoom = 100
          tdDesc.append @tmplZoomFixed { zoom }
        else if name is "zoomInc"
          unless zoom = @model.get("sleep")
            @model.set "sleep", zoom = 10
          tdDesc.append @tmplZoomInc { zoom }
        else
          ctg = commandDisp[0].substring(0,1).toUpperCase() + commandDisp[0].substring(1)
          tdDesc.append @tmplCommand { desc, ctg }
            
      when "remap", "disabled"
        if mode is "remap"
          keycombo = @$(".origin").text()
        else
          keycombo = @$(".new").text()
        keycombo = (keycombo.replace /\s/g, "").toUpperCase()
        unless help = scHelp[@lang][keycombo]
          if /^CTRL\+[2-7]$/.test keycombo
            help = scHelp[@lang]["CTRL+1"]
        if help
          help.forEach (scKey) =>
            [, key, content] = /(^\w+)\^(.+)/.exec scKey
            tdDesc.append @tmplHelp
              sectDesc: scHelpSect[@lang][key]
              sectKey:  key
              scHelp:   content
            # .find(".sectInit")
            # .tooltip
            #   position: { my: "left+10 top-60" }
            #   tooltipClass: "tooltipClass"
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
    <button class="btn btn-outline-primary btn-sm cog" title="Sub Menu"><i class="icon-ellipsis-horizontal"></i></button>
    <div class="selectCog" tabIndex="0">
      <div class="edit"><i class="<%=iconName%>"></i> <%=command%></div>
      <div class="addCommand"><i class="icon-plus"></i> Add command</div>
      <div class="ctxmenu"><i class="icon-reorder"></i> Create context menu...</div>
      <!--<div class="copySC"><i class="icon-copy"></i> Copy script</div>-->
      <div class="menuChangeIcon"></div>
      <span class="seprater 1st"><hr style="margin:3px 1px"></span>
      <div class="pause"><i class="icon-pause"></i> Suspend</div>
      <div class="resume"><i class="icon-play"></i> Resume</div>
      <span class="seprater"><hr style="margin:3px 1px"></span>
      <div class="delete"><i class="icon-trash"></i> Delete</div>
    </div>
    """

  tmplUpDown: """
    <div class="btn-group updown">
      <button class="btn btn-outline-primary btn-sm" title="up"><i class="icon-chevron-up"></i></button>
  	  <button class="btn btn-outline-primary btn-sm" title="down"><i class="icon-chevron-down"></i></button>
  	</div>
    """

  tmplMemo: _.template """
    <form class="memo">
      <input type="text" class="form-control memo">
    </form>
    <div class="memo"><%=memo%></div>
    """

  tmplSleep: _.template """
    <form class="formSleep">
      <span>Sleep</span>
      <input type="number" class="inputSleep" min="0" max="60000" step="10" required>
      <span class="dispSleep" title="Sleep <%=sleep%> msec"><%=sleep%></span>&nbsp;msec
      <i class="icon-pencil editSleep" title="Edit sleep msec(0-60000)"></i>
    </form>
    """

  tmplZoomFixed: _.template """
    <div class="ctgIcon Tab">Tab</div><div class="command">
      <form class="formSleep">
        <span>Zoom page</span>
        <input type="number" class="inputSleep" min="25" max="500" step="1" required>
        <span class="dispSleep" title="Zoom page <%=zoom%> %"><%=zoom%></span>&nbsp;%
        <i class="icon-pencil editSleep" title="Edit zoom factor % between 25 and 500"></i>
      </form>
    </div>
    """
  tmplZoomInc: _.template """
    <div class="ctgIcon Tab">Tab</div><div class="command">
      <form class="formSleep">
        <span>Zoom page - increments</span>
        <input type="number" class="inputSleep" min="-100" max="100" step="1" required>
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
      <th class="thRemap">
        <div class="new" tabIndex="0"></div>
        <div class="grpbartop"></div>
        <div class="grpbarbtm"></div>
      </th>
      <th class="thArrow">
        <i class="icon-arrow-right"></i>
      </th>
      <th class="thOrigin">
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

KeyConfigSetBaseView = Backbone.View.extend
  placeholder: "Enter new shortcut key"

  # Backbone Buitin Events
  el: "table.keyConfigSetView"

  events: {}
    # "click .scrollEnd i": "onClickScrollEnd"

  initialize: (options) ->
    @collection.comparator = (model) ->
      model.get "order"
    @collection.on
      add:      @onAddRender
      @

  render: (keyConfigSet) ->
    @$el.append @template()
    @collection.set keyConfigSet
    loading = false
    @redrawTable()
    $(".fixed-table-container-inner")
      .on "scroll", @setScrollingShade.bind(@)
      .niceScroll
        horizrailenabled: false
        cursorwidth: 13
        cursorborderradius: 2
        smoothscroll: true
        cursoropacitymin: .3
        cursoropacitymax: .7
        zindex: 999998
    @

  # Object Method
  redrawTable: ->
    @$(".child").show()
    @$(".borderRow").remove()
    @collection.models.forEach (model) =>
      model.trigger "setRowspan"
    $("#sortarea").append @$(".data")
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
    @$(".last").removeClass "last"
    $.each @$("tbody > tr"), (i, tr) =>
      unless /child/.test tr.nextSibling?.className
        (tr$ = $(tr)).after @tmplBorder
        if /child/.test tr.className
          tr$.addClass "last"

  setScrollingShade: (event) ->
    { scrollTop, scrollHeight, offsetHeight } = event.target || $(".fixed-table-container-inner")[0]
    if scrollTop < 10
      $(".header-background").removeClass("scrolling")
    else
      $(".header-background").addClass("scrolling")
      $(".scrollEnd").show()
    if scrollTop + @scrollingBottomBegin > scrollHeight - offsetHeight
      $("footer").removeClass("scrolling")
    else
      $("footer").addClass("scrolling")
      $(".scrollEnd").show()

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
    <tr class="borderRow addnewBorder">
      <td colspan="6"><div class="borderRow"></div></td>
      <td></td>
    </tr>
    """

  tmplBorder: """
    <tr class="borderRow">
      <td colspan="6"><div class="borderRow"></div></td>
      <td></td>
    </tr>
    """

  template: _.template """
    <thead>
      <tr>
        <th class="thRemap">
          <div class="th_inner">Mapped key</div>
        </th>
        <th class="thArrow">
          <div class="th_inner"><i class="icon-arrow-right"></i></div>
        </th>
        <th class="thOrigin">
          <div class="th_inner">Origin key</div>
        </th>
        <th class="thOptions">
          <div class="th_inner options">Mode</div>
        </th>
        <th class="ctxmenu"></th>
        <th>
          <div class="th_inner desc">Description</div>
          <!--
          <div class="scrollEnd top"><i class="icon-double-angle-up" title="Scroll to Top"></i></div>
          <div class="scrollEnd bottom"><i class="icon-double-angle-down" title="Scroll to Bottom"></i></div>
          -->
        </th>
      </tr>
    </thead>
    <tbody></tbody>
    """

marginBottom = 0
resizeTimer = false
windowOnResize = ->
  if resizeTimer
    clearTimeout resizeTimer
  resizeTimer = setTimeout((->
    tableHeight = window.innerHeight - document.querySelector("header").offsetHeight - marginBottom
    document.querySelector(".fixed-table-container").style.height = tableHeight + "px"
    $(".fixed-table-container-inner").getNiceScroll().resize()
    $(".result_outer").getNiceScroll().resize()
  ), 200)
