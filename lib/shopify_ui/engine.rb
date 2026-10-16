# frozen_string_literal: true

module ShopifyUI
  # Engines autoload app/components automatically; this only fixes the namespace. lib/tasks/*.rake
  # (shopify_ui:tailwind) is loaded automatically by Rails::Engine.
  class Engine < ::Rails::Engine
    # app/components/shopify_ui/ => ShopifyUI (Rails' default would be ShopifyUi).
    initializer "shopify_ui.inflections", before: :set_autoload_paths do
      Rails.autoloaders.each { |loader| loader.inflector.inflect("shopify_ui" => "ShopifyUI") }
    end

    # Prebuilt stylesheet (bin/build-css), so apps need no Tailwind. Works with Sprockets and Propshaft.
    initializer "shopify_ui.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/assets/builds").to_s
        app.config.assets.precompile << "shopify_ui.css" if app.config.assets.respond_to?(:precompile)
      end
    end

    initializer "shopify_ui.helpers" do
      ActiveSupport.on_load(:action_view) { include ShopifyUI::HeadTagsHelper }
    end
  end
end
