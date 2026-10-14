# frozen_string_literal: true

module ShopifyUI
  class DropdownSelectComponent < ViewComponent::Base
    strip_trailing_whitespace

    WRAPPER = "tw:flex tw:flex-col tw:gap-1 tw:font-sans"
    LABEL = "tw:m-0 tw:text-[13px] tw:font-regular tw:text-ink"
    FIELD = "tw:relative tw:flex tw:items-center"

    SELECT = %w[
      tw:m-0 tw:box-border tw:h-8 tw:w-full tw:cursor-pointer tw:appearance-none tw:rounded-control tw:border
      tw:py-0 tw:pl-3 tw:pr-8 tw:font-sans tw:text-[13px] tw:leading-none tw:transition-colors tw:duration-100
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-1 tw:focus-visible:outline-link
      tw:max-sm:h-10 tw:max-sm:text-[16px]
    ].freeze

    STATES = {
      default: "tw:border-input-border tw:bg-surface tw:text-ink tw:hover:bg-surface-hover",
      error: "tw:border-danger-icon tw:bg-danger-light tw:text-ink",
      disabled: "tw:cursor-not-allowed tw:border-border tw:bg-surface-secondary tw:text-disabled"
    }.freeze

    CHEVRON = "tw:pointer-events-none tw:absolute tw:right-2 tw:size-4"
    CHEVRON_COLORS = {
      default: "tw:text-muted",
      error: "tw:text-muted",
      disabled: "tw:text-disabled"
    }.freeze

    HELP_TEXT = "tw:m-0 tw:text-[13px] tw:text-muted"
    ERROR = "tw:m-0 tw:flex tw:items-center tw:gap-1 tw:text-[13px] tw:text-danger"
    ERROR_ICON = "tw:size-4 tw:shrink-0 tw:text-danger-icon"

    def initialize(name:, options:, label: nil, selected: nil, placeholder: nil, help_text: nil,
                   error: nil, disabled: false, label_hidden: false, id: nil, **html_attributes)
      @name = name
      @options = options
      @label = label
      @selected = selected
      @placeholder = placeholder
      @help_text = help_text
      @error = error
      @disabled = disabled
      @label_hidden = label_hidden
      @id = id || "sui-select-#{SecureRandom.hex(4)}"
      @html_attributes = html_attributes
    end

    private

    def state
      if @disabled then :disabled elsif @error.present? then :error else :default end
    end

    def label_classes
      [ LABEL, ("tw:sr-only" if @label_hidden) ].compact.join(" ")
    end

    def select_attributes
      @html_attributes.merge(
        id: @id,
        name: @name,
        disabled: @disabled || nil,
        class: [ SELECT, STATES[state], @html_attributes[:class] ].flatten.compact.join(" "),
        aria: {
          invalid: (@error.present? || nil),
          describedby: ("#{@id}-description" if @error.present? || @help_text.present?)
        }
      )
    end

    def option_tags
      placeholder = @placeholder ? tag.option(@placeholder, value: "", disabled: true, selected: @selected.nil?) : "".html_safe
      placeholder + helpers.options_for_select(@options, @selected)
    end

    def chevron_classes
      "#{CHEVRON} #{CHEVRON_COLORS[state]}"
    end
  end
end
