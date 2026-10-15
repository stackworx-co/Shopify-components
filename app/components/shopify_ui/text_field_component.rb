# frozen_string_literal: true

module ShopifyUI
  # Shopify admin text field (Polaris TextField).
  #
  # Covers: label (hidden / with action link / required indicator), placeholder, help text, inline error,
  # disabled, read-only, prefix / suffix (text or icon), multiline (fixed rows or auto-grow),
  # character count, clear button, number stepper, password reveal, monospaced, text alignment,
  # sizes (slim / medium), borderless variant, and connected left/right content (slots).
  # On phones the field grows to a 40px touch target with 16px text (no iOS zoom on focus).
  class TextFieldComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_one :connected_left
    renders_one :connected_right

    TYPES = %w[text email number password search tel url date datetime-local month time week currency integer].freeze
    SIZES = %i[slim medium].freeze
    ALIGNS = { left: "tw:text-left", center: "tw:text-center", right: "tw:text-right" }.freeze

    WRAPPER = "tw:flex tw:flex-col tw:gap-1 tw:font-sans tw:min-w-0"
    LABEL_ROW = "tw:flex tw:items-baseline tw:justify-between tw:gap-2 tw:min-w-0"
    LABEL = "tw:m-0 tw:min-w-0 tw:text-[13px] tw:font-regular tw:text-ink"
    REQUIRED = "tw:ml-0.5 tw:text-danger"
    LABEL_ACTION = "tw:shrink-0 tw:text-[13px] tw:font-medium tw:text-link tw:no-underline tw:hover:underline tw:hover:text-link-hover tw:focus-visible:outline-2 tw:focus-visible:outline-link tw:rounded"
    ROW = "tw:flex tw:items-start tw:gap-2 tw:min-w-0"

    BOX = %w[
      tw:relative tw:flex tw:min-w-0 tw:flex-1 tw:items-center tw:gap-1.5 tw:rounded-control tw:border
      tw:px-3 tw:transition-colors tw:duration-100 tw:cursor-text
      tw:has-[input:focus-visible,textarea:focus-visible]:outline-2
      tw:has-[input:focus-visible,textarea:focus-visible]:outline-offset-1
      tw:has-[input:focus-visible,textarea:focus-visible]:outline-link
    ].freeze
    BOX_HEIGHTS = {
      slim: "tw:min-h-7 tw:max-sm:min-h-10",
      medium: "tw:min-h-8 tw:max-sm:min-h-10"
    }.freeze
    BOX_MULTILINE = "tw:items-start tw:py-1.5 tw:max-sm:py-2"

    STATES = {
      default: "tw:border-input-border tw:bg-surface tw:hover:bg-surface-hover",
      error: "tw:border-danger-icon tw:bg-danger-light",
      disabled: "tw:cursor-not-allowed tw:border-border tw:bg-surface-secondary",
      read_only: "tw:border-border tw:bg-surface-secondary",
      borderless: "tw:border-transparent tw:bg-transparent tw:hover:bg-surface-hover"
    }.freeze

    INPUT = %w[
      tw:m-0 tw:block tw:w-full tw:min-w-0 tw:flex-1 tw:appearance-none tw:border-0 tw:bg-transparent tw:p-0
      tw:font-sans tw:text-[13px] tw:leading-5 tw:text-ink tw:outline-none tw:shadow-none
      tw:placeholder:text-faint
      tw:disabled:cursor-not-allowed tw:disabled:text-disabled tw:disabled:placeholder:text-disabled
      tw:max-sm:text-[16px] tw:max-sm:leading-6
      tw:[&::-webkit-search-cancel-button]:appearance-none
      tw:[&::-webkit-inner-spin-button]:appearance-none tw:[&::-webkit-outer-spin-button]:appearance-none
      tw:[-moz-appearance:textfield]
    ].freeze
    TEXTAREA = "tw:resize-y tw:min-h-[60px]"
    AUTO_GROW = "tw:resize-none tw:overflow-hidden tw:[field-sizing:content]"
    MONO = "tw:font-mono"

    AFFIX = "tw:flex tw:shrink-0 tw:items-center tw:text-[13px] tw:text-muted tw:max-sm:text-[15px] tw:select-none"
    AFFIX_ICON = "tw:size-4 tw:shrink-0"

    ICON_BUTTON = %w[
      tw:inline-flex tw:size-5 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-full tw:border-0 tw:p-0
      tw:bg-transparent tw:text-muted tw:cursor-pointer tw:hover:text-ink
      tw:focus-visible:outline-2 tw:focus-visible:outline-link
      tw:max-sm:size-8
    ].freeze
    CLEAR_HIDDEN = "tw:invisible"

    STEPPER = "tw:-mr-1.5 tw:flex tw:shrink-0 tw:flex-col tw:self-stretch tw:justify-center tw:max-sm:flex-row tw:max-sm:items-center tw:max-sm:gap-1"
    STEP_BUTTON = %w[
      tw:inline-flex tw:h-3.5 tw:w-5 tw:items-center tw:justify-center tw:rounded tw:border-0 tw:p-0
      tw:bg-transparent tw:text-muted tw:cursor-pointer tw:hover:bg-fill-tertiary tw:hover:text-ink
      tw:focus-visible:outline-2 tw:focus-visible:outline-link
      tw:disabled:cursor-not-allowed tw:disabled:text-disabled tw:disabled:hover:bg-transparent
      tw:max-sm:size-8 tw:max-sm:rounded-full
    ].freeze

    COUNT = "tw:shrink-0 tw:self-end tw:text-[12px] tw:text-muted tw:tabular-nums tw:pb-px"

    HELP_TEXT = "tw:m-0 tw:text-[13px] tw:text-muted"
    ERROR = "tw:m-0 tw:flex tw:items-start tw:gap-1 tw:text-[13px] tw:text-danger"
    ERROR_ICON = "tw:mt-0.5 tw:size-4 tw:shrink-0 tw:text-danger-icon"

    ICONS = {
      search: '<circle cx="8.5" cy="8.5" r="5.5"/><path d="m16 16-3.5-3.5"/>',
      clear: '<circle cx="10" cy="10" r="7"/><path d="m7.5 7.5 5 5m0-5-5 5"/>',
      eye: '<path d="M2.5 10s2.8-5 7.5-5 7.5 5 7.5 5-2.8 5-7.5 5-7.5-5-7.5-5Z"/><circle cx="10" cy="10" r="2.2"/>',
      eye_off: '<path d="M2.5 10s2.8-5 7.5-5 7.5 5 7.5 5-2.8 5-7.5 5-7.5-5-7.5-5Z"/><circle cx="10" cy="10" r="2.2"/><path d="m3.5 3.5 13 13"/>',
      up: '<path d="m6 12 4-4 4 4"/>',
      down: '<path d="m6 8 4 4 4-4"/>',
      calendar: '<rect x="3" y="4" width="14" height="13" rx="2"/><path d="M3 8h14M7 2v4M13 2v4"/>',
      email: '<rect x="3" y="5" width="14" height="10" rx="2"/><path d="m3.5 6 6.5 5 6.5-5"/>',
      link: '<path d="M8.5 11.5a3 3 0 0 0 4.2 0l2.6-2.6a3 3 0 0 0-4.2-4.2l-.9.9"/><path d="M11.5 8.5a3 3 0 0 0-4.2 0l-2.6 2.6a3 3 0 0 0 4.2 4.2l.9-.9"/>'
    }.freeze

    SCRIPT = <<~JS.squish.freeze
      (function () {
        if (window.__suiTextField) return; window.__suiTextField = true;
        function field(el) { return el.closest('[data-sui-text-field]'); }
        function input(root) { return root.querySelector('input, textarea'); }
        function refresh(root) {
          var el = input(root), clear = root.querySelector('[data-sui-tf-clear]'), count = root.querySelector('[data-sui-tf-count]');
          if (clear) clear.classList.toggle('tw:invisible', !el.value || el.disabled || el.readOnly);
          if (count) { var max = el.getAttribute('maxlength'); count.textContent = el.value.length + (max ? '/' + max : ''); }
          if (el.hasAttribute('data-sui-tf-grow') && !CSS.supports('field-sizing', 'content')) { el.style.height = 'auto'; el.style.height = el.scrollHeight + 'px'; }
        }
        document.addEventListener('input', function (event) { var r = event.target.closest && field(event.target); if (r) refresh(r); });
        document.addEventListener('click', function (event) {
          var b = event.target.closest('[data-sui-tf-clear], [data-sui-tf-step], [data-sui-tf-reveal], [data-sui-text-field] [data-sui-tf-box]');
          if (!b) return;
          var root = field(b), el = input(root);
          if (b.hasAttribute('data-sui-tf-box')) { if (event.target === b || event.target.closest('[data-sui-tf-affix]')) el.focus(); return; }
          if (b.hasAttribute('data-sui-tf-clear')) { el.value = ''; el.focus(); }
          else if (b.hasAttribute('data-sui-tf-step')) { if (b.getAttribute('data-sui-tf-step') === 'up') el.stepUp(); else el.stepDown(); }
          else if (b.hasAttribute('data-sui-tf-reveal')) {
            var show = el.type === 'password'; el.type = show ? 'text' : 'password';
            b.setAttribute('aria-pressed', show ? 'true' : 'false');
            b.querySelector('[data-show]').classList.toggle('tw:hidden', show); b.querySelector('[data-hide]').classList.toggle('tw:hidden', !show);
            return;
          }
          el.dispatchEvent(new Event('input', { bubbles: true })); el.dispatchEvent(new Event('change', { bubbles: true }));
        });
        function init() { document.querySelectorAll('[data-sui-text-field]').forEach(refresh); }
        if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
      })();
    JS

    # type: also accepts :currency (decimal input, mobile number pad) and :integer.
    # prefix / suffix: text ("$", "kg") or an icon symbol (:search, :calendar, :email, :link).
    # multiline: true (auto-grow) or a row count. size: :slim | :medium. variant: :borderless.
    def initialize(name:, label: nil, value: nil, type: :text, placeholder: nil, help_text: nil, error: nil,
                   disabled: false, read_only: false, required: false, required_indicator: false,
                   label_hidden: false, label_action: nil, prefix: nil, suffix: nil,
                   multiline: false, max_length: nil, show_character_count: false, clear_button: false,
                   monospaced: false, align: :left, size: :medium, variant: nil, reveal: true,
                   step: nil, min: nil, max: nil, autocomplete: nil, id: nil, **html_attributes)
      @name = name
      @label = label
      @value = value
      @type = TYPES.include?(type.to_s) ? type.to_s : "text"
      @placeholder = placeholder
      @help_text = help_text
      @error = error
      @disabled = disabled
      @read_only = read_only
      @required = required
      @required_indicator = required_indicator
      @label_hidden = label_hidden
      @label_action = label_action&.to_h&.symbolize_keys
      @prefix = prefix
      @suffix = suffix
      @multiline = multiline
      @max_length = max_length
      @show_character_count = show_character_count
      @clear_button = clear_button
      @monospaced = monospaced
      @align = ALIGNS.key?(align&.to_sym) ? align.to_sym : :left
      @size = SIZES.include?(size&.to_sym) ? size.to_sym : :medium
      @borderless = variant&.to_sym == :borderless
      @reveal = reveal
      @step = step
      @min = min
      @max = max
      @autocomplete = autocomplete
      @id = id || "sui-text-field-#{SecureRandom.hex(4)}"
      @html_attributes = html_attributes
    end

    private

    def multiline?
      @multiline.present? && @multiline != 0
    end

    def auto_grow?
      @multiline == true
    end

    def numeric?
      %w[number currency integer].include?(@type)
    end

    def stepper?
      numeric? && !@disabled && !@read_only && !multiline?
    end

    def password?
      @type == "password"
    end

    def state
      if @disabled then :disabled
      elsif @error.present? then :error
      elsif @read_only then :read_only
      elsif @borderless then :borderless
      else :default
      end
    end

    def describedby
      ids = []
      ids << "#{@id}-description" if @error.present? || @help_text.present?
      ids << "#{@id}-count" if @show_character_count
      ids.join(" ").presence
    end

    def label_classes
      [ LABEL, ("tw:sr-only" if @label_hidden) ].compact.join(" ")
    end

    def box_attributes
      classes = [ BOX, BOX_HEIGHTS[@size], (BOX_MULTILINE if multiline?), STATES[state] ]
      { class: classes.flatten.compact.join(" "), data: { sui_tf_box: "" } }
    end

    def html_type
      case @type
      when "currency", "integer" then "text"
      else @type
      end
    end

    def input_mode
      { "currency" => "decimal", "integer" => "numeric", "number" => "decimal" }[@type]
    end

    def field_attributes
      base = {
        id: @id, name: @name, placeholder: @placeholder,
        disabled: @disabled || nil, readonly: @read_only || nil, required: @required || nil,
        maxlength: @max_length, autocomplete: @autocomplete,
        class: [ INPUT, (multiline? ? (auto_grow? ? AUTO_GROW : TEXTAREA) : nil), (MONO if @monospaced),
                 ALIGNS[@align], @html_attributes[:class] ].flatten.compact.join(" "),
        aria: { invalid: (@error.present? || nil), describedby: describedby }.merge(@html_attributes[:aria] || {})
      }
      if multiline?
        base.merge(rows: (auto_grow? ? 1 : @multiline.to_i), data: (auto_grow? ? { sui_tf_grow: "" } : {}))
      else
        base.merge(type: html_type, value: @value, inputmode: input_mode,
                   pattern: (@type == "integer" ? "[0-9]*" : nil),
                   step: @step || (@type == "number" ? "any" : nil), min: @min, max: @max,
                   enterkeyhint: (@type == "search" ? "search" : nil))
      end.merge(@html_attributes.except(:class, :aria))
    end

    def field_tag
      if multiline?
        tag.textarea(@value, **field_attributes)
      else
        tag.input(**field_attributes)
      end
    end

    def svg(name, css = AFFIX_ICON)
      tag.svg(ICONS[name].html_safe, viewBox: "0 0 20 20", fill: "none", stroke: "currentColor",
              "stroke-width": 1.6, "stroke-linecap": "round", "stroke-linejoin": "round",
              class: css, aria: { hidden: true }, focusable: "false")
    end

    def affix(content)
      return if content.blank?

      body = content.is_a?(Symbol) && ICONS.key?(content) ? svg(content) : content
      tag.span(body, class: AFFIX, data: { sui_tf_affix: "" })
    end

    def clear_tag
      return unless @clear_button && !multiline?

      tag.button(svg(:clear), type: "button", class: [ ICON_BUTTON, (CLEAR_HIDDEN if @value.blank?) ].flatten.compact.join(" "),
                 aria: { label: "Clear" }, data: { sui_tf_clear: "" })
    end

    def reveal_tag
      return unless password? && @reveal && !@disabled

      tag.button(safe_join([ tag.span(svg(:eye), data: { show: "" }, class: "tw:contents"),
                             tag.span(svg(:eye_off), data: { hide: "" }, class: "tw:hidden") ]),
                 type: "button", class: ICON_BUTTON.join(" "), aria: { label: "Show password", pressed: "false" },
                 data: { sui_tf_reveal: "" })
    end

    def stepper_tag
      return unless stepper? && %w[number].include?(@type)

      tag.span(safe_join([
        tag.button(svg(:up, "tw:size-3.5"), type: "button", class: STEP_BUTTON.join(" "), aria: { label: "Increase" }, tabindex: -1, data: { sui_tf_step: "up" }),
        tag.button(svg(:down, "tw:size-3.5"), type: "button", class: STEP_BUTTON.join(" "), aria: { label: "Decrease" }, tabindex: -1, data: { sui_tf_step: "down" })
      ]), class: STEPPER)
    end

    def count_tag
      return unless @show_character_count

      length = @value.to_s.length
      tag.span(@max_length ? "#{length}/#{@max_length}" : length.to_s, id: "#{@id}-count", class: COUNT,
               data: { sui_tf_count: "" }, aria: { live: "polite" })
    end
  end
end
