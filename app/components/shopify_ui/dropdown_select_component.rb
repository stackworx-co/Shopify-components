# frozen_string_literal: true

module ShopifyUI
  # Shopify admin select: a field-style trigger that opens a floating option list
  # (white card, ✓ on selected options, grey rounded highlight, wrapping labels, scrolls).
  # A hidden native <select> mirrors the choice, so forms submit exactly as before.
  #
  # options: ["Active", ...] | [["Active", "active"], ["Archived", "archived", { disabled: true }]]
  #          | { "Group" => [...] } for grouped lists.
  # multiple: true keeps the list open and toggles ✓ per option (name should end in []).
  class DropdownSelectComponent < ViewComponent::Base
    strip_trailing_whitespace

    WRAPPER = "tw:flex tw:flex-col tw:gap-1 tw:font-sans tw:min-w-0"
    LABEL = "tw:m-0 tw:text-[13px] tw:font-regular tw:text-ink"
    FIELD = "tw:relative tw:flex tw:items-center tw:min-w-0"

    TRIGGER = %w[
      tw:m-0 tw:box-border tw:flex tw:h-8 tw:w-full tw:min-w-0 tw:cursor-pointer tw:appearance-none tw:items-center
      tw:rounded-control tw:border tw:py-0 tw:pl-3 tw:pr-8 tw:text-left tw:font-sans tw:text-[13px] tw:leading-none
      tw:transition-colors tw:duration-100
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-1 tw:focus-visible:outline-link
      tw:max-sm:h-10 tw:max-sm:text-[16px]
    ].freeze
    VALUE = "tw:block tw:min-w-0 tw:truncate"
    PLACEHOLDER = "tw:text-muted"

    STATES = {
      default: "tw:border-input-border tw:bg-surface tw:text-ink tw:hover:bg-surface-hover",
      error: "tw:border-danger-icon tw:bg-danger-light tw:text-ink",
      disabled: "tw:cursor-not-allowed tw:border-border tw:bg-surface-secondary tw:text-disabled"
    }.freeze

    CHEVRON = "tw:pointer-events-none tw:absolute tw:right-2 tw:size-4"
    CHEVRON_COLORS = { default: "tw:text-muted", error: "tw:text-muted", disabled: "tw:text-disabled" }.freeze

    LIST = %w[
      tw:m-0 tw:box-border tw:w-max tw:max-w-[min(360px,calc(100vw-16px))]
      tw:max-h-[min(360px,55vh)] tw:overflow-y-auto tw:overscroll-contain
      tw:rounded-[12px] tw:border-0 tw:bg-surface tw:p-1.5 tw:font-sans tw:text-ink tw:list-none
      tw:shadow-[0_4px_6px_-2px_rgba(26,26,26,.2),0_0_0_1px_rgba(0,0,0,.08)]
      tw:outline-none tw:[scrollbar-width:thin]
    ].freeze
    GROUP = "tw:m-0 tw:px-2 tw:pt-2 tw:pb-1 tw:text-[12px] tw:font-medium tw:text-muted"
    OPTION = %w[
      tw:flex tw:items-start tw:gap-1 tw:rounded-[8px] tw:px-2 tw:py-1.5 tw:text-[13px] tw:leading-5
      tw:cursor-pointer tw:select-none tw:break-words
      tw:hover:bg-surface-sunken tw:data-active:bg-surface-sunken tw:aria-selected:bg-surface-hover
      tw:aria-selected:data-active:bg-surface-sunken
      tw:aria-disabled:cursor-not-allowed tw:aria-disabled:text-disabled tw:aria-disabled:hover:bg-transparent
      tw:max-sm:py-2.5 tw:max-sm:text-[15px]
    ].freeze
    CHECK = "tw:mt-0.5 tw:size-4 tw:shrink-0 tw:invisible tw:in-aria-selected:visible"
    OPTION_LABEL = "tw:min-w-0 tw:flex-1"

    HELP_TEXT = "tw:m-0 tw:text-[13px] tw:text-muted"
    ERROR = "tw:m-0 tw:flex tw:items-center tw:gap-1 tw:text-[13px] tw:text-danger"
    ERROR_ICON = "tw:size-4 tw:shrink-0 tw:text-danger-icon"

    SCRIPT = Runtime.wrap <<~JS.squish
      (function () {
        if (window.__suiSelect) return; window.__suiSelect = true;
        function parts(el) {
          var root = el.closest('[data-sui-select]');
          return { root: root, list: root.querySelector('[role=listbox]'), trigger: root.querySelector('[data-sui-select-trigger]'),
                   native: root.querySelector('select'), multiple: root.hasAttribute('data-multiple') };
        }
        function opts(p) { return Array.prototype.slice.call(p.list.querySelectorAll('[role=option]:not([aria-disabled=true])')); }
        function setActive(p, opt) {
          p.list.querySelectorAll('[data-active]').forEach(function (o) { o.removeAttribute('data-active'); });
          if (!opt) return; opt.setAttribute('data-active', ''); p.list.setAttribute('aria-activedescendant', opt.id);
          opt.scrollIntoView({ block: 'nearest' });
        }
        function sync(p) {
          var chosen = Array.prototype.slice.call(p.list.querySelectorAll('[aria-selected=true]'));
          var values = chosen.map(function (o) { return o.getAttribute('data-value'); });
          Array.prototype.forEach.call(p.native.options, function (o) { o.selected = values.indexOf(o.value) !== -1; });
          var label = p.trigger.querySelector('[data-sui-select-value]');
          var text = chosen.map(function (o) { return o.getAttribute('data-label'); }).join(', ');
          label.textContent = text || p.trigger.getAttribute('data-placeholder') || '';
          label.classList.toggle('tw:text-muted', !text);
          p.native.dispatchEvent(new Event('input', { bubbles: true }));
          p.native.dispatchEvent(new Event('change', { bubbles: true }));
        }
        function choose(p, opt) {
          if (!opt || opt.getAttribute('aria-disabled') === 'true') return;
          if (p.multiple) { opt.setAttribute('aria-selected', opt.getAttribute('aria-selected') === 'true' ? 'false' : 'true'); setActive(p, opt); }
          else {
            p.list.querySelectorAll('[aria-selected=true]').forEach(function (o) { o.setAttribute('aria-selected', 'false'); });
            opt.setAttribute('aria-selected', 'true'); p.list.hidePopover(); p.trigger.focus();
          }
          sync(p);
        }
        function position(p) {
          var r = p.trigger.getBoundingClientRect(), l = p.list;
          l.style.minWidth = r.width + 'px'; l.style.right = l.style.bottom = 'auto';
          l.style.left = Math.max(8, Math.min(r.left, innerWidth - l.offsetWidth - 8)) + 'px';
          var below = innerHeight - r.bottom - 8, above = r.top - 8;
          l.style.top = (l.offsetHeight > below && above > below ? Math.max(8, r.top - 4 - l.offsetHeight) : r.bottom + 4) + 'px';
          l.style.visibility = '';
        }
        document.addEventListener('beforetoggle', function (event) {
          var l = event.target; if (event.newState === 'open' && l.matches && l.matches('[data-sui-select] [role=listbox]')) l.style.visibility = 'hidden';
        }, true);
        document.addEventListener('toggle', function (event) {
          var l = event.target; if (!l.matches || !l.matches('[data-sui-select] [role=listbox]')) return;
          var p = parts(l);
          p.trigger.setAttribute('aria-expanded', event.newState === 'open' ? 'true' : 'false');
          if (event.newState !== 'open') { setActive(p, null); return; }
          position(p); l.focus({ preventScroll: true });
          setActive(p, l.querySelector('[aria-selected=true]:not([aria-disabled=true])') || opts(p)[0]);
        }, true);
        document.addEventListener('click', function (event) {
          var opt = event.target.closest('[data-sui-select] [role=option]'); if (opt) choose(parts(opt), opt);
        });
        document.addEventListener('mousemove', function (event) {
          var opt = event.target.closest('[data-sui-select] [role=option]:not([aria-disabled=true])');
          if (opt && !opt.hasAttribute('data-active')) setActive(parts(opt), opt);
        });
        var typed = '', typedAt = 0;
        document.addEventListener('keydown', function (event) {
          var t = event.target;
          if (t.matches && t.matches('[data-sui-select-trigger]') && (event.key === 'ArrowDown' || event.key === 'ArrowUp')) {
            event.preventDefault(); parts(t).list.showPopover(); return;
          }
          if (!t.matches || !t.matches('[data-sui-select] [role=listbox]')) return;
          var p = parts(t), all = opts(p), cur = all.indexOf(t.querySelector('[data-active]')), k = event.key;
          if (k === 'ArrowDown') setActive(p, all[Math.min(cur + 1, all.length - 1)]);
          else if (k === 'ArrowUp') setActive(p, all[Math.max(cur - 1, 0)]);
          else if (k === 'Home') setActive(p, all[0]);
          else if (k === 'End') setActive(p, all[all.length - 1]);
          else if (k === 'PageDown') setActive(p, all[Math.min(cur + 8, all.length - 1)]);
          else if (k === 'PageUp') setActive(p, all[Math.max(cur - 8, 0)]);
          else if (k === 'Enter' || k === ' ') choose(p, all[cur]);
          else if (k === 'Tab') { t.hidePopover(); return; }
          else if (k.length === 1 && !event.metaKey && !event.ctrlKey && !event.altKey) {
            var now = Date.now(); typed = (now - typedAt > 600 ? '' : typed) + k.toLowerCase(); typedAt = now;
            var hit = all.filter(function (o) { return o.getAttribute('data-label').toLowerCase().indexOf(typed) === 0; })[0];
            if (hit) setActive(p, hit);
          } else return;
          event.preventDefault();
        });
        window.addEventListener('resize', function () {
          document.querySelectorAll('[data-sui-select] [role=listbox]:popover-open').forEach(function (l) { l.hidePopover(); });
        });
      })();
    JS

    def initialize(name:, options:, label: nil, selected: nil, placeholder: nil, help_text: nil,
                   error: nil, disabled: false, label_hidden: false, multiple: false, id: nil, **html_attributes)
      @name = name
      @label = label
      @multiple = multiple
      @selected = Array(selected).map(&:to_s)
      @placeholder = placeholder
      @help_text = help_text
      @error = error
      @disabled = disabled
      @label_hidden = label_hidden
      @id = id || "sui-select-#{SecureRandom.hex(4)}"
      @html_attributes = html_attributes
      @groups = normalize(options)
      default_selection
    end

    private

    # => [[group_label_or_nil, [{ label:, value:, disabled: }]]]
    def normalize(options)
      return options.map { |group, opts| [ group.to_s, opts.map { |o| option_hash(o) } ] } if options.is_a?(Hash)

      [ [ nil, Array(options).map { |o| option_hash(o) } ] ]
    end

    def option_hash(option)
      label, value, extra = option.is_a?(Array) ? option : [ option, option ]
      value = label if value.nil?
      { label: label.to_s, value: value.to_s, disabled: (extra.is_a?(Hash) && extra[:disabled]).present? }
    end

    # Native single selects fall back to the first option; mirror that unless there's a placeholder.
    def default_selection
      return if @multiple || @placeholder || @selected.any?

      first = all_options.find { |o| !o[:disabled] }
      @selected = [ first[:value] ] if first
    end

    def all_options
      @groups.flat_map(&:last)
    end

    def selected?(option)
      @selected.include?(option[:value])
    end

    def state
      if @disabled then :disabled elsif @error.present? then :error else :default end
    end

    def list_id
      "#{@id}-list"
    end

    def label_id
      "#{@id}-label"
    end

    def label_classes
      [ LABEL, ("tw:sr-only" if @label_hidden) ].compact.join(" ")
    end

    def describedby
      "#{@id}-description" if @error.present? || @help_text.present?
    end

    def root_attributes
      { class: FIELD, data: { sui_select: "", multiple: (@multiple ? "" : nil) } }
    end

    def trigger_attributes
      @html_attributes.merge(
        id: @id,
        type: "button",
        disabled: @disabled || nil,
        popovertarget: list_id,
        class: [ TRIGGER, STATES[state], @html_attributes[:class] ].flatten.compact.join(" "),
        data: { sui_select_trigger: "", placeholder: @placeholder },
        aria: { haspopup: "listbox", expanded: "false", controls: list_id,
                labelledby: ("#{label_id} #{@id}" if @label), invalid: (@error.present? || nil), describedby: describedby }
      )
    end

    def display_text
      all_options.select { |o| selected?(o) }.map { |o| o[:label] }.join(", ").presence
    end

    def list_attributes
      { id: list_id, popover: "auto", role: "listbox", tabindex: -1, class: LIST.join(" "),
        aria: { labelledby: (label_id if @label), label: (@placeholder unless @label), multiselectable: (@multiple || nil) } }
    end

    def option_id(group_index, index)
      "#{@id}-opt-#{group_index}-#{index}"
    end

    def native_select
      body = safe_join([
        (tag.option("", value: "") if @placeholder && !@multiple),
        *all_options.map { |o| tag.option(o[:label], value: o[:value], selected: selected?(o) || nil, disabled: o[:disabled] || nil) }
      ].compact)
      tag.select(body, name: @name, multiple: @multiple || nil, disabled: @disabled || nil,
                 class: "tw:sr-only", tabindex: -1, aria: { hidden: true }, form: @html_attributes[:form])
    end
  end
end
