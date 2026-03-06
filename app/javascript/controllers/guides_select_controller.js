import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const path = window.location.pathname
    this.element.value = path.substring(path.lastIndexOf("/") + 1) || "index.html"
  }

  navigate({ target }) {
    Turbo.visit(target.value)
  }
}
