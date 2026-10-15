# frozen_string_literal: true

module ShopifyUI
  # Shopify admin thumbnail (Polaris Thumbnail).
  #
  # Covers: sizes (extra_small 24 / small 40 / medium 60 / large 80), image or placeholder icon
  # (:image, :product, :file, :collection, :customer), broken-image fallback to the placeholder,
  # lazy loading + srcset, fit (contain like the admin / cover), transparent background, quantity
  # badge ("2" on order line items), "+N" more overlay, link wrapper, and a stacked group.
  # mobile_size: a different size below sm (e.g. large on desktop, small on phones).
  class ThumbnailComponent < ViewComponent::Base
    strip_trailing_whitespace

    SIZES = {
      extra_small: "tw:size-6 tw:rounded-[6px]",
      small: "tw:size-10 tw:rounded-lg",
      medium: "tw:size-[60px] tw:rounded-[10px]",
      large: "tw:size-20 tw:rounded-[12px]"
    }.freeze
    MOBILE_SIZES = {
      extra_small: "tw:max-sm:size-6 tw:max-sm:rounded-[6px]",
      small: "tw:max-sm:size-10 tw:max-sm:rounded-lg",
      medium: "tw:max-sm:size-[60px] tw:max-sm:rounded-[10px]",
      large: "tw:max-sm:size-20 tw:max-sm:rounded-[12px]"
    }.freeze
    ICON_SIZES = { extra_small: "tw:size-3.5", small: "tw:size-5", medium: "tw:size-6", large: "tw:size-7" }.freeze

    BOX = %w[
      tw:relative tw:inline-flex tw:shrink-0 tw:items-center tw:justify-center tw:overflow-hidden
      tw:border tw:border-border tw:text-faint tw:align-middle tw:font-sans
    ].freeze
    BACKGROUNDS = { default: "tw:bg-surface", transparent: "tw:bg-transparent tw:border-transparent", subdued: "tw:bg-surface-secondary" }.freeze
    IMG = "tw:block tw:size-full tw:data-broken:hidden"
    FITS = { contain: "tw:object-contain", cover: "tw:object-cover" }.freeze
    PLACEHOLDER = "tw:hidden tw:group-data-broken:block tw:group-data-empty:block"

    QUANTITY = %w[
      tw:absolute tw:-right-1.5 tw:-top-1.5 tw:z-[1] tw:inline-flex tw:min-w-[18px] tw:h-[18px] tw:items-center tw:justify-center
      tw:rounded-full tw:bg-fill-tertiary tw:px-1 tw:text-[11px] tw:font-semibold tw:leading-none tw:text-ink
      tw:ring-2 tw:ring-surface tw:tabular-nums
    ].freeze
    MORE = "tw:absolute tw:inset-0 tw:flex tw:items-center tw:justify-center tw:bg-[rgba(0,0,0,.55)] tw:text-[13px] tw:font-semibold tw:text-white"

    LINK = "tw:inline-flex tw:rounded-[inherit] tw:focus-visible:outline-2 tw:focus-visible:outline-offset-2 tw:focus-visible:outline-link tw:hover:opacity-90"

    ICONS = {
      image: '<rect x="3" y="3" width="14" height="14" rx="3"/><circle cx="7.5" cy="7.5" r="1.4"/><path d="m17 13-3.6-3.6a1.2 1.2 0 0 0-1.7 0L4.5 16.6"/>',
      product: '<path d="M10.6 2.8h4.4a2.2 2.2 0 0 1 2.2 2.2v4.4a1.5 1.5 0 0 1-.44 1.06l-6.1 6.1a1.5 1.5 0 0 1-2.12 0l-4.5-4.5a1.5 1.5 0 0 1 0-2.12l6.1-6.1a1.5 1.5 0 0 1 1.06-.44Z"/><circle cx="13.6" cy="6.4" r="1.1"/>',
      file: '<path d="M11.5 2.75H6.25A1.5 1.5 0 0 0 4.75 4.25v11.5a1.5 1.5 0 0 0 1.5 1.5h7.5a1.5 1.5 0 0 0 1.5-1.5V6.5Z"/><path d="M11.5 2.75V6.5h3.75"/>',
      collection: '<rect x="3" y="6" width="11" height="11" rx="2"/><path d="M6 3h9a2 2 0 0 1 2 2v9"/>',
      customer: '<circle cx="10" cy="7" r="3"/><path d="M4 17c0-3 2.5-5 6-5s6 2 6 5"/>'
    }.freeze

    def initialize(source: nil, alt: "", size: :small, mobile_size: nil, placeholder: :image, srcset: nil, sizes: nil,
                   fit: :contain, background: :default, quantity: nil, more: nil, href: nil, lazy: true, **html_attributes)
      @source = source.presence
      @alt = alt
      @size = SIZES.key?(size&.to_sym) ? size.to_sym : :small
      @mobile_size = MOBILE_SIZES.key?(mobile_size&.to_sym) ? mobile_size.to_sym : nil
      @placeholder = ICONS.key?(placeholder&.to_sym) ? placeholder.to_sym : :image
      @srcset = srcset
      @sizes = sizes
      @fit = FITS.key?(fit&.to_sym) ? fit.to_sym : :contain
      @background = BACKGROUNDS.key?(background&.to_sym) ? background.to_sym : :default
      @quantity = quantity
      @more = more
      @href = href
      @lazy = lazy
      @html_attributes = html_attributes
    end

    def call
      box = tag.span(safe_join([ image_tag_html, placeholder_tag, more_tag ].compact),
                     class: box_classes, data: { empty: (@source ? nil : "") },
                     role: (@source ? nil : "img"), aria: { label: (@source ? nil : (@alt.presence || "No image")) })
      body = @quantity ? tag.span(safe_join([ box, tag.span(@quantity, class: QUANTITY.join(" "), aria: { label: "Quantity #{@quantity}" }) ]), class: "tw:relative tw:inline-flex tw:shrink-0") : box
      body = tag.a(body, href: @href, class: LINK, aria: { label: (@alt.presence if @href) }) if @href
      @html_attributes.any? ? tag.span(body, **@html_attributes, class: [ "tw:inline-flex", @html_attributes[:class] ].compact.join(" ")) : body
    end

    private

    def box_classes
      [ "tw:group", BOX, SIZES[@size], (MOBILE_SIZES[@mobile_size] if @mobile_size), BACKGROUNDS[@background] ].flatten.compact.join(" ")
    end

    def image_tag_html
      return unless @source

      tag.img(src: @source, alt: @alt, srcset: @srcset, sizes: @sizes, loading: (@lazy ? "lazy" : nil), decoding: "async",
              class: "#{IMG} #{FITS[@fit]}",
              onerror: "this.setAttribute('data-broken','');this.parentNode.setAttribute('data-broken','')")
    end

    def placeholder_tag
      tag.svg(ICONS[@placeholder].html_safe, viewBox: "0 0 20 20", fill: "none", stroke: "currentColor", "stroke-width": 1.5,
              "stroke-linecap": "round", "stroke-linejoin": "round",
              class: "#{PLACEHOLDER} #{ICON_SIZES[@size]}", aria: { hidden: true }, focusable: "false")
    end

    def more_tag
      tag.span("+#{@more}", class: MORE) if @more.to_i.positive?
    end
  end

  # Overlapping row of thumbnails (e.g. order line items), with "+N" on the last when there are more.
  class ThumbnailGroupComponent < ViewComponent::Base
    def initialize(items:, max: 3, size: :small, mobile_size: nil, **html_attributes)
      @items = Array(items).map { |i| i.to_h.symbolize_keys }
      @max = max
      @size = size
      @mobile_size = mobile_size
      @html_attributes = html_attributes
    end

    def call
      shown = @items.first(@max)
      extra = @items.size - shown.size
      thumbs = shown.each_with_index.map do |item, index|
        more = (extra if index == shown.size - 1 && extra.positive?)
        tag.span(render(ThumbnailComponent.new(size: @size, mobile_size: @mobile_size, more: more, **item)),
                 class: "tw:inline-flex tw:rounded-[10px] tw:ring-2 tw:ring-surface #{'tw:-ml-3 tw:max-sm:-ml-2.5' if index.positive?}")
      end
      tag.span(safe_join(thumbs), **@html_attributes, class: [ "tw:inline-flex tw:items-center", @html_attributes[:class] ].compact.join(" "),
               role: "group", aria: { label: "#{@items.size} items" })
    end
  end
end
