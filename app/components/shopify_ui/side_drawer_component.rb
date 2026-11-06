# frozen_string_literal: true

module ShopifyUI
  # Shopify admin side drawer (Polaris-style).
  #
  # Built using native <dialog>.
  #
  # Supports:
  # - Small, medium, large and fullscreen sizes
  # - Right-side slide-in animation
  # - Fixed header and footer
  # - Independently scrollable body
  # - Horizontal overflow prevention
  # - Plain or sectioned content
  # - Flush body
  # - Primary and secondary actions
  # - Custom footer content
  # - Loading state
  # - Hidden title
  # - Dismissible / non-dismissible behavior
  # - Open on load
  # - Turbo Frame and Stimulus content
  #
  class SideDrawerComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_many :sections
    renders_one :footer

    SIZES = {
      small: "tw:w-[min(360px,100vw)]",
      medium: "tw:w-[min(480px,100vw)]",
      large: "tw:w-[min(640px,100vw)]",
      fullscreen: "tw:w-screen"
    }.freeze

    DRAWER = %w[
      tw:fixed tw:inset-y-0 tw:right-0 tw:left-auto
      tw:m-0 tw:ml-auto tw:max-w-none
      tw:h-dvh tw:max-h-none
      tw:border-0 tw:bg-surface tw:p-0
      tw:font-sans tw:text-ink
      tw:overflow-hidden
      tw:rounded-l-surface
      tw:shadow-dialog
      tw:backdrop:bg-[rgba(0,0,0,.5)]
      tw:opacity-0 tw:translate-x-full
      tw:open:opacity-100 tw:open:translate-x-0
      tw:transition-[opacity,translate,display,overlay]
      tw:transition-discrete
      tw:duration-200 tw:ease-out
      tw:starting:open:opacity-0
      tw:starting:open:translate-x-full
      tw:motion-reduce:transition-none
      tw:max-sm:w-full
      tw:max-sm:rounded-none
    ].freeze

    # Full-height flex column.
    # The drawer itself must not scroll.
    INNER = %w[
      tw:flex tw:h-full tw:min-h-0
      tw:w-full tw:flex-col
      tw:overflow-hidden
    ].freeze

    HEADER = %w[
      tw:flex tw:w-full tw:shrink-0
      tw:items-center tw:justify-between
      tw:gap-3
      tw:border-b tw:border-border
      tw:bg-surface-secondary
      tw:py-3 tw:pl-5 tw:pr-3
    ].freeze

    HEADER_HIDDEN = "tw:absolute tw:right-3 tw:top-3 tw:z-10"

    TITLE = %w[
      tw:m-0 tw:min-w-0
      tw:text-[14px] tw:font-semibold
      tw:leading-5 tw:text-ink
      tw:break-words
    ].join(" ")

    CLOSE = %w[
      tw:inline-flex tw:size-8
      tw:shrink-0 tw:items-center
      tw:justify-center
      tw:rounded-full
      tw:border-0 tw:p-0
      tw:bg-transparent tw:text-muted
      tw:cursor-pointer
      tw:transition-colors tw:duration-100
      tw:hover:bg-fill-tertiary
      tw:hover:text-ink
      tw:active:bg-fill-tertiary-hover
      tw:focus-visible:outline-2
      tw:focus-visible:outline-offset-1
      tw:focus-visible:outline-link
    ].freeze

    # Only the body scrolls.
    BODY = %w[
      tw:relative tw:min-h-0
      tw:min-w-0 tw:w-full
      tw:flex-1
      tw:overflow-y-auto
      tw:overflow-x-hidden
      tw:overscroll-contain
      tw:text-[13px] tw:leading-5
    ].join(" ")

    BODY_PADDING = "tw:p-5"

    SECTION = %w[
      tw:min-w-0 tw:max-w-full
      tw:border-t tw:border-border-secondary
      tw:p-5
      tw:first:border-t-0
    ].join(" ")

    LOADING = %w[
      tw:flex tw:items-center
      tw:justify-center
      tw:py-12
    ].join(" ")

    SPINNER = "tw:size-6 tw:animate-spin tw:text-muted"

    BUTTON_SPINNER = "tw:size-4 tw:animate-spin"

    # Non-shrinking footer remains visible at the bottom.
 FOOTER = %w[
  tw:flex tw:w-full tw:shrink-0
  tw:box-border
  tw:items-center
  tw:justify-between
  tw:gap-3
  tw:border-t tw:border-border
  tw:bg-surface
  tw:px-5 tw:py-3
  tw:pb-[max(12px,env(safe-area-inset-bottom))]
].freeze

