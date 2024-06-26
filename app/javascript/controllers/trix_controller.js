import { Controller } from "@hotwired/stimulus"
import Trix from "trix"

export default class extends Controller {
  static values = {
    defaultColor: { type: String, default: "#000000" },
    color: { type: String, default: "#000000" },
  }

  static classes = ["active", "inactive", "linkError"]
  static targets = ["backgroundColor", "textColor", "underlineColorPicker", "underlineColorPickerModal", "fontSizeControls", "fontSizeInput"]

  initialize() {
    this.textToolBox = this.element.querySelector(".trix-button-group--text-tools")
    this.allowSync = true
    this.setupTrix()
    this.#addTool()
  }

  changeColor(e) {
    this.colorValue = e.detail
    if (this.backgroundColorTarget.contains(e.target)) {
      this.trixEditor.activateAttribute("backgroundColor", e.detail)
    } else if (this.textColorTarget.contains(e.target)) {
      this.trixEditor.activateAttribute("foregroundColor", e.detail)
    } else {
      this.trixEditor.activateAttribute("underlineColor", e.detail)
    }
  }

  connect() {
    this.element.classList.add(...this.inactiveClasses)
    this.element.classList.remove(...this.activeClasses)
  }

  markSelection() {
    this.trixEditor.activateAttribute("frozen")
    this.fontSizeInputTarget.focus()
    this.trix.blur()
  }

  setupTrix() {
    Trix.config.textAttributes.foregroundColor = {
      styleProperty: "color",
      inheritable: 1
    }

    Trix.config.textAttributes.backgroundColor = {
      styleProperty: "background-color",
      inheritable: 1
    }

    Trix.config.textAttributes.underline = {
      style: { textDecoration: "underline" },
      parser: function (element) {
        return element.style.textDecoration === "underline"
      },
      inheritable: 1
    }

    Trix.config.textAttributes.underlineColor = {
      styleProperty: "text-decoration-color",
      inheritable: 1
    }

    // Trix.config.textAttributes.fontSize = {
    //   styleProperty: "font-size",
    //   inheritable: 1
    // }

    this.trix = this.element.querySelector("trix-editor")
  }

  // changeSelectionFontSize({ detail: font }) {
  //   this.trixEditor.activateAttribute("fontSize", font.px)
  //   this.trixEditor.deactivateAttribute("frozen")
  // }

  toggleUnderline() {
    if (this.trixEditor.attributeIsActive("underline")) {
      this.trixEditor.deactivateAttribute("underline")
    } else {
      this.trixEditor.activateAttribute("underline")
    }

    this.trix.focus()
  }

  sync() {
    if (this.trixEditor.attributeIsActive("underline")) {
      this.underlineColorPickerTarget.disabled = false
      this.underlineColorPickerTarget.classList.remove("text-gray-300")
    } else {
      this.underlineColorPickerTarget.disabled = true
      this.underlineColorPickerTarget.classList.add("text-gray-300")
    }

    // if (this.pieceAtCursor.attributes.has("fontSize")) {
    //   this.dispatch("font-size:sync", {
    //     target: this.fontSizeControlsTarget,
    //     detail: this.pieceAtCursor.getAttribute("fontSize")
    //   })
    // }
  }

  toggleUnderlineColorPicker() {
    const piece = this.pieceAtCursor

    if (piece.attributes.has("underline")) {
      const indexOfPiece = this.trixEditorDocument.toString().indexOf(piece.toString())
      const textRange = [indexOfPiece, indexOfPiece + piece.length]
      this.trixEditor.setSelectedRange(textRange)
    }

    this.underlineColorPickerModalTarget.classList.toggle("hidden")
  }

  get pieceAtCursor() {
    return this.trixEditorDocument.getPieceAtPosition(this.trixEditor.getPosition())
  }

  get trixEditor() {
    return this.trix.editor
  }

  get trixEditorDocument() {
    return this.trix.editor.getDocument()
  }

  // get fontSizeDropdownLabelContainer() {
  //   return this.element.querySelector('[data-custom-dropdown-target="placeholderText"]')
  // }

  get currentState() {
    return {
      boldValue: this.boldValue,
      italicValue: this.italicValue,
      alignmentValue: this.alignmentInputTarget.value,
      color: this.colorValue,
      sizeValue: this.sizeValue,
      trix: this.trix
    }
  }

