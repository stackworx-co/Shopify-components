# frozen_string_literal: true

module ShopifyUI
  # Engines autoload app/components automatically; this only fixes the namespace. lib/tasks/*.rake
  # (shopify_ui:tailwind) is loaded automatically by Rails::Engine.
  class Engine < ::Rails::Engine
    # app/components/shopify_ui/ => ShopifyUI (Rails' default would be ShopifyUi).
    initializer "shopify_ui.inflections", before: :set_autoload_paths do
      Rails.autoloaders.each { |loader| loader.inflector.inflect("shopify_ui" => "ShopifyUI") }
    end
  end
end
