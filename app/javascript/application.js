// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Observe the HTML tag for Google Translate CSS class, to swap lang direction LTR/RTL.
new MutationObserver((mutations) => {
  mutations.forEach((mutation) => {
    if (mutation.type === "attributes" && mutation.attributeName === "class") {
      mutation.target.dir = mutation.target.classList.contains("translated-rtl") ? "rtl" : "ltr"
    }
  })
}).observe(document.querySelector("html"), { attributeFilter: ["class"] })
