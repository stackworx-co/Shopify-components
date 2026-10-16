# frozen_string_literal: true

module ShopifyUI
  # <%= shopify_ui_head_tags %> in the layout <head>, after the app's own stylesheets.
  module HeadTagsHelper
    FONT_URL = "https://fonts.googleapis.com/css2?family=Inter:wght@450;550;650;700&display=swap"

    def shopify_ui_head_tags(stylesheet: true)
      safe_join([
        tag.meta(name: "color-scheme", content: "light"),
        tag.link(rel: "preconnect", href: "https://fonts.googleapis.com"),
        tag.link(rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: ""),
        tag.link(rel: "stylesheet", href: FONT_URL),
        (stylesheet_link_tag("shopify_ui", "data-turbo-track": "reload") if stylesheet)
      ].compact, "\n")
    end
  end
end
