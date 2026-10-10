// Manipule : la lecture à voix haute de l'énoncé, et les jetons qu'on déplace.
//
// Rien d'autre ne nécessite de JavaScript ici — les réponses sont des
// formulaires. Pas de Stimulus, pas de dépendance : ce bundle doit rester
// minuscule et tourner sur un navigateur dont on ignore l'âge.

const FEMININES = /(am[ée]lie|audrey|aur[ée]lie|marie|hortense|julie|denise|[ée]lo[ïi]se|sylvie|google fran[çc]ais|femme|female)/i
const MASCULINES = /(thomas|paul|henri|claude|nicolas|guillaume|r[ée]mi|jean|homme|male)/i
// Les voix « Natural », « Online », Google ou Siri sont neuronales : à genre
// égal, elles sont nettement plus compréhensibles qu'une voix système.
const QUALITE = /(natural|online|enhanced|premium|neural|siri|google)/i

let voix = null
let enCours = false
let relance = null
let lecteur = null
let enPause = false

function choisir() {
  if (!window.speechSynthesis) return
  const francaises = speechSynthesis.getVoices().filter((v) => /^fr/i.test(v.lang))
  francaises.sort((a, b) => note(a) - note(b))
  voix = francaises[0] || null
  afficher(francaises)
}

function note(v) {
  let n = 0
  if (FEMININES.test(v.name)) n -= 8
  else if (MASCULINES.test(v.name)) n += 8
  if (QUALITE.test(v.name)) n -= 3
  if (v.localService) n += 1
  return n
}

// L'avertissement ne concerne que le repli : si les morceaux sont là, l'absence
// de voix française sur la machine n'a plus aucune importance.
function afficher(francaises) {
  const zone = document.querySelector("[data-m-voix]")
  if (!zone) return
  if (document.querySelector("[data-m-audio]")) { zone.textContent = ""; return }
  if (!window.speechSynthesis) zone.textContent = "Cet ordinateur ne sait pas lire à voix haute."
  else if (!francaises.length && speechSynthesis.getVoices().length) zone.textContent = "Aucune voix française sur cet ordinateur."
  else zone.textContent = ""
}

function arreter() {
  enCours = false
  enPause = false
  if (relance) { clearInterval(relance); relance = null }
  if (lecteur) { lecteur.pause(); lecteur = null }
  if (window.speechSynthesis) speechSynthesis.cancel()
  document.querySelectorAll(".m-lu").forEach((element) => element.classList.remove("m-lu"))
}

// Un morceau pré-généré : la même voix pour tous les élèves, quelle que soit la
// machine. C'est le chemin normal ; la synthèse du navigateur n'est plus qu'un
// filet pour les problèmes dont l'audio n'a pas encore été fabriqué.
function jouerFichier(url, fini) {
  const son = new window.Audio(url)
  lecteur = son
  const finir = () => { if (lecteur === son) lecteur = null; fini() }
  son.onended = finir
  son.onerror = finir
  son.play().catch(finir)
}

// Une phrase à la fois, avec un silence entre chacune : c'est ce que
// l'enseignante demande, et ça ne s'obtient pas en baissant le débit.
function lireTexte(texte, fini) {
  if (!window.speechSynthesis) { fini(); return }
  const phrases = (texte.match(/[^.!?…]+[.!?…]*/g) || []).map((p) => p.trim()).filter(Boolean)
  if (!phrases.length) { fini(); return }

  let i = 0
  const suivante = () => {
    if (!enCours || i >= phrases.length) { fini(); return }
    const u = new SpeechSynthesisUtterance(phrases[i])
    u.lang = "fr-FR"
    if (voix) u.voice = voix
    u.rate = 0.9
    u.onend = () => { i += 1; setTimeout(suivante, 650) }
    u.onerror = () => { arreter(); fini() }
    speechSynthesis.speak(u)
  }
  suivante()
}

// Chaque élément est surligné pendant qu'il est lu : un élève qui ne déchiffre
// pas doit au moins voir OÙ on en est.
function lireElements(elements, fini) {
  if (!elements.length) { fini(); return }
  arreter()
  enCours = true
  // Chrome coupe la lecture au bout d'une quinzaine de secondes sans ce rappel.
  relance = setInterval(() => {
    if (enCours && !enPause) { speechSynthesis.pause(); speechSynthesis.resume() }
  }, 9000)

  let i = 0
  const suivant = () => {
    if (!enCours || i >= elements.length) { arreter(); fini(); return }
    const element = elements[i]
    element.classList.add("m-lu")
    const apres = () => {
      element.classList.remove("m-lu")
      i += 1
      setTimeout(suivant, 250)
    }
    const fichier = element.dataset.mAudio
    if (fichier) jouerFichier(fichier, apres)
    else lireTexte(element.textContent.trim(), apres)
  }
  suivant()
}

