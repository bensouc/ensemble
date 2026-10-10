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

// Les racines d'outil. C'est par elles que `deposer` retrouve à QUI annoncer
// un changement : un outil absent de cette liste déposerait sans jamais
// recompter ses zones.
const RACINES = "[data-m-jetons], [data-m-plateau], [data-m-partage]"

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

  placerDans(jeton, zone, point)

  const outil = zone.closest(RACINES)
  if (outil) {
    compter(outil)
    outil.dispatchEvent(new CustomEvent("m:change", { bubbles: false }))
  }
}

// Une zone « libre » garde la pièce où elle tombe : l'élève range comme il
// veut, et un bouton alignera quand LUI le décidera. Ailleurs, la pièce
// reprend le flux.
function placerDans(jeton, zone, point) {
  const tas = zone.querySelector("[data-m-tas]")
  if (!tas) return

  if (!zone.hasAttribute("data-m-libre") || !point) {
    jeton.style.position = ""
    jeton.style.left = ""
    jeton.style.top = ""
    return
  }

  const cadre = tas.getBoundingClientRect()
  const borner = (valeur, taille, dispo) => Math.max(0, Math.min(valeur, dispo - taille))
  jeton.style.position = "absolute"
  jeton.style.left = `${borner(point.x - cadre.left - (jeton.offsetWidth / 2), jeton.offsetWidth, cadre.width)}px`
  jeton.style.top = `${borner(point.y - cadre.top - (jeton.offsetHeight / 2), jeton.offsetHeight, cadre.height)}px`
}

function oublierLeChoix() {
  if (jetonChoisi) jetonChoisi.classList.remove("m-jeton-choisi")
  jetonChoisi = null
}

function zoneSous(x, y) {
  const sous = document.elementFromPoint(x, y)
  return sous ? sous.closest("[data-m-zone]") : null
}

function brancherUnePiece(jeton, outil, accepte = () => true) {
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
        // Un simple appui : on choisit le jeton, la case viendra ensuite.
        // Tout ce qui répond au tapotement passe par ici et jamais par
        // `click` : `pointerdown` appelle `preventDefault()`, ce qui empêche
        // le `click` de suivre.
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
  outil.querySelectorAll("[data-m-zone]").forEach((zone) => brancherUneZone(zone, outil, accepte))
}