FOOTER_ACTIONS = %w[
  tw:ml-auto
  tw:flex tw:shrink-0
  tw:items-center tw:justify-end
  tw:gap-2
].join(" ")

   FOOTER_LEFT = %w[
  tw:min-w-0 tw:flex-1
  tw:text-[13px]
].join(" ")

    # FOOTER_ACTIONS = %w[
    #   tw:ml-auto tw:flex
    #   tw:flex-wrap tw:items-center
    #   tw:justify-end tw:gap-2
    #   tw:max-sm:w-full
    #   tw:max-sm:[&>*]:flex-1
    # ].join(" ")

    SCRIPT = Runtime.wrap <<~JS.squish
      (function () {
        if (window.__suiSideDrawer) return;
        window.__suiSideDrawer = true;

        function lock() {
          var openDrawer = document.querySelector(
            'dialog[data-sui-side-drawer][open]'
          );

          var openModal = document.querySelector(
            'dialog[data-sui-modal][open]'
          );

          document.documentElement.style.overflow =
            (openDrawer || openModal) ? 'hidden' : '';
        }

        function open(drawer, opener) {
          if (!drawer || drawer.open) return;

          drawer.__suiOpener = opener;

          drawer.showModal();
          lock();
        }

        document.addEventListener('click', function (event) {
          var opener = event.target.closest(
            '[data-sui-side-drawer-open]'
          );

          if (opener) {
            event.preventDefault();

            open(
              document.getElementById(
                opener.getAttribute('data-sui-side-drawer-open')
              ),
              opener
            );

            return;
          }

          var closer = event.target.closest(
            'dialog[data-sui-side-drawer] [data-sui-side-drawer-close]'
          );

          if (closer) {
            closer.closest('dialog').close();
            return;
          }

          var drawer = event.target;

          if (
            drawer.matches &&
            drawer.matches(
              'dialog[data-sui-side-drawer][data-dismissible]'
            )
          ) {
            var rect = drawer.getBoundingClientRect();

            if (
              event.clientX < rect.left ||
              event.clientX > rect.right ||
              event.clientY < rect.top ||
              event.clientY > rect.bottom
            ) {
              drawer.close();
            }
          }
        });

        document.addEventListener('cancel', function (event) {
          if (
            event.target.matches(
              'dialog[data-sui-side-drawer]:not([data-dismissible])'
            )
          ) {
            event.preventDefault();
          }
        }, true);

        document.addEventListener('close', function (event) {
          var drawer = event.target;

          if (
            !drawer.matches ||
            !drawer.matches('dialog[data-sui-side-drawer]')
          ) return;

          lock();

          if (
            drawer.__suiOpener &&
            drawer.__suiOpener.focus
          ) {
            drawer.__suiOpener.focus();
          }
        }, true);

        function init() {
          document.querySelectorAll(
            'dialog[data-sui-side-drawer][data-open-on-load]'
          ).forEach(function (drawer) {
            if (drawer.__suiAutoOpened) return;

            drawer.__suiAutoOpened = true;
            open(drawer);
          });
        }

        ShopifyUI.onLoad(init);
      })();
    JS

    def self.open_attributes(id)
      {
        data: { sui_side_drawer_open: id },
        aria: {
          haspopup: "dialog",
          controls: id
        }
      }
    end

    def initialize(
      id:,
      title:,
      size: :medium,
      title_hidden: false,
      primary_action: nil,
      secondary_actions: [],
      sectioned: false,
      flush: false,
      loading: false,
      dismissible: true,
      open: false,
      close_label: "Close",
      **html_attributes
    )
      @id = id
      @title = title
      @size = SIZES.key?(size&.to_sym) ? size.to_sym : :medium
      @title_hidden = title_hidden

      @primary = primary_action&.to_h&.symbolize_keys

      @secondary = Array(secondary_actions).map do |action|
        action.to_h.symbolize_keys
      end

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
        class: [
          DRAWER,
          SIZES[@size],
          @html_attributes[:class]
        ].flatten.compact.join(" "),
        aria: {
          labelledby: title_id,
          busy: (@loading || nil)
        },
        data: {
          sui_side_drawer: "",
          dismissible: (@dismissible ? "" : nil),
          open_on_load: (@open ? "" : nil)
        }
      )
    end

    def header_classes
      @title_hidden ? HEADER_HIDDEN : HEADER.join(" ")
    end

    def body_classes
      [
        BODY,
        (BODY_PADDING unless @flush || @sectioned || @loading)
      ].compact.join(" ")
    end

    def actions?
      @primary.present? || @secondary.any?
    end

    def spinner(css)
      tag.svg(
        tag.circle(
          cx: 10,
          cy: 10,
          r: 7.5,
          stroke: "currentColor",
          "stroke-width": 2,
          "stroke-dasharray": "34 14",
          "stroke-linecap": "round",
          fill: "none"
        ),
        viewBox: "0 0 20 20",
        class: css,
        aria: { hidden: true }
      )
    end

    def close_icon
      tag.svg(
        tag.path(d: "m5.5 5.5 9 9m0-9-9 9"),
        viewBox: "0 0 20 20",
        width: 20,
        height: 20,
        fill: "none",
        stroke: "currentColor",
        "stroke-width": 1.6,
        "stroke-linecap": "round",
        aria: { hidden: true }
      )
    end

    def action_button(action, variant:)
      variant = :critical if action[:destructive] && variant == :primary
      variant = :secondary if action[:destructive] && variant == :secondary

      attrs = (action[:attributes] || {}).dup

      if action[:close]
        attrs[:data] = (attrs[:data] || {}).merge(
          sui_side_drawer_close: ""
        )
      end

      if action[:loading]
        attrs[:aria] = (attrs[:aria] || {}).merge(busy: true)
      end

      css = [
        (
          "tw:text-danger tw:hover:text-danger" if
          action[:destructive] && variant == :secondary
        ),
        attrs.delete(:class)
      ].compact.join(" ").presence

      render(
        ButtonComponent.new(
          variant: variant,
          href: action[:href],
          disabled: action[:disabled] || action[:loading] || false,
          type: attrs.delete(:type) || "button",
          class: css,
          **attrs
        )
      ) do
        if action[:loading]
          safe_join([
            spinner(BUTTON_SPINNER),
            tag.span(action[:label], class: "tw:sr-only")
          ])
        else
          action[:label]
        end
      end
    end
  end
end