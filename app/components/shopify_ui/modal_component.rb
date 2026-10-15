# frozen_string_literal: true

module ShopifyUI
  # Shopify admin modal (Polaris Modal), built on native <dialog> (focus trap, Esc, top layer).
  #
  # Covers: sizes (small / medium / large / fullscreen), title with close button or hidden title,
  # plain or sectioned body, flush body (no padding, for lists / media), long scrolling content with
  # fixed header + footer, primary action (incl. destructive, disabled, loading), secondary actions,
  # custom footer content on the left (e.g. a checkbox), body loading state, non-dismissible modals,
  # and open-on-load. Below sm it becomes a bottom sheet with full-width layout and safe-area padding.
  #
  # Open it from any element: tag.button("Open", **ShopifyUI::ModalComponent.open_attributes("my-modal"))
  # Close from inside with data-sui-modal-close, or action hashes with close: true.
  class ModalComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_many :sections
    renders_one :footer

    SIZES = {
      small: "tw:sm:w-[min(380px,calc(100vw-32px))]",
      medium: "tw:sm:w-[min(620px,calc(100vw-32px))]",
      large: "tw:sm:w-[min(980px,calc(100vw-32px))]",
      fullscreen: "tw:sm:w-[calc(100vw-32px)] tw:sm:h-[calc(100dvh-32px)]"
    }.freeze

    DIALOG = %w[
      tw:m-auto tw:max-w-none tw:border-0 tw:bg-surface tw:p-0 tw:font-sans tw:text-ink tw:overflow-hidden
      tw:rounded-surface tw:shadow-[0_26px_40px_-6px_rgba(26,26,26,.28),0_0_0_1px_rgba(0,0,0,.08)]
      tw:sm:max-h-[calc(100dvh-64px)]
      tw:backdrop:bg-[rgba(0,0,0,.5)]
      tw:opacity-0 tw:translate-y-2 tw:open:opacity-100 tw:open:translate-y-0
      tw:transition-[opacity,translate,display,overlay] tw:transition-discrete tw:duration-150 tw:ease-out
      tw:starting:open:opacity-0 tw:starting:open:translate-y-2
      tw:motion-reduce:transition-none
      tw:max-sm:mb-0 tw:max-sm:mt-auto tw:max-sm:w-full tw:max-sm:max-h-[calc(100dvh-24px)]
      tw:max-sm:rounded-b-none tw:max-sm:translate-y-6 tw:max-sm:starting:open:translate-y-6
    ].freeze
    FULLSCREEN_MOBILE = "tw:max-sm:h-dvh tw:max-sm:max-h-dvh tw:max-sm:rounded-none"

    INNER = "tw:flex tw:max-h-[inherit] tw:h-full tw:min-h-0 tw:flex-col"

    HEADER = %w[
      tw:flex tw:shrink-0 tw:items-center tw:justify-between tw:gap-3 tw:border-b tw:border-border
      tw:bg-surface-secondary tw:py-2.5 tw:pl-4 tw:pr-2.5 tw:max-sm:py-2
    ].freeze
    HEADER_HIDDEN = "tw:absolute tw:right-2.5 tw:top-2.5 tw:z-10"
    TITLE = "tw:m-0 tw:min-w-0 tw:text-[14px] tw:font-semibold tw:leading-5 tw:text-ink tw:break-words"
    CLOSE = %w[
      tw:inline-flex tw:size-7 tw:shrink-0 tw:items-center tw:justify-center tw:rounded-control tw:border-0 tw:p-0
      tw:bg-transparent tw:text-muted tw:cursor-pointer tw:transition-colors tw:duration-100
      tw:hover:bg-fill-tertiary tw:hover:text-ink tw:active:bg-fill-tertiary-hover
      tw:focus-visible:outline-2 tw:focus-visible:outline-offset-1 tw:focus-visible:outline-link
      tw:max-sm:size-9
    ].freeze

    BODY = "tw:relative tw:min-h-0 tw:flex-1 tw:overflow-y-auto tw:overscroll-contain tw:text-[13px] tw:leading-5"
    BODY_PADDING = "tw:p-4"
    SECTION = "tw:p-4 tw:border-t tw:border-border-secondary tw:first:border-t-0"
    LOADING = "tw:flex tw:items-center tw:justify-center tw:py-12"
    SPINNER = "tw:size-6 tw:animate-spin tw:text-muted"
    BUTTON_SPINNER = "tw:size-4 tw:animate-spin"

    FOOTER = %w[
      tw:flex tw:shrink-0 tw:flex-wrap tw:items-center tw:justify-between tw:gap-3 tw:border-t tw:border-border
      tw:px-4 tw:py-3 tw:pb-[max(12px,env(safe-area-inset-bottom))]
    ].freeze
    FOOTER_LEFT = "tw:min-w-0 tw:flex-1 tw:basis-[180px] tw:text-[13px]"
    FOOTER_ACTIONS = "tw:ml-auto tw:flex tw:flex-wrap tw:items-center tw:justify-end tw:gap-2 tw:max-sm:w-full tw:max-sm:[&>*]:flex-1"

    SCRIPT = Runtime.wrap <<~JS.squish
      (function () {
        if (window.__suiModal) return; window.__suiModal = true;
        function lock() { document.documentElement.style.overflow = document.querySelector('dialog[data-sui-modal][open]') ? 'hidden' : ''; }
        function open(dialog, opener) { if (!dialog || dialog.open) return; dialog.__suiOpener = opener; dialog.showModal(); lock(); }
        document.addEventListener('click', function (event) {
          var opener = event.target.closest('[data-sui-modal-open]');
          if (opener) { event.preventDefault(); open(document.getElementById(opener.getAttribute('data-sui-modal-open')), opener); return; }
          var closer = event.target.closest('dialog[data-sui-modal] [data-sui-modal-close]');
          if (closer) { closer.closest('dialog').close(); return; }
          var d = event.target;
          if (d.matches && d.matches('dialog[data-sui-modal][data-dismissible]')) {
            var r = d.getBoundingClientRect();
            if (event.clientX < r.left || event.clientX > r.right || event.clientY < r.top || event.clientY > r.bottom) d.close();
          }
        });
        document.addEventListener('cancel', function (event) {
          if (event.target.matches('dialog[data-sui-modal]:not([data-dismissible])')) event.preventDefault();
        }, true);
        document.addEventListener('close', function (event) {
          var d = event.target; if (!d.matches || !d.matches('dialog[data-sui-modal]')) return;
          lock(); if (d.__suiOpener && d.__suiOpener.focus) d.__suiOpener.focus();
        }, true);
        function init() { document.querySelectorAll('dialog[data-sui-modal][data-open-on-load]').forEach(function (d) { if (d.__suiAutoOpened) return; d.__suiAutoOpened = true; open(d); }); }
        ShopifyUI.onLoad(init);
      })();
    JS

    def self.open_attributes(id)
      { data: { sui_modal_open: id }, aria: { haspopup: "dialog", controls: id } }
    end

    # primary_action:    { label:, destructive:, disabled:, loading:, href:, close:, attributes: {} }
    # secondary_actions: [{ label:, destructive:, disabled:, href:, close: true, attributes: {} }]
    def initialize(id:, title:, size: :medium, title_hidden: false, primary_action: nil, secondary_actions: [],
                   sectioned: false, flush: false, loading: false, dismissible: true, open: false,
                   close_label: "Close", **html_attributes)
      @id = id
      @title = title
      @size = SIZES.key?(size&.to_sym) ? size.to_sym : :medium
      @title_hidden = title_hidden
      @primary = primary_action&.to_h&.symbolize_keys
      @secondary = Array(secondary_actions).map { |a| a.to_h.symbolize_keys }
      @sectioned = sectioned
      @flush = flush
      @loading = loading
      @dismissible = dismissible
      @open = open
      @close_label = close_label
      @html_attributes = html_attributes
    end

    private

    def title_id
      "#{@id}-title"
    end

    def dialog_attributes
      @html_attributes.merge(
        id: @id,
        class: [ DIALOG, SIZES[@size], (FULLSCREEN_MOBILE if @size == :fullscreen), @html_attributes[:class] ].flatten.compact.join(" "),
        aria: { labelledby: title_id, busy: (@loading || nil) },
        data: { sui_modal: "", dismissible: (@dismissible ? "" : nil), open_on_load: (@open ? "" : nil) }
      )
    end

    def header_classes
      @title_hidden ? HEADER_HIDDEN : HEADER.join(" ")
    end

    def body_classes
      [ BODY, (BODY_PADDING unless @flush || @sectioned || @loading) ].compact.join(" ")
    end

    def actions?
      @primary.present? || @secondary.any?
    end

    def spinner(css)
      tag.svg(tag.circle(cx: 10, cy: 10, r: 7.5, stroke: "currentColor", "stroke-width": 2, "stroke-dasharray": "34 14",
                         "stroke-linecap": "round", fill: "none"),
              viewBox: "0 0 20 20", class: css, aria: { hidden: true })
    end

    def close_icon
      tag.svg(tag.path(d: "m5.5 5.5 9 9m0-9-9 9"), viewBox: "0 0 20 20", width: 20, height: 20, fill: "none",
              stroke: "currentColor", "stroke-width": 1.6, "stroke-linecap": "round", aria: { hidden: true })
    end

    def action_button(action, variant:)
      variant = :critical if action[:destructive] && variant == :primary
      variant = :secondary if action[:destructive] && variant == :secondary
      attrs = (action[:attributes] || {}).dup
      attrs[:data] = (attrs[:data] || {}).merge(sui_modal_close: "") if action[:close]
      attrs[:aria] = (attrs[:aria] || {}).merge(busy: true) if action[:loading]
      css = [ ("tw:text-danger tw:hover:text-danger" if action[:destructive] && variant == :secondary), attrs.delete(:class) ].compact.join(" ").presence
      render(ButtonComponent.new(variant: variant, href: action[:href], disabled: action[:disabled] || action[:loading] || false,
                                 type: attrs.delete(:type) || "button", class: css, **attrs)) do
        action[:loading] ? safe_join([ spinner(BUTTON_SPINNER), tag.span(action[:label], class: "tw:sr-only") ]) : action[:label]
      end
    end
  end
end
