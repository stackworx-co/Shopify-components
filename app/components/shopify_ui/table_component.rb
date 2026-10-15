# frozen_string_literal: true

module ShopifyUI
  class TableComponent < ViewComponent::Base
    strip_trailing_whitespace

    renders_one :filters, ->(**options) { TableFiltersComponent.new(**options) }
    renders_one :bulk_actions, ->(**options) { BulkActionsComponent.new(variant: :inline, **options) }
    renders_many :rows, ->(**options) { TableRowComponent.new(table: self, **options) }

    CARD = %w[
      tw:relative tw:overflow-hidden tw:rounded-surface tw:border tw:border-border tw:bg-surface tw:shadow-card
    ].freeze

    TABLE = "tw:w-full tw:border-collapse tw:bg-surface tw:font-sans"

    FILTERS_ROW = "tw:border-b tw:border-border"
    HEAD_ROW = "tw:border-b tw:border-border tw:bg-surface-secondary"
    # Flush: no card, full width; grey header reads as a rounded bar, no rule under it.
    FLUSH_HEAD_ROW = "tw:bg-surface-secondary"
    FLUSH_WRAPPER = "tw:w-full tw:bg-surface"
    FLUSH_CELL_ENDS = "tw:first:rounded-l-lg tw:last:rounded-r-lg"

    HEAD_CELL = %w[
      tw:px-2.5 tw:py-2 tw:text-left tw:align-middle tw:text-[12px] tw:font-medium
      tw:text-muted tw:whitespace-nowrap
    ].freeze

    CHECK_CELL = "tw:w-px tw:pl-3 tw:pr-1"

    NUMERIC = "tw:text-right tw:tabular-nums"

    EMPTY_CELL = "tw:px-4 tw:py-10 tw:text-center tw:text-[13px] tw:text-muted"

    SELECT_ALL = "this.closest('table').querySelectorAll('tbody input[type=checkbox]:not(:disabled)')" \
                 ".forEach(function (box) { box.checked = this.checked }, this)"

    attr_reader :selectable, :select_name

    # flush: true -> full-width table with no outer border/radius (Products index style).
    def initialize(columns:, selectable: false, select_name: "ids[]", card: true, flush: false,
                   empty: "No results found", **html_attributes)
      @columns = columns.map { |column| column.is_a?(Hash) ? column : { label: column } }
      @selectable = selectable
      @select_name = select_name
      @flush = flush
      @card = card && !flush
      @empty = empty
      @html_attributes = html_attributes
    end

    def flush?
      @flush
    end

    def head_row_classes
      @flush ? FLUSH_HEAD_ROW : HEAD_ROW
    end

    def numeric?(index)
      @columns.dig(index, :numeric) ? true : false
    end

    private

    def wrapper_classes
      [ (CARD if @card), (FLUSH_WRAPPER if @flush), @html_attributes[:class] ].flatten.compact.join(" ")
    end

    def wrapper_attributes
      @html_attributes.merge(class: wrapper_classes.presence, data: { sui_table: "" }.merge(@html_attributes[:data] || {}))
    end

    def head_cell_classes(column)
      [ HEAD_CELL, (NUMERIC if column[:numeric]), (FLUSH_CELL_ENDS if @flush) ].flatten.compact.join(" ")
    end

    def check_cell_classes
      [ HEAD_CELL, CHECK_CELL, (FLUSH_CELL_ENDS if @flush) ].flatten.compact.join(" ")
    end

    def column_count
      @columns.size + (@selectable ? 1 : 0)
    end
  end
end
