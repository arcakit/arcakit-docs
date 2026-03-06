import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  show({ target: { scrollY } }) {
    this.element.classList.toggle("show", scrollY > 300)
  }

  scroll(event) {
    event.preventDefault()
    const target = document.querySelector(this.element.getAttribute("href"))
    target?.scrollIntoView({ behavior: "smooth" })
    target?.focus({ preventScroll: true })
  }
}
