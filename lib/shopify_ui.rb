# frozen_string_literal: true

require "view_component"
require "shopify_ui/version"
require "shopify_ui/head_tags_helper"
require "shopify_ui/engine"

module ShopifyUI
  # Absolute path to the Tailwind theme, for the host app's Tailwind entry file.
  def self.theme_css_path
    Engine.root.join("app", "assets", "stylesheets", "shopify_ui", "theme.css").to_s
  end
end
