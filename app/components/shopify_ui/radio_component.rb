# frozen_string_literal: true

module ShopifyUI
  # Shopify admin radio button (Polaris RadioButton): native <input type=radio>, no JavaScript.
  # Covers: checked / unchecked, label, hidden label, help text, disabled, error ring, and a card appearance
  # (bordered tile that highlights when selected). Phones: 20px control, whole row is a 44px tap target.
  class RadioComponent < ViewComponent::Base
    strip_trailing_whitespace

    INPUT = %w[
      tw:peer tw:m-0 tw:mt-0.5 tw:size-4 tw:shrink-0 tw:cursor-pointer tw:appearance-none tw:rounded-full
      tw:border tw:border-input-border tw:bg-surface tw:transition-[border-width,border-color] tw:duration-100
      tw:motion-reduce:transition-none
      tw:hover:border-ink tw:checked:border-[5px] tw:checked:border-accent tw:checked:hover:border-accent-hover
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-1 tw:focus-visible:outline-link
      tw:disabled:cursor-not-allowed tw:disabled:border-border tw:disabled:bg-surface-secondary
      tw:disabled:checked:border-disabled tw:disabled:checked:bg-surface
      tw:max-sm:size-6 tw:max-sm:mt-0 tw:max-sm:checked:border-[7px]
    ].freeze
    INPUT_ERROR = "tw:border-danger-icon tw:bg-danger-light"

    ROW = "tw:flex tw:items-start tw:gap-2 tw:cursor-pointer tw:has-disabled:cursor-not-allowed tw:max-sm:min-h-11 tw:max-sm:items-center tw:max-sm:gap-2.5"
    CARD = %w[
      tw:rounded-[12px] tw:border tw:border-border tw:bg-surface tw:p-3 tw:transition-colors tw:duration-100
      tw:hover:bg-surface-hover tw:has-checked:border-accent tw:has-checked:ring-1 tw:has-checked:ring-accent
      tw:has-disabled:bg-surface-secondary tw:has-disabled:hover:bg-surface-secondary tw:max-sm:items-start tw:max-sm:p-3.5
    ].freeze
    TEXT = "tw:flex tw:min-w-0 tw:flex-col tw:gap-0.5"
    LABEL = "tw:text-[13px] tw:leading-5 tw:text-ink tw:break-words tw:peer-disabled:text-disabled tw:max-sm:text-[14px]"
    HELP = "tw:text-[13px] tw:leading-5 tw:text-muted"

    def initialize(name:, value:, label:, checked: false, help_text: nil, disabled: false, label_hidden: false,
                   error: false, appearance: :default, id: nil, **html_attributes)
      @name = name
      @value = value
      @label = label
      @checked = checked
      @help_text = help_text
      @disabled = disabled
      @label_hidden = label_hidden
      @error = error
      @card = appearance&.to_sym == :card
      @id = id || "sui-radio-#{SecureRandom.hex(4)}"
      @html_attributes = html_attributes
    end

    def call
      input = tag.input(type: "radio", id: @id, name: @name, value: @value, checked: @checked || nil, disabled: @disabled || nil,
                        class: [ INPUT, (INPUT_ERROR if @error) ].flatten.compact.join(" "),
                        aria: { describedby: ("#{@id}-help" if @help_text.present?), invalid: (@error || nil) }, **@html_attributes)
      text = tag.span(safe_join([
        tag.span(@label, class: [ LABEL, ("tw:sr-only" if @label_hidden) ].compact.join(" ")),
        (tag.span(@help_text, id: "#{@id}-help", class: HELP) if @help_text.present?)
      ].compact), class: TEXT)
      tag.label(safe_join([ input, text ]), for: @id, class: [ ROW, (CARD if @card) ].flatten.compact.join(" "))
    end
  end
end
