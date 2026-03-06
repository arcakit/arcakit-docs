import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["main", "side"]

  connect() {
    if (!this.hasSideTarget) return

    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)")
    this.scrollBehavior = reducedMotion.matches ? "auto" : "smooth"
    reducedMotion.addEventListener("change", ({ matches }) => {
      this.scrollBehavior = matches ? "auto" : "smooth"
    })

    const mobile = window.matchMedia("(max-width: 1024px)")
    this.isMobile = mobile.matches
    mobile.addEventListener("change", ({ matches }) => { this.isMobile = matches })

    this.elements = Array.from(this.mainTarget.querySelectorAll("h2, h3, p, div, ol, ul"))
    this.direction = "up"
    this.prevY = 0
    this.frameId = null

    this.observer = new IntersectionObserver(this.#onIntersect.bind(this), {
      threshold: [0, 0.5, 1],
      rootMargin: "-10px 0px 0px 0px"
    })
    this.elements.forEach(el => this.observer.observe(el))

    window.addEventListener("scrollend", this.#onScrollEnd)
  }

  disconnect() {
    this.observer?.disconnect()
    window.removeEventListener("scrollend", this.#onScrollEnd)
  }

  #onIntersect(entries) {
    this.direction = document.scrollingElement.scrollTop > this.prevY ? "down" : "up"
    this.prevY = document.scrollingElement.scrollTop

    const intersecting = entries.flatMap(entry => {
      if (!this.#atTop(entry) || !entry.isIntersecting) return []
      const idx = this.elements.indexOf(entry.target)
      return [this.direction === "down" && entry.intersectionRatio < 0.6
        ? this.elements[idx + 1] ?? null
        : entry.target]
    })

    if (intersecting.length > 0) {
      const target = intersecting[this.direction === "down" ? intersecting.length - 1 : 0]
      this.#highlight(this.#navLink(target))
    }
  }

  #onScrollEnd = () => {
    cancelAnimationFrame(this.frameId)
    this.frameId = requestAnimationFrame(() => {
      const active = this.sideTarget.querySelector("a[aria-current]")
      if (active) this.#highlight(active, true)
    })
  }

  #atTop(entry) {
    if (!entry.rootBounds) return false
    return entry.rootBounds.bottom - entry.boundingClientRect.bottom > entry.rootBounds.bottom / 2
  }

  #navLink(elem) {
    if (!elem) elem = this.elements[0]
    for (let i = this.elements.indexOf(elem); i >= 0; i--) {
      const anchor = this.elements[i].querySelector("a.anchorlink[href]:not([href=''])")
      if (anchor) return this.sideTarget.querySelector(`a[href="${anchor.getAttribute("href")}"]`)
    }
  }

  #highlight(elem, force = false) {
    if (!elem || (!force && elem.hasAttribute("aria-current"))) return
    this.sideTarget.querySelectorAll("[aria-current]").forEach(el => el.removeAttribute("aria-current"))
    elem.setAttribute("aria-current", "true")
    if (this.isMobile) return
    cancelAnimationFrame(this.frameId)
    this.frameId = requestAnimationFrame(() => {
      elem.scrollIntoView({ behavior: this.scrollBehavior, block: "center", inline: "center" })
    })
  }
}
