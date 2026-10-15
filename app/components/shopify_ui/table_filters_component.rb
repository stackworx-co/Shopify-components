# frozen_string_literal: true

module ShopifyUI
  class TableFiltersComponent < ViewComponent::Base
    strip_trailing_whitespace

    CARD = %w[
      tw:rounded-surface tw:border tw:border-border tw:bg-surface tw:shadow-card
    ].freeze

    WRAPPER = "tw:flex tw:flex-col tw:font-sans"
    BAR = "tw:flex tw:flex-wrap tw:items-center tw:gap-2 tw:px-2.5 tw:py-2"
    TABS = "tw:relative tw:flex tw:min-w-0 tw:items-center tw:gap-1 tw:overflow-x-auto"

    TAB = %w[
      tw:inline-flex tw:h-7 tw:shrink-0 tw:items-center tw:gap-1.5 tw:rounded-full tw:px-3
      tw:text-[12.5px] tw:font-medium tw:no-underline tw:whitespace-nowrap tw:transition-colors tw:duration-100
      tw:hover:no-underline
      tw:focus-visible:outline-2 tw:focus-visible:-outline-offset-2 tw:focus-visible:outline-link
    ].freeze

    TAB_STATES = {
      selected: "tw:bg-fill-tertiary tw:text-ink tw:hover:text-ink",
      default: "tw:text-muted tw:hover:bg-surface-hover tw:hover:text-ink"
    }.freeze

    COUNT = "tw:text-[12px] tw:font-regular tw:text-muted"

    SEARCH = %w[
      tw:flex tw:h-7 tw:min-w-40 tw:flex-1 tw:items-center tw:gap-1.5 tw:rounded-full tw:px-2
      tw:text-muted tw:transition-colors tw:duration-100
      tw:hover:bg-surface-hover tw:focus-within:bg-surface-hover
      tw:focus-within:outline-2 tw:focus-within:-outline-offset-2 tw:focus-within:outline-link
    ].freeze

    SEARCH_INPUT = %w[
      tw:m-0 tw:w-full tw:min-w-0 tw:appearance-none tw:border-0 tw:bg-transparent tw:p-0
      tw:font-sans tw:text-[12.5px] tw:text-ink tw:outline-none tw:placeholder:text-muted
      tw:max-sm:text-[16px]
    ].freeze

    PILLS = "tw:flex tw:flex-wrap tw:items-center tw:gap-2 tw:px-2.5 tw:pb-2"

    PILL = %w[
      tw:inline-flex tw:h-7 tw:items-center tw:gap-1 tw:rounded-full tw:border tw:border-border
      tw:bg-surface tw:pr-1 tw:pl-3 tw:text-[12.5px] tw:font-medium tw:text-ink tw:whitespace-nowrap
    ].freeze

    PILL_REMOVE = %w[
      tw:inline-flex tw:size-5 tw:items-center tw:justify-center tw:rounded-full tw:text-muted
      tw:no-underline tw:hover:bg-fill-tertiary tw:hover:text-ink
      tw:focus-visible:outline-2 tw:focus-visible:outline-link
    ].freeze

    CLEAR = "tw:text-[12.5px] tw:font-medium tw:text-link tw:no-underline tw:hover:underline"
    CHECK = "tw:text-ink"

    def initialize(url:, views: [], view_style: :tabs, query: nil, query_name: :q,
                   placeholder: "Search and filter", sort: [], applied: [], add_filters: [],
                   clear_href: nil, params: {}, card: false, **html_attributes)
      @url = url
      @views = views
      @view_style = view_style == :menu ? :menu : :tabs
      @query = query
      @query_name = query_name
      @placeholder = placeholder
      @sort = sort
      @applied = applied
      @add_filters = add_filters
      @clear_href = clear_href
      @params = params
      @card = card
      @html_attributes = html_attributes
    end

    private

    def wrapper_attributes
      @html_attributes.merge(class: [ WRAPPER, (CARD if @card), @html_attributes[:class] ].flatten.compact.join(" "))
    end

    def tab_classes(view)
      [ TAB, TAB_STATES[view[:selected] ? :selected : :default] ].flatten.join(" ")
    end

    def selected_view
      @views.find { |view| view[:selected] } || @views.first
    end

    def pills?
      @applied.any? || @add_filters.any?
    end

    def check_icon
      tag.svg(tag.path(d: "m5 10 3.5 3.5L15 7"), viewBox: "0 0 20 20", width: 20, height: 20, fill: "none",
              stroke: "currentColor", "stroke-width": 1.8, "stroke-linecap": "round", "stroke-linejoin": "round",
              class: CHECK)
    end

    def blank_icon
      tag.span(class: "tw:size-5")
    end

    def sort_icon
      tag.svg(tag.path(d: "M7 4v12M4 7l3-3 3 3M13 16V4M10 13l3 3 3-3"), viewBox: "0 0 20 20", width: 20,
              height: 20, fill: "none", stroke: "currentColor", "stroke-width": 1.6, "stroke-linecap": "round",
              "stroke-linejoin": "round", "aria-hidden": true)
    end
  end
end
