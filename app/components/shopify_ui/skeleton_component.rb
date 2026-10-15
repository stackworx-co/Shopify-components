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
  #   type: :table        rows: 5, columns: 5, selectable: true, thumbnail: true
  #   type: :stats        count: 4
  #   type: :page         title: true, back: false, primary_action: true, secondary_actions: 0,
  #                       layout: :one_column | :two_column, width: :default | :narrow | :full
  # Soft pulse animation (off with reduced motion). Phones: page columns stack, table drops extra columns,
  # cards go edge to edge, stats scroll sideways. Screen readers hear one "Loading…" per skeleton.
  class SkeletonComponent < ViewComponent::Base
    strip_trailing_whitespace

    TYPES = %i[body_text display_text thumbnail button tabs card table stats page].freeze

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

    CARD = "tw:relative tw:overflow-hidden tw:rounded-surface tw:bg-surface tw:shadow-card tw:ring-1 tw:ring-border-secondary tw:max-sm:rounded-none tw:max-sm:ring-0 tw:max-sm:border-y tw:max-sm:border-border"
    SECTION = "tw:flex tw:flex-col tw:gap-3 tw:p-4 tw:max-sm:p-3.5 tw:border-t tw:border-border-secondary tw:first:border-t-0"

    PAGE_WIDTHS = { default: "tw:max-w-[998px]", narrow: "tw:max-w-[662px]", full: "tw:max-w-none" }.freeze

    def initialize(type: :body_text, lines: 3, size: nil, width: nil, count: 4, fitted: false, title: true,
                   sections: 1, rows: 5, columns: 5, selectable: true, thumbnail: true, back: false,
                   primary_action: true, secondary_actions: 0, layout: :one_column, page_width: :default,
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
      @columns = columns.to_i.clamp(1, 10)
      @selectable = selectable
      @thumbnail = thumbnail
      @back = back
      @primary_action = primary_action
      @secondary_actions = secondary_actions.to_i
      @layout = layout&.to_sym == :two_column ? :two_column : :one_column
      @page_width = PAGE_WIDTHS.key?(page_width&.to_sym) ? page_width.to_sym : :default
      @label = label
      @html_attributes = html_attributes
    end

    def call
      tag.div(safe_join([ tag.span("#{@label}…", class: "tw:sr-only"), tag.div(send(@type), aria: { hidden: true }, class: "tw:contents") ]),
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
      cols = (0...@columns).map do |c|
        hide = c >= 3 ? "tw:max-sm:hidden" : nil
        tag.th(bone("tw:h-2.5 #{c.zero? ? 'tw:w-16' : 'tw:w-12'}"), class: [ "tw:px-2.5 tw:py-2.5 tw:text-left", hide ].compact.join(" "))
      end
      check = ->(tag_name) { content_tag(tag_name, tag.span(class: "#{BLOCK} tw:size-4 tw:rounded-[4px]"), class: "tw:w-px tw:pl-3 tw:pr-1 tw:py-2.5") }
      head = tag.tr(safe_join([ (check.call(:th) if @selectable), *cols ].compact), class: "tw:bg-surface-secondary tw:border-b tw:border-border")
      body = (0...@rows).map do |r|
        cells = (0...@columns).map do |c|
          hide = c >= 3 ? "tw:max-sm:hidden" : nil
          inner = if c.zero? && @thumbnail
                    tag.span(safe_join([ thumbnail(:small), bone("tw:h-2.5 tw:w-28 tw:max-sm:w-20") ]), class: "tw:flex tw:items-center tw:gap-3")
                  else
                    bone("tw:h-2.5 #{%w[tw:w-24 tw:w-16 tw:w-20 tw:w-12][(r + c) % 4]}")
                  end
          tag.td(inner, class: [ "tw:px-2.5 tw:py-3", hide ].compact.join(" "))
        end
        tag.tr(safe_join([ (check.call(:td) if @selectable), *cells ].compact), class: "tw:border-b tw:border-border-secondary tw:last:border-b-0")
      end
      tag.div(tag.table(safe_join([ tag.thead(head), tag.tbody(safe_join(body)) ]), class: "tw:w-full tw:border-collapse"), class: CARD)
    end

    def stats
      items = (0...@count).map do
        tag.div(safe_join([ bone("tw:h-2.5 tw:w-20"), bone("tw:h-3.5 tw:w-12"), bone("tw:h-1 tw:w-[72px]") ]),
                class: "tw:flex tw:shrink-0 tw:flex-col tw:gap-2 tw:pr-7 tw:max-sm:pr-5")
      end
      tag.div(tag.div(safe_join(items), class: "tw:relative tw:flex tw:overflow-hidden tw:px-4 tw:py-3.5"), class: CARD)
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
