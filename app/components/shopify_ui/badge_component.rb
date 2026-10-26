# frozen_string_literal: true

module ShopifyUI
  class BadgeComponent < ViewComponent::Base
    strip_trailing_whitespace

    BASE = %w[
      tw:inline-flex tw:items-center tw:gap-1.5 tw:max-w-full
      tw:font-sans tw:text-[12px] tw:leading-4 tw:whitespace-nowrap
    ].freeze

    PILL = %w[tw:rounded-full tw:border tw:px-1.5 tw:py-px tw:font-medium].freeze

    FILLS = {
      neutral: "tw:border-transparent tw:bg-neutral-light tw:text-ink",
      info: "tw:border-transparent tw:bg-info-light tw:text-info",
      success: "tw:border-transparent tw:bg-good-light tw:text-good",
      warning: "tw:border-transparent tw:bg-warn-light tw:text-warn",
      critical: "tw:border-transparent tw:bg-danger-light tw:text-danger",
      attention: "tw:border-transparent tw:bg-attention tw:text-on-attention"
    }.freeze

    OUTLINES = {
      neutral: "tw:border-border-hover tw:bg-transparent tw:text-ink-secondary",
      info: "tw:border-info-icon tw:bg-transparent tw:text-info",
      success: "tw:border-good-icon tw:bg-transparent tw:text-good",
      warning: "tw:border-warn-icon tw:bg-transparent tw:text-warn",
      critical: "tw:border-danger-icon tw:bg-transparent tw:text-danger",
      attention: "tw:border-attention tw:bg-transparent tw:text-warn"
    }.freeze

    DOTS = {
      neutral: "tw:bg-neutral",
      info: "tw:bg-info-icon",
      success: "tw:bg-good-icon",
      warning: "tw:bg-warn-icon",
      critical: "tw:bg-danger-icon",
      attention: "tw:bg-attention"
    }.freeze

    DOT_LABEL = "tw:text-[13px] tw:text-muted"
    DOT = "tw:size-1.5 tw:shrink-0 tw:rounded-full"

    APPEARANCES = %i[fill outline dot].freeze

    def initialize(tone: :neutral, appearance: :fill, **html_attributes)
      @tone = FILLS.key?(tone&.to_sym) ? tone.to_sym : :neutral
      @appearance = APPEARANCES.include?(appearance&.to_sym) ? appearance.to_sym : :fill
      @html_attributes = html_attributes
    end

    private

    def dot?
      @appearance == :dot
    end

    def attributes
      @html_attributes.merge(class: classes)
    end

    def classes
      [ BASE, appearance_classes, @html_attributes[:class] ].flatten.compact.join(" ")
    end

    def appearance_classes
      case @appearance
      when :dot then DOT_LABEL
      when :outline then [ PILL, OUTLINES[@tone] ]
      else [ PILL, FILLS[@tone] ]
      end
    end

    def dot_classes
      "#{DOT} #{DOTS[@tone]}"
    end
  end
end
