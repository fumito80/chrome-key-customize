window.scw =
  pre: ->
    lang = chrome.i18n.getUILanguage()
    if /^ja/.test lang
      el = document.querySelector("#mdloader")
      el.setAttribute("src", "help/installja.md")

  post: ->
    chrome.runtime.getPlatformInfo (platformInfo) ->
      if platformInfo.arch is "x86-64"
        el = document.querySelector("a[href='scwinst32.exe']")
        el.setAttribute("href", "scwinst64.exe")
        el.textContent = "scwinst64.exe"
