# frozen_string_literal: true

module ShopifyUI
  # Shopify admin tags field (the "Tags" box on product / order / customer pages).
  # Type and press Enter or comma (or paste a comma list) to add; ✕ or Backspace on the empty input removes.
  # Duplicates are ignored (case-insensitive), max_tags limits the count, and each tag submits as name[].
  # Phones: 40px input with 16px text, tags wrap on their own rows, ✕ gets a 32px hit area.
  class TagInputComponent < ViewComponent::Base
    strip_trailing_whitespace

    WRAPPER = "tw:flex tw:flex-col tw:gap-1 tw:font-sans tw:min-w-0"
    LABEL = "tw:m-0 tw:text-[13px] tw:text-ink"
    BOX = %w[
      tw:flex tw:min-h-8 tw:w-full tw:min-w-0 tw:flex-wrap tw:items-center tw:gap-1.5 tw:rounded-control tw:border
      tw:border-input-border tw:bg-surface tw:px-1.5 tw:py-1 tw:cursor-text tw:transition-colors tw:duration-100
      tw:hover:bg-surface-hover
      tw:has-[input:focus-visible]:outline-2 tw:has-[input:focus-visible]:outline-offset-1 tw:has-[input:focus-visible]:outline-link
      tw:max-sm:min-h-10 tw:max-sm:py-1.5
    ].freeze
    BOX_ERROR = "tw:border-danger-icon tw:bg-danger-light"
    BOX_DISABLED = "tw:border-border tw:bg-surface-secondary tw:cursor-not-allowed tw:hover:bg-surface-secondary"
    INPUT = %w[
      tw:m-0 tw:h-6 tw:min-w-[120px] tw:flex-1 tw:appearance-none tw:border-0 tw:bg-transparent tw:px-1.5 tw:py-0
      tw:font-sans tw:text-[13px] tw:text-ink tw:outline-none tw:placeholder:text-muted tw:disabled:cursor-not-allowed
      tw:max-sm:h-8 tw:max-sm:text-[16px]
    ].freeze
    HELP = "tw:m-0 tw:text-[13px] tw:text-muted"
    ERROR = "tw:m-0 tw:text-[13px] tw:text-danger"

    SCRIPT = <<~JS.squish.freeze
      (function () {
        if (window.__suiTagInput) return; window.__suiTagInput = true;
        function root(el) { return el.closest('[data-sui-tag-input]'); }
        function values(r) { return Array.prototype.map.call(r.querySelectorAll('[data-sui-tag]'), function (t) { return t.getAttribute('data-value'); }); }
        function add(r, raw) {
          var tpl = r.querySelector('template'), input = r.querySelector('[data-entry]'), max = parseInt(r.getAttribute('data-max') || '0', 10);
          raw.split(',').map(function (s) { return s.trim(); }).filter(Boolean).forEach(function (v) {
            var have = values(r).map(function (x) { return x.toLowerCase(); });
            if (have.indexOf(v.toLowerCase()) !== -1 || (max && have.length >= max)) return;
            var html = tpl.innerHTML.split('__VALUE__').join(v.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;'));
            input.insertAdjacentHTML('beforebegin', html);
            r.dispatchEvent(new CustomEvent('sui:tag-add', { bubbles: true, detail: { value: v } }));
          });
          input.value = '';
          var full = max && values(r).length >= max; input.disabled = !!full; input.placeholder = full ? '' : (r.getAttribute('data-placeholder') || '');
          if (!full) input.focus();
        }
        document.addEventListener('keydown', function (e) {
          var input = e.target; if (!input.matches || !input.matches('[data-sui-tag-input] [data-entry]')) return;
          var r = root(input);
          if ((e.key === 'Enter' || e.key === ',') && input.value.trim()) { e.preventDefault(); add(r, input.value); }
          else if (e.key === 'Enter') e.preventDefault();
          else if (e.key === 'Backspace' && !input.value) { var tags = r.querySelectorAll('[data-sui-tag]'); var last = tags[tags.length - 1]; if (last) last.querySelector('button').click(); input.focus(); }
        });
        document.addEventListener('paste', function (e) {
          var input = e.target; if (!input.matches || !input.matches('[data-sui-tag-input] [data-entry]')) return;
          var text = (e.clipboardData || window.clipboardData).getData('text'); if (text.indexOf(',') === -1) return;
          e.preventDefault(); add(root(input), input.value + text);
        });
        document.addEventListener('focusout', function (e) {
          var input = e.target; if (input.matches && input.matches('[data-sui-tag-input] [data-entry]') && input.value.trim()) add(root(input), input.value);
        });
        document.addEventListener('sui:tag-remove', function (e) {
          var r = e.target.closest && root(e.target); if (!r) return;
          setTimeout(function () { var input = r.querySelector('[data-entry]'); input.disabled = false; input.placeholder = r.getAttribute('data-placeholder') || ''; input.focus(); }, 0);
        });
        document.addEventListener('click', function (e) {
          var box = e.target.closest('[data-sui-tag-input] [data-box]'); if (box && e.target === box) box.querySelector('[data-entry]').focus();
        });
      })();
    JS

    def initialize(name:, label: nil, tags: [], placeholder: "Add tags", help_text: nil, error: nil,
                   max_tags: nil, disabled: false, label_hidden: false, id: nil, **html_attributes)
      @name = name.to_s.end_with?("[]") ? name.to_s : "#{name}[]"
      @label = label
      @tags = Array(tags).map(&:to_s).uniq
      @placeholder = placeholder
      @help_text = help_text
      @error = error
      @max_tags = max_tags
      @disabled = disabled
      @label_hidden = label_hidden
      @id = id || "sui-tag-input-#{SecureRandom.hex(4)}"
      @html_attributes = html_attributes
    end

    def call
      tags = @tags.map { |t| render(TagComponent.new(t, removable: true, name: @name, disabled: @disabled)) }
      full = @max_tags && @tags.size >= @max_tags
      input = tag.input(type: "text", id: @id, data: { entry: "" }, placeholder: (full ? nil : @placeholder),
                        disabled: (@disabled || full) || nil, autocomplete: "off", enterkeyhint: "done",
                        class: INPUT.join(" "),
                        aria: { describedby: ("#{@id}-help" if @help_text || @error), invalid: (@error.present? || nil) })
      template = tag.template(render(TagComponent.new("__VALUE__", removable: true, name: @name)))
      box = tag.div(safe_join([ *tags, input ]), data: { box: "" },
                    class: [ BOX, (BOX_ERROR if @error.present?), (BOX_DISABLED if @disabled) ].flatten.compact.join(" "))
      tag.div(safe_join([
        (tag.label(@label, for: @id, class: [ LABEL, ("tw:sr-only" if @label_hidden) ].compact.join(" ")) if @label),
        box, template,
        (tag.p(@error, id: "#{@id}-help", class: ERROR) if @error.present?),
        (tag.p(@help_text, id: "#{@id}-help", class: HELP) if @help_text.present? && @error.blank?),
        tag.script(raw(SCRIPT))
      ].compact), **@html_attributes, class: [ WRAPPER, @html_attributes[:class] ].compact.join(" "),
         data: { sui_tag_input: "", max: @max_tags, placeholder: @placeholder })
    end
  end
end
