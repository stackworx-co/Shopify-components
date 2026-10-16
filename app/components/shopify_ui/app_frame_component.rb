# frozen_string_literal: true

module ShopifyUI
  # Shopify admin app frame: black frame with the Sidebar on the left and the page in a rounded panel.
  #
  # Desktop (lg+): 8px black margin around the panel, all four corners rounded (16px), and only the panel
  # scrolls (the sidebar and frame stay put). The panel clips its scrollbar so the corners stay round.
  # Below lg: the Sidebar's black top bar + slide-in drawer; the page fills the screen and scrolls normally.
  #
  #   <%= render ShopifyUI::AppFrameComponent.new do |frame| %>
  #     <% frame.with_sidebar(sections: [...], store: { name: "My store" }) %>
  #     ...page content...
  #   <% end %>
  #
  # contained: true fills its parent's height instead of the window (for previews / embedded demos).
  class AppFrameComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_one :sidebar, ->(**options) { SidebarComponent.new(contained: @contained, **options) }

    ROOT = {
      viewport: "tw:relative tw:overflow-x-clip tw:min-h-dvh tw:bg-frame tw:font-sans tw:lg:flex tw:lg:h-dvh tw:lg:overflow-hidden",
      contained: "tw:relative tw:overflow-hidden tw:bg-frame tw:font-sans tw:lg:flex tw:lg:h-full"
    }.freeze
    PANEL = "tw:relative tw:min-w-0 tw:flex-1 tw:bg-page tw:lg:my-2 tw:lg:mr-2 tw:lg:overflow-hidden tw:lg:rounded-[16px]"
    SCROLLER = "tw:relative tw:lg:h-full tw:lg:overflow-y-auto tw:lg:overscroll-contain sui-scrollbar tw:lg:[scrollbar-gutter:stable]"
    PANEL_BACKGROUNDS = { page: "tw:bg-page", surface: "tw:bg-surface" }.freeze

    # background: :page (light grey, default) or :surface (white panel).
    def initialize(contained: false, background: :page, main_id: "main-content", **html_attributes)
      @contained = contained
      @background = PANEL_BACKGROUNDS.key?(background&.to_sym) ? background.to_sym : :page
      @main_id = main_id
      @html_attributes = html_attributes
    end

    def call
      panel = tag.main(tag.div(content, class: SCROLLER), id: @main_id,
                       class: PANEL.sub("tw:bg-page", PANEL_BACKGROUNDS[@background]))
      tag.div(safe_join([ sidebar, panel ].compact), **@html_attributes,
              class: [ ROOT[@contained ? :contained : :viewport], @html_attributes[:class] ].compact.join(" "))
    end
  end
end