  #addTool() {
    this.textToolBox.insertAdjacentHTML("beforeend", `
      <div data-action="click->trix#toggleUnderline" class="underline-btn">
        <i class="fa-solid fa-underline"></i>
      </div>
      <div data-controller="dropdown color-picker"
           data-trix-target="backgroundColor"
           class="d-flex flex-column justify-content-center align-items-center" style="width: 32px; height: 26px; padding: 2px">
        <div class="add-trix-btn" data-action="click->dropdown#toggle">
          <svg viewBox="0 0 16 18" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <g id="Symbols" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
              <g id="Icons/Editor/Background" transform="translate(-5.000000, -2.000000)" fill="currentColor" fill-rule="nonzero">
                <g id="noun-color-fill-878618" transform="translate(5.000000, 2.000000)">
                  <path d="M7.11093587,17.4407114 C6.51717373,17.4407114 5.95899314,17.2067204 5.5393291,16.781985 L0.721726143,11.9042166 C0.249680292,11.4253884 0,10.8160723 0,10.1401816 C0,9.47420383 0.256849934,8.84683625 0.721726143,8.37703378 L6.14124375,2.88983356 L4.81859345,1.53168786 C4.47364683,1.17791271 4.47722022,0.608244438 4.82752236,0.259132606 C5.17693381,-0.0892155082 5.73869923,-0.0865039225 6.0843811,0.268173025 L13.9271766,8.31614383 C14.7804478,9.19094843 14.7761429,10.6111559 13.9173551,11.4823347 L8.68184053,16.7824626 C8.26324318,17.2072134 7.7048721,17.4411889 7.11114806,17.4411889 L7.11093587,17.4407114 Z M7.39010617,4.1701417 L1.9785887,9.64924189 C1.81236501,9.81754148 1.77769397,10.0082898 1.77769397,10.1396802 C1.77769397,10.3385632 1.83989689,10.4898373 1.9785887,10.6301185 L6.79619165,15.5078869 C6.90913827,15.6231505 7.04158235,15.6392696 7.11092825,15.6392696 C7.17938271,15.6392696 7.31182298,15.6222437 7.42477341,15.5078869 L12.6595261,10.2085305 C12.8293193,10.0357103 12.831106,9.75303815 12.6613118,9.57857866 L7.38998708,4.16967884 L7.39010617,4.1701417 Z M12.4442844,16.0802899 C12.4442844,14.6915569 13.9696047,13.6088512 14.2221422,12.2400212 C14.4772055,13.609777 16,14.6997341 16,16.0802899 C16,17.1405469 15.2044441,18 14.2221422,18 C13.2398404,18 12.4442844,17.1404312 12.4442844,16.0802899 Z M14.5776528,9.89995749 L7.40686835,17.1602956 L1.35000694,11.027792 C1.04241332,10.7154505 0.888704124,9.90003463 0.888704124,9.90003463 L14.5776528,9.89995749 Z" id="Shape"></path>
                </g>
              </g>
            </g>
          </svg>
        </div>

        <div data-dropdown-target="menu"  class=" hidden trix-color-pickr">
          <div data-color-picker-target="picker">

          </div>
        </div>

      </div>
      <div data-controller="dropdown color-picker"
           data-trix-target="textColor"
           class= "d-flex flex-column justify-content-center align-items-center" style="width: 32px; height: 26px; padding: 2px">
        <div class="add-trix-btn" data-action="click->dropdown#toggle">
          <svg viewBox="0 0 18 21" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <g id="Dashboard/Capture/New" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
              <g id="/business/capture/popup/design/edit/hero/editor" transform="translate(-801.000000, -436.000000)">
                <g id="Editor" transform="translate(704.000000, 422.000000)" fill="currentColor" fill-rule="nonzero">
                  <g id="Actions" transform="translate(14.000000, 6.000000)">
                    <g id="Group" transform="translate(78.000000, 4.000000)">
                      <path d="M14.3352609,4.53459997 C14.1747055,4.2068336 13.8484666,4 13.4917668,4 C13.1354064,4 12.8091674,4.2068336 12.6482727,4.53459997 L6.14369795,17.9543737 C5.98344333,18.2824497 5.95602862,18.6623154 6.06748582,19.0111263 C6.17864072,19.359977 6.41962802,19.6492979 6.73743049,19.8158365 C7.05793974,19.9795649 7.42815791,20.0056106 7.76731379,19.8883977 C8.10650051,19.7711801 8.38634653,19.5203204 8.54572203,19.1906886 L9.59850876,17.0374122 L17.3717949,17.0374122 L18.4242732,19.1906886 C18.5767005,19.5321009 18.8568473,19.7956778 19.2011391,19.9206433 C19.5454463,20.0459183 19.9244017,20.0220398 20.2512267,19.8549042 C20.578368,19.6874528 20.825378,19.3906936 20.9362322,19.0328885 C21.0470863,18.6747342 21.0124443,18.2855647 20.8398372,17.9543849 L14.3352609,4.53459997 Z M10.9481749,14.2590737 L13.2152291,9.57727544 C13.2703546,9.47742693 13.3733784,9.41571423 13.4851349,9.41571423 C13.5968913,9.41571423 13.6999182,9.47742217 13.7550406,9.57727544 L16.0220949,14.2590737 L10.9481749,14.2590737 Z" id="Shape"></path>
                    </g>
                  </g>
                </g>
              </g>
            </g>
          </svg>
        </div>

        <div data-dropdown-target="menu" class="hidden trix-color-pickr">
          <div data-color-picker-target="picker">

          </div>
        </div>

      </div >`
    )
  }
}
