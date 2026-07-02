# frozen_string_literal: true

module InvoicesHelper
  STATUS_BADGE_CLASSES = {
    'draft' => 'bg-slate-100 text-slate-500 dark:bg-slate-700 dark:text-slate-400',
    'ready' => 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300',
    'sent' => 'bg-amber-100 text-amber-700 dark:bg-amber-900 dark:text-amber-300',
    'paid' => 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300'
  }.freeze

  def invoice_status_badge(status)
    tag.span status.capitalize,
             class: "px-2 py-0.5 text-xs rounded-full #{STATUS_BADGE_CLASSES.fetch(status)}"
  end

  def alternating_row_class(index)
    index.odd? ? "bg-slate-200" : ""
  end
end