function signalerEcoute(bouton) {
  const url = bouton.dataset.url
  const attempt = bouton.dataset.attempt
  if (!url || !attempt) return
  const jeton = document.querySelector('meta[name="csrf-token"]')
  fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded", "X-CSRF-Token": jeton ? jeton.content : "" },
    body: `attempt_id=${encodeURIComponent(attempt)}`
  }).catch(() => {})
}

function suspendre() {
  enPause = true
  if (lecteur) lecteur.pause()
  if (window.speechSynthesis) speechSynthesis.pause()
}

function reprendre() {
  enPause = false
  if (lecteur) lecteur.play().catch(() => {})
  if (window.speechSynthesis) speechSynthesis.resume()
}

// Pendant une lecture, seuls les petits haut-parleurs se verrouillent : les
// deux grands boutons, eux, pilotent ce qui est en train de se dire.
function verrouillerLesPetits(verrou) {
  document.querySelectorAll("[data-m-ecouter-un]").forEach((bouton) => { bouton.disabled = verrou })
}

function brancher() {
  const principal = document.querySelector("[data-m-ecouter]")
  const aLire = Array.from(document.querySelectorAll("[data-m-lire]"))
  if (!principal || !aLire.length) return

  const stop = document.querySelector("[data-m-stop]")
  let enLecture = false

  const revenirAuRepos = () => {
    enLecture = false
    verrouillerLesPetits(false)
    principal.classList.remove("m-en-cours")
    principal.textContent = "🔊 Tout écouter"
    if (stop) stop.hidden = true
  }

  const afficherPause = () => {
    principal.classList.add("m-en-cours")
    principal.textContent = "⏸ Pause"
    if (stop) stop.hidden = false
  }

  const demarrer = (elements) => {
    enLecture = true
    verrouillerLesPetits(true)
    principal.disabled = false
    afficherPause()
    signalerEcoute(principal)
    lireElements(elements, revenirAuRepos)
  }

  // Le même bouton mène les trois états : écouter, suspendre, reprendre.
  // Arrêter est à côté, parce que c'est une autre décision — on ne reprendra
  // pas, on recommencera depuis le début.
  principal.addEventListener("click", () => {
    if (!enLecture) { demarrer(aLire); return }
    if (enPause) { reprendre(); afficherPause(); return }

    suspendre()
    principal.textContent = "▶ Reprendre"
  })

  if (stop) {
    stop.addEventListener("click", () => {
      arreter()
      revenirAuRepos()
    })
  }

  // Le haut-parleur d'une réponse ne relit que celle-là, autant de fois que
  // l'élève veut : mémoriser trois options entendues d'affilée est hors de
  // portée de l'enfant à qui la voix s'adresse.
  document.querySelectorAll("[data-m-ecouter-un]").forEach((bouton) => {
    bouton.addEventListener("click", () => {
      const cible = bouton.parentElement.querySelector("[data-m-lire]")
      if (cible) demarrer([cible])
    })
  })
}


// ───────────────────────────── les jetons ─────────────────────────────
//
// L'élève fait glisser des jetons d'une réserve vers des cases nommées
// d'après l'énoncé. Rien n'est corrigé et rien n'est envoyé : c'est un
// brouillon pour se représenter le problème, pas une réponse.
//
// Événements « pointer » et non glisser-déposer HTML5 : ce dernier n'existe
// pas au doigt, et on ne sait pas sur quoi la classe travaillera. Un
// repli par touches successives — un jeton, puis une case — rattrape
// l'enfant qui n'arrive pas à maintenir le contact en se déplaçant.

const SEUIL_GLISSE = 6 // pixels avant de considérer que c'est un glissé

let jetonChoisi = null

