# frozen_string_literal: true

module ShopifyUI
  # ⓘ icon button wrapped in a Tooltip — the common "explain this field / metric" case in one line.
  #
  #   <%= render ShopifyUI::InfoTooltipComponent.new(text: "Stock last synced 5 minutes ago") %>
  #
  # Takes every TooltipComponent option (position:, delay:, width:, tip slot via the block).
  # label: is the button's accessible name. The icon is 16px; on phones the hit area grows to 32px
  # without moving the surrounding layout.
  class InfoTooltipComponent < ViewComponent::Base
    strip_trailing_whitespace

    BUTTON = %w[
      tw:relative tw:inline-flex tw:size-5 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-full
      tw:border-0 tw:bg-transparent tw:p-0 tw:text-muted tw:cursor-help tw:align-middle
      tw:transition-colors tw:duration-100 tw:hover:text-ink
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-1 tw:focus-visible:outline-link
      tw:max-sm:after:absolute tw:max-sm:after:-inset-1.5 tw:max-sm:after:content-['']
    ].freeze
    ICON = '<circle cx="10" cy="10" r="7.25"/><path d="M10 9v4.5"/><path d="M10 6.5h.01"/>'

    def initialize(text: nil, label: "More information", position: :top, delay: 0, **tooltip_options)
      @text = text
      @label = label
      @tooltip_options = tooltip_options.merge(position: position, delay: delay)
    end

    def call
      rich = content
      render(TooltipComponent.new(text: @text, **@tooltip_options)) do |t|
        t.with_tip { rich } if rich.present?
        tag.button(type: "button", class: BUTTON.join(" "), aria: { label: @label }) { icon }
      end
    end

    private

    def icon
      tag.svg(ICON.html_safe, viewBox: "0 0 20 20", width: 16, height: 16, fill: "none", stroke: "currentColor",
              "stroke-width": 1.6, "stroke-linecap": "round", aria: { hidden: true })
    end
  end
end