// Une zone à la fois, parce que le partage en fabrique en cours de route :
// une boîte ajoutée après le branchement n'accueillerait rien.
function brancherUneZone(zone, outil, accepte = () => true) {
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

function maximumDe(plateau, sorte) {
  const brut = sorte === "barre" ? plateau.dataset.maxDizaines : plateau.dataset.maxUnites
  const lu = Number(brut)
  return Number.isFinite(lu) && lu > 0 ? lu : 9
}

function placeLibre(plateau, sorte, combien = 1) {
  return combienEnTravail(plateau, sorte) + combien <= maximumDe(plateau, sorte)
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
function faireTournerLaMachine(plateau, machine) {
  const dedans = machine.querySelector("[data-m-tas]")
  if (!dedans) return

  // Ce qui sort de la machine se range dans le flux, à la suite. Le poser aux
  // coordonnées de la machine le tassait contre un bord de la zone, et dix
  // unités se recouvraient les unes les autres.
  //
  // Et on vérifie D'ABORD que le résultat a où aller. Sans ce garde, une
  // dizaine poussée dans la machine alors que la zone était pleine
  // disparaissait et il en ressortait moins de dix unités : le total chutait
  // en silence. Or le total qui ne bouge pas est le seul enseignement de
  // l'outil. La pièce reste alors dans la machine, et l'élève la ressort.
  const barre = dedans.querySelector('[data-m-piece="barre"]')
  if (barre) {
    if (!placeLibre(plateau, "unite", 10)) return

    barre.remove()
    for (let i = 0; i < 10; i += 1) poserUnePiece(plateau, "unite")
    return
  }

  const unites = dedans.querySelectorAll('[data-m-piece="unite"]')
  if (unites.length < 10 || !placeLibre(plateau, "barre")) return

  Array.from(unites).slice(0, 10).forEach((u) => u.remove())
  poserUnePiece(plateau, "barre")
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

// Deux façons d'ajouter une pièce, et une seule mécanique : on TOUCHE la
// pioche, la pièce se pose dans la zone ; on la GLISSE, elle suit le doigt et
// se pose où on la lâche.
//
// Les deux passent par `pointerdown` — qui appelle `preventDefault()`, sans
// quoi le navigateur fait défiler la page au lieu de laisser glisser. Un
// écouteur `click` posé à côté ne partirait jamais au doigt : c'est le piège
// qui a déjà fait que toucher une dizaine ne l'ouvrait pas.
function brancherLaPioche(bouton, plateau) {
  // Au clavier : `pointerdown` appelle `preventDefault()`, donc le `click`
  // que le navigateur émettrait sur Entrée ou Espace n'arrive jamais. Sans
  // cet écouteur, la pioche était inatteignable autrement qu'au doigt.
  bouton.addEventListener("keydown", (e) => {
    if (e.key !== "Enter" && e.key !== " ") return

    e.preventDefault()
    poserUnePiece(plateau, bouton.dataset.mPiocher)
  })

  bouton.addEventListener("pointerdown", (e) => {
    e.preventDefault()

    const piece = poserUnePiece(plateau, bouton.dataset.mPiocher)
    if (!piece) return

    const zone = plateau.querySelector('[data-m-zone="travail"]')
    const depart = { x: e.clientX, y: e.clientY }
    let glisse = false

    const bouger = (ev) => {
      if (!glisse && Math.hypot(ev.clientX - depart.x, ev.clientY - depart.y) < SEUIL_GLISSE) return

      glisse = true
      piece.classList.add("m-jeton-vole")
      // On la POSITIONNE, on ne la redépose pas : `deposer` réinsère le nœud
      // et émet `m:change` — soit, à chaque mouvement de souris, une
      // réinsertion dans le DOM et un tour de la machine pour rien.
      placerDans(piece, zone, { x: ev.clientX, y: ev.clientY })
    }

    const lacher = (ev) => {
      document.removeEventListener("pointermove", bouger)
      document.removeEventListener("pointerup", lacher)
      document.removeEventListener("pointercancel", lacher)
      piece.classList.remove("m-jeton-vole")
      // Un simple appui : la pièce est déjà posée dans la zone, à la suite.
      if (!glisse) return

      const cible = zoneSous(ev.clientX, ev.clientY)
      if (cible && plateau.contains(cible) && accepteLaPiece(piece, cible)) {
        deposer(piece, cible, { x: ev.clientX, y: ev.clientY })
      } else {
        // Lâchée hors de toute zone : elle n'a jamais existé.
        piece.remove()
      }
      rafraichirLePlateau(plateau)
    }

    document.addEventListener("pointermove", bouger)
    document.addEventListener("pointerup", lacher)
    document.addEventListener("pointercancel", lacher)
  })
}

function brancherLesPlateaux() {
  document.querySelectorAll("[data-m-plateau]").forEach((plateau) => {
    plateau.querySelectorAll("[data-m-piece]").forEach((piece) => brancherUnePiece(piece, plateau, accepteLaPiece))
    brancherLesZones(plateau, accepteLaPiece)

    plateau.querySelectorAll("[data-m-piocher]").forEach((bouton) => brancherLaPioche(bouton, plateau))

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
      if (machine) faireTournerLaMachine(plateau, machine)
      rafraichirLePlateau(plateau)
    })
    rafraichirLePlateau(plateau)
  })
}

// ── l'horloge ──────────────────────────────────────────────────────────
//
// Un outil de MANIPULATION : l'élève attrape une aiguille et la fait tourner.
// Pas une horloge à lire — c'est en la réglant qu'il comprend ce que chaque
// aiguille raconte.
//
// Les deux s'entraînent, comme sur une vraie : passer la grande de 55 à 0
// avance la petite d'une heure, et poser la petite entre le 3 et le 4 pose la
// demie. Une horloge dont les minutes tourneraient sans emporter les heures
// enseignerait quelque chose de faux — et c'est l'erreur que font les enfants
// qu'on veut précisément corriger.

const TOUR = 12 * 60 // le cadran ne connaît pas l'après-midi

function minutesDe(horloge) {
  const lu = Number(horloge.dataset.mMinutes)
  return Number.isFinite(lu) ? ((lu % TOUR) + TOUR) % TOUR : 0
}

function pasDe(horloge) {
  const lu = Number(horloge.dataset.mPas)
  return Number.isFinite(lu) && lu > 0 ? lu : 5
}

// L'angle du point touché, vu du centre du cadran : 0 en haut, puis dans le
// sens des aiguilles. `atan2(dx, -dy)` donne exactement cela, sans quart de
// tour à rattraper ensuite.
//
// Le point passe par le repère du DESSIN, pas par le rectangle de l'élément.
// Un SVG à qui il reste de la place centre son dessin dedans : le rectangle
// vaut alors 224 de large pour 201 de haut, le cadran 201 par 201 au milieu,
// et l'angle calculé sur le rectangle rate le chiffre visé d'autant.
function angleDe(cadran, x, y) {
  const repere = cadran.getScreenCTM()
  if (!repere) return 0

  const point = new DOMPoint(x, y).matrixTransform(repere.inverse())
  return ((Math.atan2(point.x - 100, 100 - point.y) * 180 / Math.PI) + 360) % 360
}

function afficherLHeure(horloge) {
  const minutes = minutesDe(horloge)
  const tourner = (sorte, degres) => {
    horloge.querySelector(`[data-m-aiguille="${sorte}"]`)?.setAttribute("transform", `rotate(${degres}, 100, 100)`)
  }

  tourner("minute", (minutes % 60) * 6)
  // La petite aiguille avance d'un demi-degré par minute : à 3 h 30 elle est
  // à mi-chemin entre le 3 et le 4, et c'est ce demi-chemin qui dit la demie.
  tourner("heure", minutes / 2)

  const texte = `${Math.floor(minutes / 60) || 12} h ${String(minutes % 60).padStart(2, "0")}`
  const lecture = horloge.querySelector("[data-m-heure]")
  if (lecture) lecture.textContent = texte
  // L'heure est dite aux aiguilles elles-mêmes : au clavier, c'est le seul
  // endroit où elle se lit quand l'enseignante a choisi de la cacher.
  horloge.querySelectorAll("[data-m-aiguille]").forEach((a) => a.setAttribute("aria-valuetext", texte))
}

function regler(horloge, minutes) {
  horloge.dataset.mMinutes = ((Math.round(minutes) % TOUR) + TOUR) % TOUR
  afficherLHeure(horloge)
}

// Poser la grande aiguille EMPORTE les heures quand elle passe par le douze :
// c'est ce que fait une vraie horloge. On le reconnaît au saut — de la fin du
// cadran au début, ou l'inverse — parce que l'angle seul ne dit pas de quel
// côté on a tourné.
function poserLesMinutes(horloge, angle) {
  const pas = pasDe(horloge)
  const minutes = minutesDe(horloge)
  const avant = minutes % 60
  const apres = (Math.round(angle / 6 / pas) * pas) % 60

  let heures = Math.floor(minutes / 60)
  if (avant >= 45 && apres <= 15) heures += 1
  else if (avant <= 15 && apres >= 45) heures -= 1

  regler(horloge, (heures * 60) + apres)
}

// La petite aiguille porte l'heure ET sa fraction : la poser quelque part,
// c'est poser l'heure entière, minutes comprises.
function poserLesHeures(horloge, angle) {
  const pas = pasDe(horloge)
  regler(horloge, Math.round((angle / 360) * TOUR / pas) * pas)
}

function poserLAiguille(horloge, cadran, sorte, x, y) {
  const angle = angleDe(cadran, x, y)
  if (sorte === "minute") poserLesMinutes(horloge, angle)
  else poserLesHeures(horloge, angle)
}

function brancherLHorloge(horloge) {
  const cadran = horloge.querySelector("[data-m-cadran]")
  if (!cadran) return

  const saisir = (sorte) => (e) => {
    // Sans cela, le navigateur fait défiler la page au lieu de laisser
    // tourner l'aiguille — le premier contact serait le dernier.
    e.preventDefault()
    poserLAiguille(horloge, cadran, sorte, e.clientX, e.clientY)

    const bouger = (ev) => poserLAiguille(horloge, cadran, sorte, ev.clientX, ev.clientY)
    const lacher = () => {
      document.removeEventListener("pointermove", bouger)
      document.removeEventListener("pointerup", lacher)
      document.removeEventListener("pointercancel", lacher)
    }
    document.addEventListener("pointermove", bouger)
    document.addEventListener("pointerup", lacher)
    document.addEventListener("pointercancel", lacher)
  }

  horloge.querySelectorAll("[data-m-aiguille]").forEach((aiguille) => {
    const sorte = aiguille.dataset.mAiguille
    aiguille.addEventListener("pointerdown", saisir(sorte))

    // Même piège que la pioche du plateau : `pointerdown` appelle
    // `preventDefault()`, donc le `click` d'Entrée n'arrive jamais. Les
    // flèches font avancer l'aiguille d'un pas — d'une heure pour la petite.
    aiguille.addEventListener("keydown", (e) => {
      const sens = ["ArrowRight", "ArrowUp"].includes(e.key) ? 1 : ["ArrowLeft", "ArrowDown"].includes(e.key) ? -1 : 0
      if (!sens) return

      e.preventDefault()
      regler(horloge, minutesDe(horloge) + (sens * (sorte === "minute" ? pasDe(horloge) : 60)))
    })
  })

  // Toucher le cadran ailleurs que sur une aiguille déplace la grande : c'est
  // le geste que font les enfants, et le refuser n'apprendrait rien à
  // personne.
  cadran.addEventListener("pointerdown", (e) => {
    if (e.target.closest("[data-m-aiguille]")) return

    saisir("minute")(e)
  })

  afficherLHeure(horloge)
}

function brancherLesHorloges() {
  document.querySelectorAll("[data-m-horloge]").forEach(brancherLHorloge)
}

// ── le partage en boîtes ───────────────────────────────────────────────
//
// L'élève glisse les objets dans des boîtes, et c'est LUI qui ajoute et retire
// les boîtes : « combien de paquets peux-tu faire ? » est souvent la question
// même du problème, et la lui donner déjà résolue n'aiderait personne.
//
// Retirer une boîte ne perd jamais rien : ce qu'elle contenait retourne à la
// réserve. Même règle que la case qui échange — un outil qui fait disparaître
// des objets enseigne le contraire de ce qu'on veut.

function boitesDe(partage) {
  return Array.from(partage.querySelectorAll("[data-m-boites] > [data-m-zone]"))
}

function maximumDeBoites(partage) {
  const lu = Number(partage.dataset.mMaxBoites)
  return Number.isFinite(lu) && lu > 0 ? lu : 8
}

// Les boîtes portent leur rang, pas leur identité : en retirer une au milieu
// laisserait sinon « Boîte 1, Boîte 3 » à l'écran.
function renumeroterLesBoites(partage) {
  boitesDe(partage).forEach((boite, rang) => {
    const nom = boite.querySelector("[data-m-nom]")
    if (nom) nom.textContent = `Boîte ${rang + 1}`
  })
}

function ajouterUneBoite(partage) {
  const liste = partage.querySelector("[data-m-boites]")
  const modele = partage.querySelector("[data-m-modele-boite]")
  if (!liste || !modele || boitesDe(partage).length >= maximumDeBoites(partage)) return

  const boite = modele.content.firstElementChild.cloneNode(true)
  liste.appendChild(boite)
  brancherUneZone(boite, partage)
  renumeroterLesBoites(partage)
  compter(partage)
}

function retirerUneBoite(partage) {
  const boites = boitesDe(partage)
  const derniere = boites[boites.length - 1]
  const reserve = partage.querySelector('[data-m-zone="reserve"]')
  if (!derniere || !reserve) return

  oublierLeChoix()
  // Vider AVANT de retirer : la boîte emporterait ses objets avec elle.
  Array.from(derniere.querySelector("[data-m-tas]")?.children || []).
    forEach((jeton) => deposer(jeton, reserve))
  derniere.remove()
  renumeroterLesBoites(partage)
  compter(partage)
}

function brancherLesPartages() {
  document.querySelectorAll("[data-m-partage]").forEach((partage) => {
    partage.querySelectorAll("[data-m-jeton]").forEach((jeton) => brancherUnePiece(jeton, partage))
    brancherLesZones(partage)

    partage.querySelector("[data-m-ajouter-boite]")?.addEventListener("click", () => ajouterUneBoite(partage))
    partage.querySelector("[data-m-retirer-boite]")?.addEventListener("click", () => retirerUneBoite(partage))

    renumeroterLesBoites(partage)
    compter(partage)
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
  brancherLesHorloges()
  brancherLesPartages()
}

document.addEventListener("DOMContentLoaded", brancherTout)
document.addEventListener("turbo:load", brancherTout)
document.addEventListener("turbo:before-cache", () => {
  arreter()
  // Même raison que sur l'éditeur : sans cela, une page restituée par Turbo
  // reviendrait marquée comme déjà branchée, et muette.
  document.querySelectorAll("[data-m-branche]").forEach((e) => delete e.dataset.mBranche)
})