// Compte ce qui est dans le tas, sans savoir de quoi il s'agit : des jetons,
// des unités, des barres. C'est ce qui permet à un seul moteur de servir
// plusieurs outils.
function compter(outil) {
  outil.querySelectorAll("[data-m-zone]").forEach((zone) => {
    const compte = zone.querySelector("[data-m-compte]")
    const tas = zone.querySelector("[data-m-tas]")
    if (compte && tas) compte.textContent = tas.children.length
  })
}

function deposer(jeton, zone, point = null) {
  const tas = zone.querySelector("[data-m-tas]")
  if (!tas) return

  tas.appendChild(jeton)

  // Une zone « libre » garde la pièce où elle tombe : l'élève range comme il
  // veut, et un bouton alignera quand LUI le décidera.
  if (zone.hasAttribute("data-m-libre") && point) {
    const cadre = tas.getBoundingClientRect()
    jeton.style.position = "absolute"
    jeton.style.left = `${Math.max(0, Math.min(point.x - cadre.left - (jeton.offsetWidth / 2), cadre.width - jeton.offsetWidth))}px`
    jeton.style.top = `${Math.max(0, Math.min(point.y - cadre.top - (jeton.offsetHeight / 2), cadre.height - jeton.offsetHeight))}px`
  } else {
    jeton.style.position = ""
    jeton.style.left = ""
    jeton.style.top = ""
  }
  const outil = zone.closest("[data-m-jetons], [data-m-plateau]")
  if (outil) {
    compter(outil)
    outil.dispatchEvent(new CustomEvent("m:change", { bubbles: false }))
  }
}

function oublierLeChoix() {
  if (jetonChoisi) jetonChoisi.classList.remove("m-jeton-choisi")
  jetonChoisi = null
}

function zoneSous(x, y) {
  const sous = document.elementFromPoint(x, y)
  return sous ? sous.closest("[data-m-zone]") : null
}

// `auTap` : ce que fait la pièce quand on la TOUCHE sans la déplacer. Si elle
// s'en charge, on ne la sélectionne pas — ouvrir une dizaine et la choisir
// pour la déposer sont deux gestes qui s'excluent.
function brancherUnePiece(jeton, outil, accepte = () => true, auTap = null) {
  jeton.addEventListener("pointerdown", (e) => {
    e.preventDefault()
    const depart = { x: e.clientX, y: e.clientY }
    let glisse = false

    const bouger = (ev) => {
      if (!glisse && Math.hypot(ev.clientX - depart.x, ev.clientY - depart.y) < SEUIL_GLISSE) return

      if (!glisse) {
        glisse = true
        oublierLeChoix()
        jeton.classList.add("m-jeton-vole")
      }
      jeton.style.transform = `translate(${ev.clientX - depart.x}px, ${ev.clientY - depart.y}px)`
    }

    const lacher = (ev) => {
      document.removeEventListener("pointermove", bouger)
      document.removeEventListener("pointerup", lacher)
      document.removeEventListener("pointercancel", lacher)
      jeton.classList.remove("m-jeton-vole")
      jeton.style.transform = ""

      if (!glisse) {
        // `pointerdown` appelle `preventDefault()`, ce qui empêche le `click`
        // de suivre : une action posée sur `click` ne partirait JAMAIS au
        // doigt. Tout ce qui répond au tapotement passe donc par ici.
        if (auTap && auTap(jeton)) return

        // Un simple appui : on choisit le jeton, la case viendra ensuite.
        const dejaChoisi = jetonChoisi === jeton
        oublierLeChoix()
        if (!dejaChoisi) {
          jetonChoisi = jeton
          jeton.classList.add("m-jeton-choisi")
        }
        return
      }

      const cible = zoneSous(ev.clientX, ev.clientY)
      if (cible && outil.contains(cible) && accepte(jeton, cible)) {
        deposer(jeton, cible, { x: ev.clientX, y: ev.clientY })
      }
    }

    document.addEventListener("pointermove", bouger)
    document.addEventListener("pointerup", lacher)
    document.addEventListener("pointercancel", lacher)
  })
}

function brancherLesJetons() {
  document.querySelectorAll("[data-m-jetons]").forEach((outil) => {
    outil.querySelectorAll("[data-m-jeton]").forEach((jeton) => brancherUnePiece(jeton, outil))

    brancherLesZones(outil)
    compter(outil)
  })
}

