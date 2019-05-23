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

startEdit = ->
  andy.startEdit()
  return

endEdit = ->
  andy.endEdit()
  return

class HeaderView extends HeaderBaseView
  events: _.extend
    "click .addKeyConfig": "onClickAddKeyConfig"
    "click .ctxmgr"      : "onClickCtxmgr"
    HeaderView.prototype.events
  constructor: (options) ->
    super(options)
    @model.on "change:lang", @onChangeLang, @
  onClickAddKeyConfig: (event) ->
    @trigger "clickAddKeyConfig", (event)
  onClickCtxmgr: ->
    @trigger "showPopup", "ctxMenuManager"
    @$el.find(".main-menu").blur()
  onClickSettings: ->
    @trigger "showPopup", "settings"
  onEnterCtxMenuSelMode: ->
    @$("button").attr("disabled", "disabled").addClass("disabled")
  onLeaveCtxMenuSelMode: ->
    @$("button").removeAttr("disabled").removeClass("disabled")
  onChangeLang: ->
    @$(".scHelp")
      .text("Chrome Keyboard Shortcuts Help")
      .attr "href", @scHelpUrl + @model.get("lang")

class KeyConfigView extends KeyConfigBaseView
  events: _.extend
    "click .origin,.new"   : "onClickInput"
    "click .mode"          : "onClickMode"
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
    "click .updown > .btn" : "onClickUpDownChild"
    "focus .new,.origin"   : "onFocusKeyInput"
    "focus .inputSleep"    : "onClickInputMemo"
    "keydown"              : "onKeydown"
    "submit .memo"         : "onSubmitMemo"
    "submit .formSleep"    : "onSubmitSleep"
    "blur  .selectMode"    : "onBlurSelectMode"
    "blur  .selectCog"     : "onBlurSelectCog"
    "blur  input.memo"     : "onBlurInputMemo"
    "blur  .inputSleep"    : "onBlurInputSleep"
    KeyConfigView.prototype.events
  constructor: (options) ->
    super(options)
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
    # if keynames = keyIdentifiers[@kbdtype][event.originalEvent.key]
    keyname = event.originalEvent.key
    if event.originalEvent.shiftKey
      # unless keyname = keynames[1]
      #   return
      scCode = "04"
    else
      # keyname = keynames[0]
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
    if event.currentTarget.getAttribute("title") is "Suspend"
      return
    @$(".selectMode").toggleClass("selecting").focus()
    event.stopPropagation()

  onBlurSelectMode: (event) ->
    setTimeout (=> @$(".selectMode").removeClass("selecting")), 0

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
    @$(".selectCog").toggleClass("selecting").focus()
    event.stopPropagation()

  onBlurSelectCog: (event) ->
    setTimeout (=> @$(".selectCog").removeClass("selecting")), 0

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
      msg += "\n\n Mapped key: #{shortcut}\n Description: \"#{@getDescription()}\""
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

class KeyConfigSetView extends KeyConfigSetBaseView
  scrollingBottomBegin: 120

  events: _.extend
    "click .addnew": "onClickAddnew"
    "blur  .addnew": "onBlurAddnew"
    "click"        : "onClickBlank"
    KeyConfigSetBaseView.prototype.events
  
  constructor: (options) ->
    super(options)
    @model.on "change:lang"   , @onChangeLang   , @
    @model.on "change:kbdtype", @onChangeKbdtype, @
    @collection.on
      kbdEvent: @onKbdEvent
      @

  render: (keyConfigSet) ->
    super(keyConfigSet)
    @$("tbody").sortable
      delay: 300
      scroll: true
      cancel: ".borderRow,.child,input"
      placeholder: "ui-placeholder"
      forceHelperSize: true
      forcePlaceholderSize: true
      cursor: "move"
      start: =>
        @onStartSort()
      stop: (event, ui) =>
        @redrawTable()
        ui.item.effect("highlight", 1500)[0].scrollIntoViewIfNeeded true

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

  # Collection Events
  onAddRender: (model) ->
    keyConfigView = new KeyConfigView model: model
    keyConfigView.on
      "removeConfig"  : @onChildRemoveConfig
      "resizeInput"   : @onChildResizeInput
      "showPopup"     : @onShowPopup
      "addCtxMenu"    : @onAddCtxMenu
      "updateChildPos": @redrawTable
      "remakeCtxMenu" : @onRemakeCtxMenu
      "getConfigValue": @onGetConfigValue
      @
    divAddNew = @$("tr.addnew")[0] || null
    if /^C/.test(model.id) && lastFocused
      divAddNew = lastFocused.nextSibling || null
    tbody = @$("tbody")[0]
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
    keyname = event.originalEvent.key
    if event.originalEvent.shiftKey
      scCode = "04"
    else
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
    @$("tbody")[0].insertBefore newItem$[2], lastFocused
    newItem$.find(".addnew").focus()[0].scrollIntoViewIfNeeded()
    @$("tbody").sortable "disable"
    windowOnResize()

  onClickBlank: ->
    @$(":focus").blur()
    lastFocused = null

  onClickAddnew: (event) ->
    event.stopPropagation()

  onBlurAddnew: ->
    @$(".addnew, .addnewBorder").remove()
    @$("tbody").sortable "enable"
    windowOnResize()

  onChangeLang: ->
    @collection.trigger "changeLang", @model.get("lang")

  onChangeKbdtype: ->
    @collection.trigger "changeKbd", @model.get("kbdtype")

  onStartSort: ->
    @$(".child").hide()
    @$(".ui-placeholder").nextAll(".borderRow:first,.borderRow:last").remove()
    @$(".parent th:first-child").removeAttr "rowspan"

$ = jQuery
$ ->
  [keyCodes, scHelp, scHelpSect] = andy.getConfig()
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

  Backbone.history.start pushState: false
