# frozen_string_literal: true

require_relative "lib/shopify_ui/version"

Gem::Specification.new do |spec|
  spec.name        = "shopify_ui"
  spec.version     = ShopifyUI::VERSION
  spec.authors     = ["Stackworx"]
  spec.summary     = "Shopify-admin-style ViewComponents, CSS and JS for Rails apps."
  spec.homepage    = "https://github.com/stackworx-co/Shopify-components"
  spec.license     = "Nonstandard"
  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir["app/**/*", "lib/**/*", "VERSION", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "view_component", "~> 3.27"
end
