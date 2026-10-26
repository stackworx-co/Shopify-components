# frozen_string_literal: true

module ShopifyUI
  # Shopify admin combobox / autocomplete (Polaris Combobox + Autocomplete).
  #
  # Covers: type-to-filter with highlighted matches, single select (value shown in the field) and
  # multi-select (✓ in the list + removable tags under the field), grouped options, option description,
  # option thumbnail or icon, disabled options, "Add “query”" create action, remote options from a JSON
  # endpoint (url: …?q=), loading spinner, empty "No results" text, min characters, label / help / error /
  # disabled. Keyboard: ↓/↑ open and move, Enter selects, Esc closes, Backspace on empty removes last tag.
  # Phones: 40px field with 16px text, list spans the field width (up to the screen) and flips above
  # when there's no room, options get 44px rows.
  #
  # options: ["Snowboards", ...] | [{ label:, value:, description:, image:, disabled: }] | { "Group" => [...] }
  # Remote JSON: [{ "label": "…", "value": "…", "description": "…", "image": "…" }]
  class ComboboxComponent < ViewComponent::Base
    strip_trailing_whitespace

    WRAPPER = "tw:flex tw:flex-col tw:gap-1 tw:font-sans tw:min-w-0"
    LABEL = "tw:m-0 tw:text-[13px] tw:text-ink"
    BOX = %w[
      tw:relative tw:flex tw:h-8 tw:min-w-0 tw:items-center tw:gap-1.5 tw:rounded-control tw:border tw:px-2.5 tw:cursor-text
      tw:transition-colors tw:duration-100
      tw:has-[input:focus-visible]:shadow-input-focus
      tw:max-sm:h-10
    ].freeze
    STATES = {
      default: "tw:border-transparent tw:bg-surface tw:shadow-input tw:hover:bg-surface-hover",
      error: "tw:border-danger-icon tw:bg-danger-light",
      disabled: "tw:border-border tw:bg-surface-secondary tw:cursor-not-allowed"
    }.freeze
    INPUT = %w[
      tw:m-0 tw:h-full tw:min-w-0 tw:flex-1 tw:appearance-none tw:border-0 tw:bg-transparent tw:p-0 tw:font-sans tw:text-[13px]
      tw:text-ink tw:outline-none tw:placeholder:text-muted tw:disabled:cursor-not-allowed tw:disabled:text-disabled
      tw:max-sm:text-[16px]
    ].freeze
    ICON = "tw:size-4 tw:shrink-0 tw:text-muted"
    SPINNER = "tw:size-4 tw:shrink-0 tw:animate-spin tw:text-muted tw:hidden tw:group-data-loading:block"
    CHEVRON = "tw:size-4 tw:shrink-0 tw:text-muted tw:group-data-loading:hidden"

    LIST = %w[
      tw:m-0 tw:box-border tw:max-w-[calc(100vw-16px)] tw:max-h-[min(320px,50vh)] tw:overflow-y-auto tw:overscroll-contain
      tw:rounded-[12px] tw:border-0 tw:bg-surface tw:p-1.5 tw:font-sans tw:text-ink tw:list-none
      tw:shadow-popover tw:[scrollbar-width:thin]
    ].freeze
    GROUP = "tw:m-0 tw:px-2 tw:pt-2 tw:pb-1 tw:text-[12px] tw:font-medium tw:text-muted tw:data-hidden:hidden"
    OPTION = %w[
      tw:flex tw:items-center tw:gap-2 tw:rounded-[8px] tw:px-2 tw:py-1.5 tw:text-[13px] tw:leading-5 tw:cursor-pointer tw:select-none
      tw:hover:bg-surface-hover tw:data-active:bg-surface-sunken tw:data-hidden:hidden
      tw:aria-disabled:cursor-not-allowed tw:aria-disabled:text-disabled tw:aria-disabled:hover:bg-transparent
      tw:max-sm:min-h-11 tw:max-sm:text-[15px]
    ].freeze
    CHECK = "tw:size-4 tw:shrink-0 tw:invisible tw:in-aria-selected:visible"
    OPTION_TEXT = "tw:flex tw:min-w-0 tw:flex-1 tw:flex-col"
    OPTION_LABEL = "tw:break-words tw:[&_mark]:bg-transparent tw:[&_mark]:font-semibold tw:[&_mark]:text-inherit"
    OPTION_DESC = "tw:text-[12px] tw:text-muted tw:max-sm:text-[13px]"
    CREATE = "tw:text-link tw:font-medium"
    EMPTY = "tw:px-2 tw:py-2 tw:text-[13px] tw:text-muted tw:hidden tw:data-visible:block"
    TAGS = "tw:flex tw:flex-wrap tw:gap-1.5 tw:pt-1 tw:empty:hidden"
    HELP = "tw:m-0 tw:text-[13px] tw:text-muted"
    ERROR = "tw:m-0 tw:text-[13px] tw:text-danger"

    SCRIPT = Runtime.wrap(File.read(File.join(__dir__, "combobox_component.js")))

    def initialize(name:, options: [], label: nil, selected: nil, multiple: false, placeholder: "Search",
                   allow_create: false, url: nil, min_chars: 0, empty_text: "No results found",
                   help_text: nil, error: nil, disabled: false, label_hidden: false, id: nil, **html_attributes)
      @name = multiple && !name.to_s.end_with?("[]") ? "#{name}[]" : name.to_s
      @groups = normalize(options)
      @label = label
      @multiple = multiple
      @selected = Array(selected).map(&:to_s)
      @placeholder = placeholder
      @allow_create = allow_create
      @url = url
      @min_chars = min_chars
      @empty_text = empty_text
      @help_text = help_text
      @error = error
      @disabled = disabled
      @label_hidden = label_hidden
      @id = id || "sui-combobox-#{SecureRandom.hex(4)}"
      @html_attributes = html_attributes
    end

    private

    def normalize(options)
      return options.map { |group, opts| [ group.to_s, opts.map { |o| option_hash(o) } ] } if options.is_a?(Hash)

      [ [ nil, Array(options).map { |o| option_hash(o) } ] ]
    end

    def option_hash(option)
      o = option.is_a?(Hash) ? option.symbolize_keys : { label: option.to_s }
      o.merge(value: (o[:value] || o[:label]).to_s, label: o[:label].to_s)
    end

    def all_options
      @groups.flat_map(&:last)
    end

    def selected_options
      found = all_options.select { |o| @selected.include?(o[:value]) }
      missing = @selected - found.map { |o| o[:value] }
      found + missing.map { |v| { label: v, value: v } }
    end

    def state
      if @disabled then :disabled elsif @error.present? then :error else :default end
    end

    def list_id
      "#{@id}-list"
    end

    def root_attributes
      @html_attributes.merge(
        class: [ "tw:group", WRAPPER, @html_attributes[:class] ].compact.join(" "),
        data: { sui_combobox: "", multiple: (@multiple ? "" : nil), url: @url, min_chars: @min_chars,
                create: (@allow_create ? "" : nil), name: @name }
      )
    end

    def input_attributes
      single = selected_options.first unless @multiple
      { id: @id, type: "text", role: "combobox", value: single&.dig(:label), placeholder: @placeholder,
        disabled: @disabled || nil, autocomplete: "off", spellcheck: "false", enterkeyhint: "search",
        class: INPUT.join(" "), data: { input: "" },
        aria: { autocomplete: "list", expanded: "false", controls: list_id, haspopup: "listbox",
                invalid: (@error.present? || nil), describedby: ("#{@id}-help" if @help_text || @error) } }
    end

    def option_tag(option, index)
      sel = @selected.include?(option[:value])
      media = if option[:image]
                render(ThumbnailComponent.new(source: option[:image], alt: "", size: :extra_small, lazy: true))
              elsif option[:icon]
                option[:icon]
              end
      tag.li(safe_join([
        (svg('<path d="m5 10.5 3.2 3L15 6.5"/>', CHECK) if @multiple),
        media,
        tag.span(safe_join([ tag.span(option[:label], class: OPTION_LABEL, data: { text: "" }),
                             (tag.span(option[:description], class: OPTION_DESC) if option[:description]) ].compact), class: OPTION_TEXT),
        (svg('<path d="m5 10.5 3.2 3L15 6.5"/>', CHECK) unless @multiple)
      ].compact), role: "option", id: "#{@id}-opt-#{index}", class: OPTION.join(" "),
         aria: { selected: sel.to_s, disabled: (option[:disabled] ? "true" : nil) },
         data: { value: option[:value], label: option[:label], search: [ option[:label], option[:description] ].compact.join(" ").downcase })
    end

    def option_template
      tag.template(tag.li(safe_join([
        (svg('<path d="m5 10.5 3.2 3L15 6.5"/>', CHECK) if @multiple),
        tag.span(data: { media: "" }, class: "tw:contents"),
        tag.span(safe_join([ tag.span(class: OPTION_LABEL, data: { text: "" }), tag.span(class: OPTION_DESC, data: { desc: "" }) ]), class: OPTION_TEXT),
        (svg('<path d="m5 10.5 3.2 3L15 6.5"/>', CHECK) unless @multiple)
      ].compact), role: "option", class: OPTION.join(" "), aria: { selected: "false" }), data: { option: "" })
    end

    def tag_template
      tag.template(render(TagComponent.new("__LABEL__", value: "__VALUE__", removable: true, name: @name)), data: { tag: "" })
    end

    def svg(paths, css, width: 1.8)
      tag.svg(paths.html_safe, viewBox: "0 0 20 20", fill: "none", stroke: "currentColor", "stroke-width": width,
              "stroke-linecap": "round", "stroke-linejoin": "round", class: css, aria: { hidden: true }, focusable: "false")
    end
  end
end
