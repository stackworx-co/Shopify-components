# frozen_string_literal: true

module ShopifyUI
  class TableRowComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_many :cells

    ROW = %w[
      tw:border-b tw:border-border-secondary tw:last:border-b-0
      tw:hover:bg-surface-hover tw:has-checked:bg-surface-sunken
    ].freeze

    CELL = "tw:h-8 tw:px-1.5 tw:py-1.5 tw:first:pl-3 tw:last:pr-3 tw:align-middle tw:text-[12px] tw:text-ink tw:whitespace-nowrap"
    MUTED_CELL = "tw:h-8 tw:px-1.5 tw:py-1.5 tw:first:pl-3 tw:last:pr-3 tw:align-middle tw:text-[12px] tw:text-disabled tw:whitespace-nowrap"
    CHECK_CELL = "tw:w-px tw:pl-3 tw:pr-1 tw:py-1.5 tw:align-middle"
    # Flush tables: hover/selected highlight reads as a rounded bar.
    FLUSH_CELL_ENDS = "tw:first:rounded-l-lg tw:last:rounded-r-lg"

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
      [ (@muted ? MUTED_CELL : CELL), (ShopifyUI::TableComponent::NUMERIC if @table.numeric?(index)), flush_ends ]
        .compact.join(" ")
    end

    def check_cell_classes
      [ CHECK_CELL, flush_ends ].compact.join(" ")
    end

    def flush_ends
      FLUSH_CELL_ENDS if @table.flush?
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
