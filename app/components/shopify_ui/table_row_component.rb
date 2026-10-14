# frozen_string_literal: true

module ShopifyUI
  class TableRowComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_many :cells

    ROW = %w[
      tw:border-b tw:border-border-secondary tw:last:border-b-0
      tw:hover:bg-surface-hover tw:has-checked:bg-surface-sunken
    ].freeze

    CELL = "tw:px-2.5 tw:py-[9px] tw:align-middle tw:text-[13px] tw:text-ink tw:whitespace-nowrap"
    MUTED_CELL = "tw:px-2.5 tw:py-[9px] tw:align-middle tw:text-[13px] tw:text-disabled tw:whitespace-nowrap"
    CHECK_CELL = "tw:w-px tw:pl-3 tw:pr-1 tw:py-[9px] tw:align-middle"

    def initialize(table:, id: nil, selected: false, muted: false, **html_attributes)
      @table = table
      @id = id
      @selected = selected
      @muted = muted
      @html_attributes = html_attributes
    end

    private

    def row_attributes
      @html_attributes.merge(class: [ ROW, @html_attributes[:class] ].flatten.compact.join(" "))
    end

    def cell_classes(index)
      [ (@muted ? MUTED_CELL : CELL), (ShopifyUI::TableComponent::NUMERIC if @table.numeric?(index)) ]
        .compact.join(" ")
    end

    def checkbox
      ShopifyUI::CheckboxComponent.new(
        name: @table.select_name,
        value: @id,
        checked: @selected,
        aria: { label: "Select row" }
      )
    end
  end
end
