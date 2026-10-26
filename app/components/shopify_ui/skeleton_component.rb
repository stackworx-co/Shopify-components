# frozen_string_literal: true

module ShopifyUI
  # Shopify admin loading skeletons (Polaris SkeletonBodyText / SkeletonDisplayText / SkeletonThumbnail /
  # SkeletonTabs / SkeletonPage), plus button, card, table and stats skeletons for this library's components.
  #
  #   type: :body_text    lines: 3 (last line shorter)
  #   type: :display_text size: :small | :medium | :large | :extra_large, width: "60%"
  #   type: :thumbnail    size: :extra_small | :small | :medium | :large
  #   type: :button       size: :slim | :medium | :large
  #   type: :tabs         count: 4, fitted: false
  #   type: :card         title: true, sections: 1, lines: 3
  #   type: :table        rows: 5, columns: 5 | [{ width: "40%", numeric: true, thumbnail: true }, …],
  #                       selectable: true, thumbnail: true, card: true, phone_columns: 3
  #   type: :stats        count: 4, variant: :strip | :grid | :chart, columns: nil (same breakpoints as StatsCardComponent)
  #   type: :chart        height: 180, title: true, legend: 0 (legend items), card: true — LineChartComponent
  #   type: :donut        size: :small | :medium | :large, legend: :right | :bottom | false, count: 4, title: true,
  #                       card: true — DonutChartComponent
  #   type: :progress_bar size: :small | :medium | :large — ProgressBarComponent
  #   type: :page         title: true, back: false, primary_action: true, secondary_actions: 0,
  #                       layout: :one_column | :two_column, width: :default | :narrow | :full
  # Any type: heading: true | "30%" adds a heading bar above it (e.g. a section title over a table).
  # Soft pulse animation (off with reduced motion). Phones: page columns stack, table drops extra columns,
  # cards go edge to edge, stats scroll sideways. Screen readers hear one "Loading…" per skeleton.
  class SkeletonComponent < ViewComponent::Base
    strip_trailing_whitespace

    TYPES = %i[body_text display_text thumbnail button tabs card table stats chart donut progress_bar page].freeze

    BONE = "tw:block tw:rounded-full tw:bg-fill-tertiary tw:animate-pulse tw:motion-reduce:animate-none"
    BLOCK = "tw:block tw:bg-fill-tertiary tw:animate-pulse tw:motion-reduce:animate-none"

    DISPLAY = { small: "tw:h-5", medium: "tw:h-6", large: "tw:h-7", extra_large: "tw:h-9 tw:max-sm:h-8" }.freeze
    THUMB = {
      extra_small: "tw:size-6 tw:rounded-[6px]", small: "tw:size-10 tw:rounded-lg",
      medium: "tw:size-[60px] tw:rounded-[10px]", large: "tw:size-20 tw:rounded-[12px]"
    }.freeze
    BUTTON = { slim: "tw:h-7 tw:w-20", medium: "tw:h-8 tw:w-24 tw:max-sm:h-10", large: "tw:h-9 tw:w-28 tw:max-sm:h-11" }.freeze
    LINE_WIDTHS = %w[tw:w-full tw:w-[92%] tw:w-[96%] tw:w-[88%] tw:w-[94%]].freeze
    LAST_LINE = "tw:w-[62%]"

    CARD = "tw:relative tw:overflow-hidden tw:rounded-surface tw:bg-surface tw:shadow-card tw:max-sm:rounded-none tw:max-sm:ring-0 tw:max-sm:border-y tw:max-sm:border-border"
    SECTION = "tw:flex tw:flex-col tw:gap-3 tw:p-4 tw:max-sm:p-3.5 tw:border-t tw:border-border-secondary tw:first:border-t-0"

    PROGRESS = { small: "tw:h-2", medium: "tw:h-4", large: "tw:h-8" }.freeze
    STAT_VARIANTS = %i[strip grid chart].freeze
    PAD = "tw:p-4 tw:max-sm:p-3.5"

    PAGE_WIDTHS = { default: "tw:max-w-[998px]", narrow: "tw:max-w-[662px]", full: "tw:max-w-none" }.freeze

    def initialize(type: :body_text, lines: 3, size: nil, width: nil, count: 4, fitted: false, title: true,
                   sections: 1, rows: 5, columns: 5, selectable: true, thumbnail: true, back: false,
                   primary_action: true, secondary_actions: 0, layout: :one_column, page_width: :default,
                   variant: :strip, height: 180, legend: nil, card: true, heading: false, phone_columns: 3,
                   label: "Loading", **html_attributes)
      @type = TYPES.include?(type&.to_sym) ? type.to_sym : :body_text
      @lines = lines.to_i.clamp(1, 20)
      @size = size&.to_sym
      @width = width
      @count = count.to_i.clamp(1, 12)
      @fitted = fitted
      @title = title
      @sections = sections.to_i.clamp(1, 6)
      @rows = rows.to_i.clamp(1, 30)
      @column_specs = columns.is_a?(Array) ? columns.first(10).map { |c| c.is_a?(Hash) ? c.transform_keys(&:to_sym) : { width: c } } : nil
      @columns = @column_specs ? [ @column_specs.size, 1 ].max : columns.to_i.clamp(1, 10)
      @stats_columns = columns.is_a?(Array) ? nil : columns
      @selectable = selectable
      @thumbnail = thumbnail
      @back = back
      @primary_action = primary_action
      @secondary_actions = secondary_actions.to_i
      @layout = layout&.to_sym == :two_column ? :two_column : :one_column
      @page_width = PAGE_WIDTHS.key?(page_width&.to_sym) ? page_width.to_sym : :default
      @variant = STAT_VARIANTS.include?(variant&.to_sym) ? variant.to_sym : :strip
      @height = height.to_i.clamp(40, 600)
      @legend = legend
      @card = card
      @heading = heading
      @phone_columns = phone_columns.to_i.clamp(1, 10)
      @label = label
      @html_attributes = html_attributes
    end

    def call
      tag.div(safe_join([ tag.span("#{@label}…", class: "tw:sr-only"), tag.div(with_heading(send(@type)), aria: { hidden: true }, class: "tw:contents") ]),
              **@html_attributes, role: "status", aria: { busy: true, live: "polite" },
              class: [ "tw:font-sans", @html_attributes[:class] ].compact.join(" "))
    end

    private

    def bone(css, style: nil)
      tag.span(class: "#{BONE} #{css}", style: style)
    end

    def body_text(lines = @lines)
      bones = (0...lines).map { |i| bone("tw:h-2.5 #{i == lines - 1 && lines > 1 ? LAST_LINE : LINE_WIDTHS[i % LINE_WIDTHS.size]}") }
      tag.span(safe_join(bones), class: "tw:flex tw:flex-col tw:gap-2.5 tw:py-0.5")
    end

    def display_text(size = @size, width = @width)
      bone("#{DISPLAY[DISPLAY.key?(size) ? size : :medium]} tw:max-w-full tw:rounded-lg", style: "width: #{width || '60%'}")
    end

    def thumbnail(size = @size)
      tag.span(class: "#{BLOCK} tw:shrink-0 #{THUMB[THUMB.key?(size) ? size : :small]}")
    end

    def button(size = @size)
      bone("tw:shrink-0 #{BUTTON[BUTTON.key?(size) ? size : :medium]}")
    end

    def tabs
      widths = %w[tw:w-10 tw:w-24 tw:w-16 tw:w-20 tw:w-14 tw:w-24]
      items = (0...@count).map { |i| bone("tw:h-7 tw:max-sm:h-10 tw:shrink-0 #{@fitted ? 'tw:flex-1' : widths[i % widths.size]}") }
      tag.div(safe_join(items), class: "tw:relative tw:flex tw:min-w-0 tw:gap-2 tw:overflow-hidden")
    end

    def card(title: @title, sections: @sections, lines: @lines)
      parts = (0...sections).map do |i|
        head = (i.zero? && title) ? display_text(:small, "40%") : nil
        tag.div(safe_join([ head, body_text(lines) ].compact), class: SECTION)
      end
      tag.div(safe_join(parts), class: CARD)
    end

    def table
      specs = (0...@columns).map { |c| @column_specs&.[](c) || {} }
      hide = ->(c) { c >= @phone_columns ? "tw:max-sm:hidden" : nil }
      cols = specs.each_with_index.map do |spec, c|
        tag.th(bone("tw:h-2.5 #{c.zero? ? 'tw:w-16' : 'tw:w-12'}#{' tw:ml-auto' if spec[:numeric]}"),
               class: [ "tw:px-2.5 tw:py-2.5 tw:text-left", hide.call(c) ].compact.join(" "),
               style: spec[:width] ? "width: #{spec[:width]}" : nil)
      end
      check = ->(tag_name) { content_tag(tag_name, tag.span(class: "#{BLOCK} tw:size-4 tw:rounded-[4px]"), class: "tw:w-px tw:pl-3 tw:pr-1 tw:py-2.5") }
      head = tag.tr(safe_join([ (check.call(:th) if @selectable), *cols ].compact), class: "tw:bg-surface-secondary tw:border-b tw:border-border")
      body = (0...@rows).map do |r|
        cells = specs.each_with_index.map do |spec, c|
          thumb = spec.key?(:thumbnail) ? spec[:thumbnail] : (c.zero? && @thumbnail)
          inner = if thumb
                    tag.span(safe_join([ thumbnail(:small), bone("tw:h-2.5 tw:w-28 tw:max-sm:w-20") ]), class: "tw:flex tw:items-center tw:gap-3")
                  else
                    bone("tw:h-2.5 tw:max-w-full #{%w[tw:w-24 tw:w-16 tw:w-20 tw:w-12][(r + c) % 4]}#{' tw:ml-auto' if spec[:numeric]}")
                  end
          tag.td(inner, class: [ "tw:px-2.5 tw:py-3", hide.call(c) ].compact.join(" "))
        end
        tag.tr(safe_join([ (check.call(:td) if @selectable), *cells ].compact), class: "tw:border-b tw:border-border-secondary tw:last:border-b-0")
      end
      table = tag.table(safe_join([ tag.thead(head), tag.tbody(safe_join(body)) ]), class: "tw:w-full tw:border-collapse#{' tw:table-fixed' if specs.any? { |sp| sp[:width] }}")
      tag.div(table, class: @card ? CARD : "tw:w-full tw:bg-surface")
    end

    def stats
      return stats_strip if @variant == :strip

      s = ShopifyUI::StatsCardComponent
      max = @variant == :chart ? 6 : 4
      cols = (@stats_columns || @count.clamp(1, max)).to_i.clamp(1, 6)
      grid_cols = (s::CHART_COLUMNS[cols] if @variant == :chart) || s::GRID_COLUMNS[cols]
      label = tag.span(bone("tw:h-2.5 tw:w-24 tw:max-w-full"), class: "tw:flex tw:h-5 tw:items-center")
      cards = (0...@count).map do
        if @variant == :chart
          tag.div(safe_join([ label,
                              tag.span(bone("tw:h-5 tw:w-20"), class: "tw:mt-1.5 tw:flex tw:h-[25px] tw:items-center"),
                              tag.span(class: "#{BLOCK} tw:mt-3 tw:h-14 tw:w-full tw:rounded-lg") ]),
                  class: "#{s::CARD} #{s::CHART_CARD}")
        else
          tag.div(safe_join([ label,
                              tag.span(bone("tw:h-5 tw:w-24"), class: "tw:flex tw:h-[25px] tw:items-center"),
                              tag.span(class: "#{BLOCK} tw:h-12 tw:w-full tw:rounded-lg") ]),
                  class: "#{s::CARD} #{s::GRID_CARD}")
        end
      end
      tag.div(safe_join(cards), class: "#{@variant == :chart ? s::CHART_GRID : s::GRID} #{grid_cols}")
    end

    def stats_strip
      items = (0...@count).map do
        tag.div(safe_join([ bone("tw:h-2.5 tw:w-20"), bone("tw:h-3.5 tw:w-12"), bone("tw:h-1 tw:w-[72px]") ]),
                class: "tw:flex tw:shrink-0 tw:flex-col tw:gap-2 tw:pr-7 tw:max-sm:pr-5")
      end
      tag.div(tag.div(safe_join(items), class: "tw:relative tw:flex tw:overflow-hidden tw:px-4 tw:py-3.5"), class: CARD)
    end

    # Mirrors LineChartComponent: Y labels | plot (height px) / X labels row (mt-2 h-4) / optional legend.
    def chart
      y_axis = tag.div(safe_join(Array.new(5) { bone("tw:h-2 tw:w-6") }),
                       class: "tw:flex tw:w-8 tw:shrink-0 tw:flex-col tw:items-end tw:justify-between tw:py-0.5",
                       style: "height: #{@height}px")
      x_axis = tag.div(safe_join((0...5).map { |i| bone("tw:h-2 tw:w-10#{' tw:max-sm:hidden' if i.odd?}") }),
                       class: "tw:mt-2 tw:flex tw:h-4 tw:items-center tw:justify-between")
      plot = tag.div(safe_join([ tag.span(class: "#{BLOCK} tw:w-full tw:rounded-lg", style: "height: #{@height}px"), x_axis ]),
                     class: "tw:min-w-0 tw:flex-1")
      legend_count = @legend.is_a?(Integer) ? @legend.clamp(0, 8) : (@legend ? 2 : 0)
      legend = if legend_count.positive?
                 tag.div(safe_join(Array.new(legend_count) { bone("tw:h-2.5 tw:w-20") }), class: "tw:mt-3 tw:flex tw:flex-wrap tw:gap-x-4 tw:gap-y-2")
               end
      body = safe_join([ tag.div(safe_join([ y_axis, plot ]), class: "tw:flex tw:w-full tw:gap-2"), legend ].compact)
      in_card(body)
    end

    # Mirrors DonutChartComponent: ring (same sizes, one smaller on phones) + legend right / bottom.
    def donut
      d = ShopifyUI::DonutChartComponent
      size = d::SIZES.key?(@size) ? @size : :medium
      layout = @legend == false ? :none : (@legend.to_s == "bottom" ? :bottom : :right)
      ring = tag.span(tag.svg(tag.circle(cx: 60, cy: 60, r: d::RADIUS, fill: "none", "stroke-width": d::STROKE, class: "tw:stroke-fill-tertiary"),
                              viewBox: "0 0 120 120", class: "tw:block tw:size-full"),
                      class: "tw:block tw:shrink-0 tw:animate-pulse tw:motion-reduce:animate-none #{d::SIZES[size]}")
      legend = unless layout == :none
                 rows = (0...@count).map do |i|
                   tag.li(safe_join([ tag.span(class: "#{BLOCK} tw:size-2 tw:shrink-0 tw:rounded-full"),
                                      tag.span(bone("tw:h-2.5 #{%w[tw:w-24 tw:w-16 tw:w-20][i % 3]} tw:max-w-full"), class: "tw:min-w-0 tw:flex-1"),
                                      bone("tw:h-2.5 tw:w-8"), bone("tw:h-2.5 tw:w-10") ]),
                          class: "tw:flex tw:h-5 tw:items-center tw:gap-2")
                 end
                 tag.ul(safe_join(rows), class: "#{d::LEGEND}#{' tw:max-w-[320px]' if layout == :bottom}")
               end
      in_card(tag.div(safe_join([ ring, legend ].compact), class: d::LAYOUTS[layout]))
    end

    def progress_bar
      bone("tw:w-full #{PROGRESS[PROGRESS.key?(@size) ? @size : :medium]}")
    end

    def in_card(body)
      return body unless @card

      head = tag.div(display_text(:small, "35%"), class: "tw:mb-4") if @title
      tag.div(tag.div(safe_join([ head, body ].compact), class: PAD), class: CARD)
    end

    def with_heading(node)
      return node unless @heading

      width = @heading.is_a?(String) ? @heading : "30%"
      tag.div(safe_join([ tag.div(display_text(:small, width), class: "tw:max-sm:px-4"), node ]), class: "tw:flex tw:flex-col tw:gap-3")
    end

    def page
      header = tag.div(safe_join([
        tag.div(safe_join([ (tag.span(class: "#{BLOCK} tw:size-7 tw:rounded-control tw:shrink-0") if @back),
                            (display_text(:large, "180px") if @title) ].compact), class: "tw:flex tw:min-w-0 tw:flex-1 tw:items-center tw:gap-2"),
        tag.div(safe_join([ *Array.new(@secondary_actions) { tag.span(button(:medium), class: "tw:max-md:hidden") },
                            (tag.span(class: "#{BLOCK} tw:size-8 tw:rounded-full tw:md:hidden") if @secondary_actions.positive?),
                            (button(:medium) if @primary_action) ].compact), class: "tw:flex tw:shrink-0 tw:items-center tw:gap-2")
      ]), class: "tw:flex tw:items-center tw:justify-between tw:gap-4 tw:pb-4 tw:max-sm:px-4")

      main = tag.div(safe_join([ card(sections: 2), card(title: true, lines: 2) ]), class: "tw:flex tw:min-w-0 tw:flex-col tw:gap-4")
      body = if @layout == :two_column
               side = tag.div(safe_join([ card(lines: 2), card(lines: 4) ]), class: "tw:flex tw:min-w-0 tw:flex-col tw:gap-4")
               tag.div(safe_join([ main, side ]), class: "tw:grid tw:gap-4 tw:lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]")
             else
               main
             end
      tag.div(safe_join([ header, body ]), class: "tw:mx-auto tw:w-full #{PAGE_WIDTHS[@page_width]}")
    end
  end
end
