# frozen_string_literal: true

module ShopifyUI
  # Shopify admin choice list (Polaris ChoiceList): titled group of radios (or checkboxes with allow_multiple).
  # Covers: title / hidden title, choices with help text, disabled choices, error, extra content revealed under the
  # selected choice (no JS), vertical or horizontal layout (horizontal stacks on phones), and card appearance.
  class ChoiceListComponent < ViewComponent::Base
    strip_trailing_whitespace

    FIELDSET = "tw:m-0 tw:min-w-0 tw:border-0 tw:p-0 tw:font-sans"
    TITLE = "tw:mb-1.5 tw:p-0 tw:text-[13px] tw:font-medium tw:text-ink"
    LAYOUTS = {
      vertical: "tw:flex tw:flex-col tw:gap-2 tw:max-sm:gap-0",
      horizontal: "tw:flex tw:flex-wrap tw:gap-x-5 tw:gap-y-2 tw:max-sm:flex-col tw:max-sm:gap-0"
    }.freeze
    CARD_LAYOUTS = {
      vertical: "tw:flex tw:flex-col tw:gap-2",
      horizontal: "tw:grid tw:gap-2 tw:sm:grid-cols-[repeat(auto-fit,minmax(180px,1fr))]"
    }.freeze
    REVEAL = "tw:hidden tw:pt-2 tw:pb-1 tw:pl-6 tw:group-has-checked/choice:block tw:max-sm:pl-7.5"
    ERROR = "tw:mt-1.5 tw:flex tw:items-start tw:gap-1 tw:text-[13px] tw:text-danger"
    HELP = "tw:mt-1.5 tw:text-[13px] tw:text-muted"

    # choices: [{ label:, value:, help_text:, disabled:, reveal: html }] or ["Option", ...] or [["Label", "value"]]
    def initialize(name:, choices:, title: nil, selected: nil, allow_multiple: false, title_hidden: false,
                   help_text: nil, error: nil, disabled: false, layout: :vertical, appearance: :default, id: nil, **html_attributes)
      @allow_multiple = allow_multiple
      @name = allow_multiple && !name.to_s.end_with?("[]") ? "#{name}[]" : name.to_s
      @choices = Array(choices).map { |c| normalize(c) }
      @title = title
      @selected = Array(selected).map(&:to_s)
      @title_hidden = title_hidden
      @help_text = help_text
      @error = error
      @disabled = disabled
      @layout = LAYOUTS.key?(layout&.to_sym) ? layout.to_sym : :vertical
      @card = appearance&.to_sym == :card
      @id = id || "sui-choices-#{SecureRandom.hex(4)}"
      @html_attributes = html_attributes
    end

    def call
      legend = tag.legend(@title, class: [ TITLE, ("tw:sr-only" if @title_hidden) ].compact.join(" ")) if @title
      items = @choices.each_with_index.map { |c, i| choice_tag(c, i) }
      list = tag.div(safe_join(items), class: (@card ? CARD_LAYOUTS : LAYOUTS)[@layout])
      after = if @error.present?
                tag.p(@error, id: "#{@id}-help", class: "tw:m-0 #{ERROR}")
              elsif @help_text.present?
                tag.p(@help_text, id: "#{@id}-help", class: "tw:m-0 #{HELP}")
              end
      hidden = tag.input(type: "hidden", name: @name, value: "") if @allow_multiple
      tag.fieldset(safe_join([ legend, hidden, list, after ].compact), id: @id, **@html_attributes,
                   class: [ FIELDSET, @html_attributes[:class] ].compact.join(" "), disabled: @disabled || nil,
                   aria: { describedby: ("#{@id}-help" if after), invalid: (@error.present? || nil) })
    end

    private

    def normalize(choice)
      return choice.to_h.symbolize_keys.then { |c| c.merge(value: (c[:value] || c[:label]).to_s) } if choice.is_a?(Hash)

      label, value = choice.is_a?(Array) ? choice : [ choice, choice ]
      { label: label.to_s, value: value.to_s }
    end

    def choice_tag(choice, index)
      id = "#{@id}-#{index}"
      checked = @selected.include?(choice[:value])
      control = if @allow_multiple
                  checkbox_row(choice, id, checked)
                else
                  render(RadioComponent.new(name: @name, value: choice[:value], label: choice[:label], checked: checked,
                                            help_text: choice[:help_text], disabled: @disabled || choice[:disabled] || false,
                                            error: @error.present?, appearance: (@card ? :card : :default), id: id))
                end
      reveal = tag.div(choice[:reveal], class: REVEAL) if choice[:reveal]
      tag.div(safe_join([ control, reveal ].compact), class: "tw:group/choice tw:min-w-0")
    end

    def checkbox_row(choice, id, checked)
      box = render(CheckboxComponent.new(name: @name, value: choice[:value], checked: checked,
                                         disabled: @disabled || choice[:disabled] || false, id: id,
                                         aria: { describedby: ("#{id}-help" if choice[:help_text]) }))
      text = tag.span(safe_join([
        tag.span(choice[:label], class: RadioComponent::LABEL),
        (tag.span(choice[:help_text], id: "#{id}-help", class: RadioComponent::HELP) if choice[:help_text])
      ].compact), class: RadioComponent::TEXT)
      tag.label(safe_join([ tag.span(box, class: "tw:mt-0.5 tw:max-sm:mt-0 tw:inline-flex"), text ]), for: id,
                class: [ RadioComponent::ROW, (RadioComponent::CARD if @card) ].flatten.compact.join(" "))
    end
  end
end
