// Signature d'un énoncé rendu : chaque caractère visible avec son style calculé
// et sa hauteur dans la page ; plus les éléments non textuels.
function signature(root) {
  var rootTop = root.getBoundingClientRect().top
  var chars = []
  var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT)
  var range = document.createRange()
  var n
  while ((n = walker.nextNode())) {
    var t = n.textContent
    if (!t.trim()) continue
    var el = n.parentElement
    var cs = getComputedStyle(el)
    var bg = "none"
    for (var e = el; e && e !== root; e = e.parentElement) {
      var b = getComputedStyle(e).backgroundColor
      if (b !== "rgba(0, 0, 0, 0)" && b !== "transparent") { bg = b; break }
    }
    var bloc = el
    while (bloc !== root && /^inline/.test(getComputedStyle(bloc).display)) bloc = bloc.parentElement
    var cle = [parseInt(cs.fontWeight, 10) >= 600 ? "gras" : "", cs.fontStyle === "italic" ? "ital" : "",
      cs.textDecorationLine, cs.color, bg, cs.fontSize, getComputedStyle(bloc).textAlign].join("|")
    for (var i = 0; i < t.length; i++) {
      if (/\s/.test(t[i])) continue
      range.setStart(n, i); range.setEnd(n, i + 1)
      chars.push({ c: t[i], cle: cle, top: Math.round(range.getBoundingClientRect().top - rootTop) })
    }
  }
  var elements = ["img", "table", "svg", "figure", "li", "h1", "h2", "h3", "blockquote", "pre", "a"].map(function (s) {
    return s + ":" + root.querySelectorAll(s).length
  }).join(" ")
  return { chars: chars, elements: elements, hauteur: Math.round(root.getBoundingClientRect().height) }
}

function sauts(chars) {
  var s = []
  for (var i = 1; i < chars.length; i++) if (chars[i].top - chars[i - 1].top > 2) s.push(i)
  return s
}

function comparer(avant, apres) {
  var a = document.getElementById("a"), b = document.getElementById("b")
  a.innerHTML = avant; b.innerHTML = apres
  var sa = signature(a), sb = signature(b)
  var ta = sa.chars.map(function (x) { return x.c }).join(""), tb = sb.chars.map(function (x) { return x.c }).join("")
  var r = { texte: ta === tb, elements: sa.elements === sb.elements, hauteurAvant: sa.hauteur, hauteurApres: sb.hauteur }
  r.format = r.texte && sa.chars.every(function (x, i) { return x.cle === sb.chars[i].cle })
  r.lignes = r.texte && JSON.stringify(sauts(sa.chars)) === JSON.stringify(sauts(sb.chars))
  var ecart = 0
  if (r.texte) sa.chars.forEach(function (x, i) { ecart = Math.max(ecart, Math.abs(x.top - sb.chars[i].top)) })
  r.ecartMax = ecart
  r.espacement = r.texte && ecart <= 4 && Math.abs(sa.hauteur - sb.hauteur) <= 4
  if (!r.texte) {
    var k = 0; while (k < ta.length && ta[k] === tb[k]) k++
    r.detail = "texte: «" + ta.slice(Math.max(0, k - 20), k + 30) + "» devient «" + tb.slice(Math.max(0, k - 20), k + 30) + "»"
  } else if (!r.format) {
    var j = sa.chars.findIndex(function (x, i) { return x.cle !== sb.chars[i].cle })
    r.detail = "format à «" + ta.slice(Math.max(0, j - 10), j + 15) + "» : " + sa.chars[j].cle + " devient " + sb.chars[j].cle
  } else if (!r.elements) {
    r.detail = "éléments : " + sa.elements + " devient " + sb.elements
  }
  return r
}