// Le repli par touches successives : on touche une pièce, puis une case. Il
// existe pour l'enfant qui n'arrive pas à maintenir le contact en se
// déplaçant — et il vaut pour TOUS les outils, pas seulement les jetons.
function brancherLesZones(outil, accepte = () => true) {
  outil.querySelectorAll("[data-m-zone]").forEach((zone) => {
    zone.addEventListener("click", (e) => {
      // La pièce est DANS sa case : sans ce garde, le clic qui vient de la
      // choisir remonte jusqu'ici et la repose aussitôt, si bien qu'on ne peut
      // jamais rien sélectionner. On choisit en touchant une pièce, on dépose
      // en touchant la case ailleurs que sur une pièce.
      //
      // Le bouton d'échange vit DANS la boîte : sans lui aussi dans ce garde,
      // un enfant qui touche un cube, change d'avis et touche « échanger » le
      // voit atterrir dans la boîte.
      if (e.target.closest("[data-m-jeton], [data-m-piece], [data-m-echanger]")) return
      if (!jetonChoisi || !accepte(jetonChoisi, zone)) return

      const piece = jetonChoisi
      oublierLeChoix()
      deposer(piece, zone, { x: e.clientX, y: e.clientY })
    })
  })
}

// ── les dizaines et les unités ─────────────────────────────────────────
//
// Un matériel de représentation, pas un exerciseur : l'élève s'en sert pour
// s'AIDER à résoudre. Une seule zone, où les pièces se posent OÙ IL VEUT — pas
// de colonnes, pas de rangement imposé. Un bouton aligne quand lui le décide.
//
// Et une case qui transforme, dans les deux sens : dix unités y deviennent une
// dizaine, une dizaine y éclate en dix unités. C'est LUI qui transforme, en y
// déposant ce qu'il veut ; un échange fait par l'écran lui volerait la
// retenue.

function tasDeTravail(plateau) {
  return plateau.querySelector('[data-m-zone="travail"] [data-m-tas]')
}

function unePiece(sorte) {
  const piece = document.createElement("button")
  piece.type = "button"
  piece.className = sorte === "barre" ? "m-barre" : "m-unite"
  piece.dataset.mPiece = sorte
  piece.setAttribute("aria-label", sorte === "barre" ? "Dizaine" : "Unité")
  return piece
}

// On compte TOUT ce que l'élève a sous la main, la case qui échange comprise.
// Sinon le total chute pendant qu'il y dépose ses unités — 12, puis 5, puis 4
// — et il croit perdre des pièces. Compté ainsi, le total ne bouge jamais : ni
// en déposant, ni en transformant. C'est l'invariant que l'outil enseigne.
function combien(plateau, sorte) {
  return plateau.querySelectorAll(`[data-m-piece="${sorte}"]`).length
}

// Le plafond, lui, ne regarde que la zone de travail : ce qui est dans la
// machine est de passage.
function combienEnTravail(plateau, sorte) {
  return tasDeTravail(plateau)?.querySelectorAll(`[data-m-piece="${sorte}"]`).length || 0
}

function accepteLaPiece(_piece, zone) {
  return zone.dataset.mAccepte === "tout"
}

function placeLibre(plateau, sorte) {
  const maximum = Number(sorte === "barre" ? plateau.dataset.maxDizaines : plateau.dataset.maxUnites) || 9
  return combienEnTravail(plateau, sorte) < maximum
}

// Le total et son détail, lus en permanence. Le détail dit la POSITION sans
// imposer de colonnes : trois dizaines et cinq unités font trente-cinq.
function rafraichirLePlateau(plateau) {
  const dizaines = combien(plateau, "barre")
  const unites = combien(plateau, "unite")

  const total = plateau.querySelector("[data-m-total]")
  if (total) total.textContent = (dizaines * 10) + unites

  const detail = plateau.querySelector("[data-m-detail]")
  if (!detail) return

  const morceaux = []
  if (dizaines) morceaux.push(`${dizaines} ${dizaines > 1 ? "dizaines" : "dizaine"}`)
  if (unites) morceaux.push(`${unites} ${unites > 1 ? "unités" : "unité"}`)
  detail.textContent = morceaux.join(" et ")
}

function poserUnePiece(plateau, sorte, point = null) {
  if (!placeLibre(plateau, sorte)) return null

  const piece = unePiece(sorte)
  const zone = plateau.querySelector('[data-m-zone="travail"]')
  tasDeTravail(plateau)?.appendChild(piece)
  brancherUnePiece(piece, plateau, accepteLaPiece)
  if (point && zone) deposer(piece, zone, point)
  rafraichirLePlateau(plateau)
  return piece
}

