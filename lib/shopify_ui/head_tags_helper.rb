# frozen_string_literal: true

module ShopifyUI
  # <%= shopify_ui_head_tags %> in the layout <head>, after the app's own stylesheets.
  module HeadTagsHelper
    # ShopifyInter, served from the same Shopify CDN stylesheet Polaris 2 loads.
    FONT_URL = "https://cdn.shopify.com/static/fonts/shopifyinter/v0/styles.css"

    def shopify_ui_head_tags(stylesheet: true)
      safe_join([
        tag.meta(name: "color-scheme", content: "light"),
        tag.link(rel: "preconnect", href: "https://cdn.shopify.com", crossorigin: ""),
        tag.link(rel: "stylesheet", href: FONT_URL),
        (stylesheet_link_tag("shopify_ui", "data-turbo-track": "reload") if stylesheet)
      ].compact, "\n")
    end
  end
end
