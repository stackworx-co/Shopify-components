# frozen_string_literal: true

module ShopifyUI
  # Title + subtitle block, sized on the shared Polaris 2 type scale (TextComponent::SCALE), so page,
  # section and card titles look the same on every page.
  #
  #   <%= render(ShopifyUI::HeadingComponent.new(title: "Shipping", subtitle: "Rates at checkout", size: :section)) do |h| %>
  #     <% h.with_badge(tone: :success) { "Active" } %>
  #     <% h.with_actions do %><%= render(ShopifyUI::ButtonComponent.new) { "Edit" } %><% end %>
  #   <% end %>
  #
  # size:  :page (26px), :section (22px), :card (15px), :subsection (13px)
  # level: heading tag (1–6); defaults to h1 / h2 / h2 / h3 by size.
  # Phones: actions wrap under the title; long titles wrap instead of overflowing.
  class HeadingComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_one :leading
    renders_one :actions
    renders_many :badges, ->(tone: :neutral, appearance: :fill, &block) {
      BadgeComponent.new(tone: tone, appearance: appearance)
    }

    SIZES = {
      page: { title: :display_md, subtitle: :body_md, level: 1, gap: "tw:gap-1" },
      section: { title: :display_sm, subtitle: :body_md, level: 2, gap: "tw:gap-1" },
      card: { title: :heading_lg, subtitle: :body_md, level: 2, gap: "tw:gap-0.5" },
      subsection: { title: :heading_md, subtitle: :body_sm, level: 3, gap: "tw:gap-0.5" }
    }.freeze

    ROOT = "tw:flex tw:min-w-0 tw:flex-wrap tw:items-start tw:gap-x-4 tw:gap-y-3 tw:font-sans"
    MAIN = "tw:flex tw:min-w-0 tw:flex-1 tw:basis-[220px] tw:items-start tw:gap-3"
    LEADING = "tw:flex tw:shrink-0 tw:items-center tw:justify-center"
    STACK = "tw:flex tw:min-w-0 tw:flex-1 tw:flex-col"
    TITLE_ROW = "tw:flex tw:min-w-0 tw:flex-wrap tw:items-center tw:gap-x-2 tw:gap-y-1"
    ACTIONS = "tw:flex tw:shrink-0 tw:flex-wrap tw:items-center tw:gap-2 tw:ml-auto tw:max-sm:ml-0"

    def initialize(title:, subtitle: nil, size: :card, level: nil, title_hidden: false, **html_attributes)
      @title = title
      @subtitle = subtitle
      @size = SIZES.key?(size&.to_sym) ? size.to_sym : :card
      @level = (level || SIZES[@size][:level]).to_i.clamp(1, 6)
      @title_hidden = title_hidden
      @html_attributes = html_attributes
    end

    private

    def config
      SIZES[@size]
    end

    def root_attributes
      @html_attributes.merge(class: [ ROOT, @html_attributes[:class] ].compact.join(" "))
    end

    def title_tag
      render(TextComponent.new(variant: config[:title], as: :"h#{@level}", visually_hidden: @title_hidden)) { @title }
    end

    def subtitle_tag
      render(TextComponent.new(variant: config[:subtitle], tone: :subdued)) { @subtitle }
    end
  end
end
