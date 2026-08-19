import { Controller } from "@hotwired/stimulus"

// Rend la toolbar Trix atteignable au clavier (motif « toolbar » du WAI-ARIA).
//
// Trix pose `tabindex="-1"` sur tous ses boutons pour que Tab sorte du champ :
// conséquence, aucun bouton n'était accessible au clavier. On applique un
// tabindex glissant : un seul point d'entrée Tab, puis les flèches circulent
// entre les boutons. Le HTML reste en `tabindex="-1"` : si ce JS ne charge pas,
// on retombe exactement sur le comportement Trix d'origine.
export default class extends Controller {
  connect() {
    this.promote(this.buttons[0])
  }

  keydown(event) {
    const button = event.target.closest(".rt-tb__btn")
    // Les pastilles à l'intérieur d'un popover sont gérées par trix-palette.
    if (!button || !this.element.contains(button)) return

    const buttons = this.buttons
    const index = buttons.indexOf(button)
    if (index === -1) return

    let next
    switch (event.key) {
      case "ArrowRight": next = (index + 1) % buttons.length; break
      case "ArrowLeft": next = (index - 1 + buttons.length) % buttons.length; break
      case "Home": next = 0; break
      case "End": next = buttons.length - 1; break
      default: return
    }

    event.preventDefault()
    this.promote(buttons[next])
    buttons[next].focus()
  }

  // Mémorise le dernier bouton utilisé comme point d'entrée Tab.
  promote(button) {
    if (!button) return
    this.buttons.forEach((other) => other.setAttribute("tabindex", other === button ? "0" : "-1"))
  }

  focusin(event) {
    this.promote(event.target.closest(".rt-tb__btn"))
  }

  get buttons() {
    return Array.from(this.element.querySelectorAll(".rt-tb__btn:not([disabled])"))
  }
}