// La case qui échange. Elle ne GARDE rien : ce qu'on y met en ressort
// transformé, et retourne dans la zone de travail. Une dizaine éclate tout de
// suite ; dix unités attendent d'être dix.
function faireTourenerLaMachine(plateau, machine) {
  const dedans = machine.querySelector("[data-m-tas]")
  if (!dedans) return

  // Ce qui sort de la machine se range dans le flux, à la suite. Le poser aux
  // coordonnées de la machine le tassait contre un bord de la zone, et dix
  // unités se recouvraient les unes les autres.
  const barre = dedans.querySelector('[data-m-piece="barre"]')
  if (barre) {
    barre.remove()
    for (let i = 0; i < 10; i += 1) poserUnePiece(plateau, "unite")
    rafraichirLePlateau(plateau)
    return
  }

  const unites = dedans.querySelectorAll('[data-m-piece="unite"]')
  if (unites.length < 10) return

  Array.from(unites).slice(0, 10).forEach((u) => u.remove())
  poserUnePiece(plateau, "barre")
  rafraichirLePlateau(plateau)
}

// Ranger : les pièces s'alignent, les dizaines d'abord. À la demande, jamais
// d'office — c'est l'élève qui décide quand son brouillon devient lisible.
function rangerLePlateau(plateau) {
  const tas = tasDeTravail(plateau)
  if (!tas) return

  const pieces = Array.from(tas.querySelectorAll("[data-m-piece]"))
  pieces.sort((a, b) => (a.dataset.mPiece === b.dataset.mPiece ? 0 : a.dataset.mPiece === "barre" ? -1 : 1))
  pieces.forEach((piece) => {
    piece.style.position = ""
    piece.style.left = ""
    piece.style.top = ""
    tas.appendChild(piece)
  })
}

function brancherLesPlateaux() {
  document.querySelectorAll("[data-m-plateau]").forEach((plateau) => {
    plateau.querySelectorAll("[data-m-piece]").forEach((piece) => brancherUnePiece(piece, plateau, accepteLaPiece))
    brancherLesZones(plateau, accepteLaPiece)

    plateau.querySelectorAll("[data-m-piocher]").forEach((bouton) => {
      bouton.addEventListener("click", () => poserUnePiece(plateau, bouton.dataset.mPiocher))
    })

    // Enlever : la dernière pièce de cette sorte s'en va. Un « − » en face du
    // « + » se comprend sans explication.
    plateau.querySelectorAll("[data-m-retirer]").forEach((bouton) => {
      bouton.addEventListener("click", () => {
        const pieces = tasDeTravail(plateau)?.querySelectorAll(`[data-m-piece="${bouton.dataset.mRetirer}"]`)
        if (!pieces || pieces.length === 0) return

        oublierLeChoix()
        pieces[pieces.length - 1].remove()
        rafraichirLePlateau(plateau)
      })
    })

    plateau.querySelector("[data-m-aligner]")?.addEventListener("click", () => rangerLePlateau(plateau))

    const machine = plateau.querySelector('[data-m-zone="machine"]')
    plateau.addEventListener("m:change", () => {
      if (machine) faireTourenerLaMachine(plateau, machine)
      rafraichirLePlateau(plateau)
    })
    rafraichirLePlateau(plateau)
  })
}

// `DOMContentLoaded` et `turbo:load` se déclenchent TOUS LES DEUX au premier
// chargement. Sans ce garde, chaque écouteur serait posé deux fois, et un clic
// sur « Tout écouter » lancerait deux lectures concurrentes.
function brancherTout() {
  const corps = document.querySelector(".m-carte") || document.body
  if (!corps || corps.dataset.mBranche) return

  corps.dataset.mBranche = "1"
  brancher()
  brancherLesJetons()
  brancherLesPlateaux()
}

document.addEventListener("DOMContentLoaded", brancherTout)
document.addEventListener("turbo:load", brancherTout)
document.addEventListener("turbo:before-cache", () => {
  arreter()
  // Même raison que sur l'éditeur : sans cela, une page restituée par Turbo
  // reviendrait marquée comme déjà branchée, et muette.
  document.querySelectorAll("[data-m-branche]").forEach((e) => delete e.dataset.mBranche)
})
