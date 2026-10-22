# frozen_string_literal: true

module ShopifyUI
  # Shopify admin progress bar (Polaris ProgressBar): a rounded grey track with a coloured fill.
  #
  #   progress: 0–100 (clamped)
  #   tone:     :highlight (default, blue) | :magic (purple) | :primary (black) | :success (green) | :critical (red)
  #   size:     :small (8px) | :medium (16px, default) | :large (32px)
  #   animated: true — the fill grows in from the left on first render (off with reduced motion)
  #   label:    aria-label for screen readers
  class ProgressBarComponent < ViewComponent::Base
    strip_trailing_whitespace

    TRACK = "tw:relative tw:w-full tw:overflow-hidden tw:rounded-full tw:bg-fill-tertiary"

    FILL = %w[
      tw:block tw:h-full tw:w-full tw:origin-left tw:rounded-full tw:scale-x-(--sui-progress)
    ].freeze

    ANIMATION = %w[
      tw:transition-transform tw:duration-500 tw:ease-out tw:starting:scale-x-0
      tw:motion-reduce:transition-none
    ].freeze

    TONES = {
      highlight: "tw:bg-viz-blue",
      magic: "tw:bg-viz-purple",
      primary: "tw:bg-viz-black",
      success: "tw:bg-viz-green",
      critical: "tw:bg-viz-red"
    }.freeze

    SIZES = {
      small: "tw:h-2",
      medium: "tw:h-4",
      large: "tw:h-8"
    }.freeze

    def initialize(progress: 0, tone: :highlight, size: :medium, animated: true, label: nil, **html_attributes)
      @progress = progress.to_f.clamp(0, 100)
      @tone = TONES.key?(tone&.to_sym) ? tone.to_sym : :highlight
      @size = SIZES.key?(size&.to_sym) ? size.to_sym : :medium
      @animated = animated
      @label = label
      @html_attributes = html_attributes
    end

    def call
      tag.div(**track_attributes) do
        tag.span(class: fill_classes, style: "--sui-progress: #{(@progress / 100).round(4)}")
      end
    end

    private

    def track_attributes
      @html_attributes.merge(
        class: [ TRACK, SIZES[@size], @html_attributes[:class] ].compact.join(" "),
        role: "progressbar",
        "aria-label": @label,
        "aria-valuemin": 0,
        "aria-valuemax": 100,
        "aria-valuenow": @progress.round(1)
      )
    end

    def fill_classes
      [ FILL, TONES[@tone], (ANIMATION if @animated) ].flatten.compact.join(" ")
    end
  end
end
