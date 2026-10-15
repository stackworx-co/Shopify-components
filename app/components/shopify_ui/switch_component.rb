# frozen_string_literal: true

module ShopifyUI
  # Shopify admin switch / toggle (Polaris Switch).
  # A native checkbox with role="switch", so it submits with forms and works without JavaScript.
  #
  # Covers: on / off, label on the right (default) or left, hidden label, help text (details), error,
  # disabled (on or off), pending/loading state, sizes (small / medium), unchecked value (Rails style
  # hidden "0"), and a full-width settings-row layout (label + help on the left, switch at the end).
  # Phones: switch grows a little and the whole row is a 44px tap target; help text wraps under the label.
  class SwitchComponent < ViewComponent::Base
    strip_trailing_whitespace

    SIZES = {
      small: { track: "tw:h-4 tw:w-7", knob: "tw:size-3 tw:peer-checked:translate-x-3", mobile: "tw:max-sm:h-5 tw:max-sm:w-9 tw:max-sm:[&>span]:size-4 tw:max-sm:[&>span]:peer-checked:translate-x-4" },
      medium: { track: "tw:h-5 tw:w-9", knob: "tw:size-4 tw:peer-checked:translate-x-4", mobile: "tw:max-sm:h-6 tw:max-sm:w-11 tw:max-sm:[&>span]:size-5 tw:max-sm:[&>span]:peer-checked:translate-x-5" }
    }.freeze

    ROOT = "tw:group tw:font-sans tw:min-w-0"
    ROW = {
      inline: "tw:inline-flex tw:max-w-full tw:items-start tw:gap-2.5 tw:cursor-pointer tw:max-sm:min-h-11 tw:max-sm:items-center",
      setting: "tw:flex tw:w-full tw:items-center tw:justify-between tw:gap-4 tw:cursor-pointer tw:max-sm:min-h-11"
    }.freeze
    LABEL_LEFT = "tw:flex-row-reverse"
    DISABLED = "tw:cursor-not-allowed"

    TRACK = %w[
      tw:relative tw:inline-flex tw:shrink-0 tw:items-center tw:rounded-full tw:p-0.5 tw:mt-px
      tw:bg-fill-tertiary-active tw:transition-colors tw:duration-150 tw:motion-reduce:transition-none
      tw:has-checked:bg-accent
      tw:has-[input:focus-visible]:outline-2 tw:has-[input:focus-visible]:outline-offset-2 tw:has-[input:focus-visible]:outline-link
      tw:has-disabled:bg-border tw:has-disabled:has-checked:bg-disabled
      tw:group-hover:has-[input:not(:disabled):not(:checked)]:bg-faint tw:group-hover:has-[input:checked:not(:disabled)]:bg-accent-hover
    ].freeze
    TRACK_ERROR = "tw:ring-2 tw:ring-danger-icon tw:ring-offset-1"
    INPUT = "tw:peer tw:absolute tw:inset-0 tw:m-0 tw:size-full tw:cursor-[inherit] tw:appearance-none tw:rounded-full tw:opacity-0"
    KNOB = %w[
      tw:pointer-events-none tw:block tw:rounded-full tw:bg-white tw:shadow-[0_1px_2px_rgba(0,0,0,.3)]
      tw:transition-transform tw:duration-150 tw:ease-out tw:motion-reduce:transition-none
      tw:peer-disabled:shadow-none
    ].freeze
    SPINNER = "tw:absolute tw:inset-0 tw:m-auto tw:size-3 tw:animate-spin tw:text-muted"

    TEXT = "tw:flex tw:min-w-0 tw:flex-col tw:gap-0.5"
    LABEL = "tw:text-[13px] tw:leading-5 tw:text-ink tw:break-words tw:group-data-disabled:text-disabled"
    LABEL_SETTING = "tw:font-medium"
    HELP = "tw:text-[13px] tw:leading-5 tw:text-muted tw:group-data-disabled:text-disabled"
    ERROR = "tw:mt-1 tw:flex tw:items-start tw:gap-1 tw:text-[13px] tw:text-danger"

    # layout: :inline (switch + label) or :setting (label/help left, switch right, full width).
    # unchecked_value: submits this when off (like Rails check_box); nil to send nothing.
    def initialize(name: nil, label:, checked: false, value: "1", unchecked_value: "0", help_text: nil, error: nil,
                   disabled: false, pending: false, label_hidden: false, label_position: :right, layout: :inline,
                   size: :medium, id: nil, **html_attributes)
      @name = name
      @label = label
      @checked = checked
      @value = value
      @unchecked_value = unchecked_value
      @help_text = help_text
      @error = error
      @disabled = disabled
      @pending = pending
      @label_hidden = label_hidden
      @label_position = label_position&.to_sym == :left ? :left : :right
      @layout = ROW.key?(layout&.to_sym) ? layout.to_sym : :inline
      @size = SIZES.key?(size&.to_sym) ? size.to_sym : :medium
      @id = id || "sui-switch-#{SecureRandom.hex(4)}"
      @html_attributes = html_attributes
    end

    def call
      tag.div(safe_join([ row, error_tag ].compact), class: [ ROOT, @html_attributes.delete(:class) ].compact.join(" "),
              data: { disabled: (@disabled || @pending ? "" : nil) })
    end

    private

    def row
      setting = @layout == :setting
      classes = [ ROW[@layout], (LABEL_LEFT if @label_position == :left && !setting), (DISABLED if @disabled || @pending) ]
      tag.label(safe_join(setting ? [ text, switch ] : [ switch, text ]), for: @id, class: classes.compact.join(" "))
    end

    def switch
      s = SIZES[@size]
      hidden = tag.input(type: "hidden", name: @name, value: @unchecked_value, disabled: @disabled || nil) if @name && !@unchecked_value.nil?
      input = tag.input(type: "checkbox", role: "switch", id: @id, name: @name, value: @value, checked: @checked || nil,
                        disabled: (@disabled || @pending) || nil, class: INPUT,
                        aria: { checked: @checked.to_s, describedby: ("#{@id}-help" if @help_text || @error),
                                invalid: (@error.present? || nil), busy: (@pending || nil) },
                        onchange: "this.setAttribute('aria-checked', this.checked)", **@html_attributes)
      knob = tag.span(@pending ? spinner : nil, class: [ KNOB, s[:knob], "tw:relative" ].flatten.join(" "))
      safe_join([ hidden, tag.span(safe_join([ input, knob ]), class: [ TRACK, s[:track], s[:mobile], (TRACK_ERROR if @error.present?) ].flatten.compact.join(" ")) ].compact)
    end

    def spinner
      tag.svg(tag.circle(cx: 10, cy: 10, r: 7, fill: "none", stroke: "currentColor", "stroke-width": 3, "stroke-dasharray": "30 14"),
              viewBox: "0 0 20 20", class: SPINNER, aria: { hidden: true })
    end

    def text
      return tag.span(@label, class: "tw:sr-only") if @label_hidden && @help_text.blank?

      tag.span(safe_join([
        tag.span(@label, class: [ LABEL, (LABEL_SETTING if @layout == :setting), ("tw:sr-only" if @label_hidden) ].compact.join(" ")),
        (tag.span(@help_text, id: "#{@id}-help", class: HELP) if @help_text.present? && @error.blank?)
      ].compact), class: TEXT)
    end

    def error_tag
      return if @error.blank?

      tag.p(safe_join([
        tag.svg(tag.path(d: "M10 2a8 8 0 1 0 0 16 8 8 0 0 0 0-16Zm-.75 4.5a.75.75 0 0 1 1.5 0v4a.75.75 0 0 1-1.5 0v-4ZM10 14.5a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z"),
                viewBox: "0 0 20 20", fill: "currentColor", class: "tw:mt-0.5 tw:size-4 tw:shrink-0 tw:text-danger-icon", aria: { hidden: true }),
        tag.span(@error)
      ]), id: "#{@id}-help", class: "tw:m-0 #{ERROR}")
    end
  end
end
