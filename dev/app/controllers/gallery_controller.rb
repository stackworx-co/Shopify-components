# frozen_string_literal: true

class GalleryController < ApplicationController
  layout "gallery"

  # Each partial in app/views/components/ is one component section, e.g. _button.html.erb.
  def index
    @sections = Dir[Rails.root.join("app/views/components/_*.html.erb")]
                  .map { |path| File.basename(path, ".html.erb").delete_prefix("_") }
                  .sort
  end
end
