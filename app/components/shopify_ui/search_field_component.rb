# frozen_string_literal: true

module ShopifyUI
  # Shopify admin search field: full stadium pill with a magnifier.
  #
  # Covers: variants (outlined form field / filled top-bar search / plain inline search used in table
  # filters), sizes (slim / medium / large), clear button, loading spinner, keyboard shortcut hint +
  # global shortcut (Ctrl/⌘ K or "/"), "Cancel" button (search mode), GET form submit or live search
  # (debounced `sui:search` event, optional auto-submit), disabled, and a collapsible mode that shows
  # only an icon button on phones and expands to full width when tapped.
  # On phones the field is 40px tall with 16px text (no iOS zoom) and the keyboard shows a Search key.
  class SearchFieldComponent < ViewComponent::Base
    strip_trailing_whitespace

    VARIANTS = %i[outlined filled plain].freeze
    SIZES = %i[slim medium large].freeze

    ROOT = "tw:group tw:flex tw:min-w-0 tw:items-center tw:gap-2 tw:font-sans"
    COLLAPSIBLE_ROOT = "tw:max-sm:data-expanded:flex-1"

    BOX = %w[
      tw:relative tw:flex tw:min-w-0 tw:flex-1 tw:items-center tw:gap-1.5 tw:rounded-full tw:cursor-text
      tw:transition-colors tw:duration-100
      tw:has-[input:focus-visible]:shadow-input-focus
      tw:has-[input:disabled]:cursor-not-allowed
    ].freeze
    COLLAPSIBLE_BOX = "tw:max-sm:hidden tw:max-sm:group-data-expanded:flex"

    VARIANT_CLASSES = {
      outlined: "tw:border tw:border-transparent tw:bg-surface tw:shadow-input tw:hover:bg-surface-hover tw:has-[input:disabled]:border-border tw:has-[input:disabled]:bg-surface-secondary",
      filled: "tw:border tw:border-transparent tw:bg-fill-tertiary tw:hover:bg-fill-tertiary-hover tw:focus-within:bg-surface tw:focus-within:border-input-border tw:has-[input:disabled]:bg-surface-secondary",
      plain: "tw:border tw:border-transparent tw:bg-transparent tw:hover:bg-surface-hover tw:focus-within:bg-surface-hover"
    }.freeze

    SIZE_CLASSES = {
      slim: "tw:h-7 tw:px-2.5 tw:max-sm:h-10 tw:max-sm:px-3",
      medium: "tw:h-8 tw:px-3 tw:max-sm:h-10",
      large: "tw:h-9 tw:px-3.5 tw:max-sm:h-11"
    }.freeze
    TEXT_SIZES = { slim: "tw:text-[12.5px]", medium: "tw:text-[13px]", large: "tw:text-[14px]" }.freeze

    ICON = "tw:size-4 tw:shrink-0 tw:text-muted tw:group-has-[input:disabled]:text-disabled"
    INPUT = %w[
      tw:m-0 tw:h-full tw:w-full tw:min-w-0 tw:flex-1 tw:appearance-none tw:border-0 tw:bg-transparent tw:p-0
      tw:font-sans tw:text-ink tw:outline-none tw:placeholder:text-muted
      tw:disabled:cursor-not-allowed tw:disabled:text-disabled tw:disabled:placeholder:text-disabled
      tw:[&::-webkit-search-cancel-button]:appearance-none tw:[&::-webkit-search-decoration]:appearance-none
      tw:max-sm:text-[16px]
    ].freeze

    KBD = %w[
      tw:shrink-0 tw:rounded-[6px] tw:border tw:border-border tw:bg-surface tw:px-1.5 tw:py-px tw:font-sans
      tw:text-[11px] tw:font-medium tw:leading-4 tw:text-muted
      tw:group-focus-within:hidden tw:group-data-has-value:hidden tw:max-sm:hidden tw:[@media(hover:none)]:hidden
    ].freeze

    CLEAR = %w[
      tw:inline-flex tw:size-5 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-full tw:border-0 tw:p-0
      tw:bg-transparent tw:text-muted tw:cursor-pointer tw:hover:text-ink
      tw:focus-visible:outline-2 tw:focus-visible:outline-link
      tw:hidden tw:group-data-has-value:inline-flex tw:group-data-loading:hidden tw:group-has-[input:disabled]:hidden
      tw:max-sm:size-8 tw:max-sm:-mr-1.5
    ].freeze

    SPINNER = "tw:size-4 tw:shrink-0 tw:animate-spin tw:text-muted tw:hidden tw:group-data-loading:block"

    CANCEL = %w[
      tw:shrink-0 tw:rounded-control tw:border-0 tw:bg-transparent tw:px-1.5 tw:py-1 tw:font-sans tw:text-[13px]
      tw:font-medium tw:text-ink tw:cursor-pointer tw:hover:bg-fill-tertiary
      tw:focus-visible:outline-2 tw:focus-visible:outline-link
      tw:max-sm:min-h-10 tw:max-sm:px-2
    ].freeze
    COLLAPSIBLE_CANCEL = "tw:max-sm:hidden tw:max-sm:group-data-expanded:inline-flex tw:max-sm:items-center"

    TOGGLE = %w[
      tw:hidden tw:max-sm:inline-flex tw:max-sm:group-data-expanded:hidden
      tw:size-10 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-full tw:border tw:border-border tw:bg-surface tw:p-0
      tw:text-ink tw:cursor-pointer tw:hover:bg-surface-hover
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-1 tw:focus-visible:outline-link
    ].freeze

    SCRIPT = Runtime.wrap <<~JS.squish
      (function () {
        if (window.__suiSearch) return; window.__suiSearch = true;
        function root(el) { return el.closest('[data-sui-search]'); }
        function input(r) { return r.querySelector('input[type=search]'); }
        function emit(r, name) { r.dispatchEvent(new CustomEvent(name, { bubbles: true, detail: { value: input(r).value } })); }
        function refresh(r) { r.toggleAttribute('data-has-value', !!input(r).value); }
        function changed(r) {
          refresh(r); clearTimeout(r.__t);
          r.__t = setTimeout(function () {
            emit(r, 'sui:search');
            var form = r.closest('form');
            if (r.hasAttribute('data-auto-submit') && form) { form.requestSubmit ? form.requestSubmit() : form.submit(); }
          }, parseInt(r.getAttribute('data-debounce') || '300', 10));
        }
        document.addEventListener('input', function (e) { var r = e.target.closest && root(e.target); if (r && e.target === input(r)) changed(r); });
        document.addEventListener('click', function (e) {
          var b = e.target.closest('[data-sui-search] [data-action]');
          if (!b) { var box = e.target.closest('[data-sui-search] [data-box]'); if (box) input(root(box)).focus(); return; }
          var r = root(b), el = input(r), a = b.getAttribute('data-action');
          if (a === 'clear') { el.value = ''; el.focus(); changed(r); }
          else if (a === 'cancel') { el.value = ''; refresh(r); emit(r, 'sui:search'); emit(r, 'sui:search-cancel'); el.blur(); r.removeAttribute('data-expanded'); }
          else if (a === 'expand') { r.setAttribute('data-expanded', ''); el.focus(); }
        });
        document.addEventListener('focusout', function (e) {
          var r = e.target.closest && root(e.target);
          if (r && r.hasAttribute('data-collapsible')) setTimeout(function () { if (!r.contains(document.activeElement) && !input(r).value) r.removeAttribute('data-expanded'); }, 0);
        });
        document.addEventListener('keydown', function (e) {
          var t = e.target;
          if (t.matches && t.matches('[data-sui-search] input[type=search]') && e.key === 'Escape' && t.value) { e.preventDefault(); t.value = ''; changed(root(t)); return; }
          var typing = t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName);
          var combo = (e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k';
          var slash = e.key === '/' && !typing && !e.metaKey && !e.ctrlKey && !e.altKey;
          if (!combo && !slash) return;
          var r = document.querySelector('[data-sui-search][data-shortcut]'); if (!r) return;
          e.preventDefault(); r.setAttribute('data-expanded', ''); input(r).focus(); input(r).select();
        });
        window.ShopifyUI = window.ShopifyUI || {};
        window.ShopifyUI.setSearchLoading = function (el, on) { var r = typeof el === 'string' ? document.getElementById(el) : el; if (r) r.toggleAttribute('data-loading', on !== false); };
        function init() { document.querySelectorAll('[data-sui-search]').forEach(refresh); }
        ShopifyUI.onLoad(init);
      })();
    JS

    # url: wraps the field in a GET form (Enter submits); params: extra hidden fields to keep (filters, sort).
    # shortcut: true shows "Ctrl K" and focuses this field on Ctrl/⌘ K or "/".
    def initialize(name: "query", value: nil, placeholder: "Search", label: nil, variant: :outlined, size: :medium,
                   url: nil, params: {}, clear_button: true, cancel_button: false, shortcut: false,
                   loading: false, disabled: false, auto_submit: false, debounce: 300, collapsible: false,
                   autofocus: false, id: nil, **html_attributes)
      @name = name
      @value = value
      @placeholder = placeholder
      @label = label || placeholder
      @variant = VARIANTS.include?(variant&.to_sym) ? variant.to_sym : :outlined
      @size = SIZES.include?(size&.to_sym) ? size.to_sym : :medium
      @url = url
      @params = params
      @clear_button = clear_button
      @cancel_button = cancel_button
      @shortcut = shortcut
      @loading = loading
      @disabled = disabled
      @auto_submit = auto_submit
      @debounce = debounce
      @collapsible = collapsible
      @autofocus = autofocus
      @id = id || "sui-search-#{SecureRandom.hex(4)}"
      @html_attributes = html_attributes
    end

    private

    def root_attributes
      @html_attributes.merge(
        id: @id,
        class: [ ROOT, (COLLAPSIBLE_ROOT if @collapsible), @html_attributes[:class] ].compact.join(" "),
        data: {
          sui_search: "", has_value: (@value.present? ? "" : nil), loading: (@loading ? "" : nil),
          shortcut: (@shortcut ? "" : nil), auto_submit: (@auto_submit ? "" : nil), debounce: @debounce,
          collapsible: (@collapsible ? "" : nil), expanded: (@collapsible && @value.present? ? "" : nil)
        }.merge(@html_attributes[:data] || {})
      )
    end

    def wrapper_tag(&block)
      if @url
        tag.form(action: @url, method: "get", role: "search", class: "tw:contents") do
          safe_join([ *@params.map { |k, v| tag.input(type: "hidden", name: k, value: v) }, capture(&block) ])
        end
      else
        tag.div(role: "search", class: "tw:contents", &block)
      end
    end

    def box_classes
      [ BOX, VARIANT_CLASSES[@variant], SIZE_CLASSES[@size], (COLLAPSIBLE_BOX if @collapsible) ].flatten.compact.join(" ")
    end

    def input_attributes
      { type: "search", id: "#{@id}-input", name: @name, value: @value, placeholder: @placeholder,
        disabled: @disabled || nil, autofocus: @autofocus || nil, autocomplete: "off", spellcheck: "false",
        enterkeyhint: "search", class: [ INPUT, TEXT_SIZES[@size] ].flatten.join(" "), aria: { label: @label } }
    end

    def cancel_classes
      [ CANCEL, (COLLAPSIBLE_CANCEL if @collapsible) ].flatten.compact.join(" ")
    end

    def svg(path, css, size: 20, width: 1.6)
      tag.svg(path.html_safe, viewBox: "0 0 #{size} #{size}", fill: "none", stroke: "currentColor", "stroke-width": width,
              "stroke-linecap": "round", "stroke-linejoin": "round", class: css, aria: { hidden: true }, focusable: "false")
    end

    def magnifier(css = ICON)
      svg('<circle cx="8.5" cy="8.5" r="5.5"/><path d="m16 16-3.5-3.5"/>', css)
    end

    def clear_icon
      svg('<circle cx="10" cy="10" r="7"/><path d="m7.5 7.5 5 5m0-5-5 5"/>', "tw:size-4")
    end

    def spinner
      svg('<circle cx="10" cy="10" r="7" stroke-dasharray="32 12"/>', SPINNER, width: 2)
    end
  end
end
