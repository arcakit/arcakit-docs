import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "panel"]
  static classes = ["open"]

  toggle(event) {
    event.preventDefault()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.panelTarget.classList.add(...this.openClasses)
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.panelTarget.querySelector("a")?.focus()
  }

  close() {
    this.panelTarget.classList.remove(...this.openClasses)
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.buttonTarget.focus()
  }

  closeOnOutsideClick({ target }) {
    if (this.isOpen && !this.element.contains(target)) this.close()
  }

  get isOpen() {
    return this.buttonTarget.getAttribute("aria-expanded") === "true"
  }
}
