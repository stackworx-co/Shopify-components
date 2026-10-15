# frozen_string_literal: true

module ShopifyUI
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
