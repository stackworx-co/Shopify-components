# frozen_string_literal: true

module ShopifyUI
  class CheckboxComponent < ViewComponent::Base
    strip_trailing_whitespace

    INPUT = %w[
      tw:peer tw:m-0 tw:size-4 tw:cursor-pointer tw:appearance-none tw:rounded-[4px]
      tw:border tw:border-input-border tw:bg-surface tw:transition-colors tw:duration-100
      tw:checked:border-accent tw:checked:bg-accent
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-1 tw:focus-visible:outline-link
      tw:disabled:cursor-not-allowed tw:disabled:border-border tw:disabled:bg-surface-secondary
    ].freeze

    CHECK = %w[
      tw:pointer-events-none tw:absolute tw:inset-0 tw:hidden tw:size-4 tw:text-on-accent
      tw:peer-checked:block
    ].freeze

    def initialize(name: nil, value: "1", checked: false, disabled: false, **html_attributes)
      @name = name
      @value = value
      @checked = checked
      @disabled = disabled
      @html_attributes = html_attributes
    end

    private

    def input_attributes
      @html_attributes.merge(
        type: "checkbox",
        name: @name,
        value: @value,
        checked: @checked || nil,
        disabled: @disabled || nil,
        class: [ INPUT, @html_attributes[:class] ].flatten.compact.join(" ")
      )
    end

    def check_classes
      CHECK.join(" ")
    end
  end
end
