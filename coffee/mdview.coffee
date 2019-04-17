# scw?.pre()

mdToHtml = (md, iframe) ->
  iframe.setAttribute("style", "display:none;")
  document.body.setAttribute "style", "overflow:auto;margin:8px;"
  converter = new Showdown.converter()
  document.getElementById("content").innerHTML = converter.makeHtml(md)
  if hash = document.location.hash
    document.location = hash
  Array.prototype.forEach.call document.getElementsByTagName("pre"), (pre) ->
    pre.className = "prettyprint"
  prettyPrint()
  scw?.post()

iframe = document.getElementById "mdloader"
if md = iframe.contentDocument.querySelector("pre")?.textContent
  mdToHtml md, iframe
else
  iframe.addEventListener "load", ->
    if md = iframe.contentDocument.querySelector("pre")?.textContent
      mdToHtml md, @
