# Expense Line Items

## Summary

Add support for non-hourly expense lines on invoices (e.g. "Monthly internet and cell phone charges"). An expense line is an `InvoiceLine` with `task_id: nil` and `quantity`/`unit_price` set.

## Checklist

1. **Migration**: add `quantity` (decimal, nullable) and `unit_price` (decimal, nullable) to `invoice_lines`
2. **Model**: no changes — fields are optional, no new validations
3. **Wizard step 3**: add "Add expense line" section below the task table
   - Description pre-filled: `"Monthly internet and cell phone charges - {period month} {period year}"`
   - Quantity defaults to 1, unit_price editable
   - Show for all customers (or gate later if needed)
4. **Wizard controller**: handle expense line params in `sync_lines_from_selection` — create/update expense line alongside task lines
5. **Lines controller**: permit `quantity` and `unit_price`
6. **Print view**: render expense lines (`task_id: nil`, `unit_price` present) as separate rows below task bullets, with qty and price in their columns
7. **Finalize service**: include expense subtotal (`quantity * unit_price`) in `total_amount` alongside hours-based amount. Or keep separate — TBD
8. **Specs**: migration, wizard expense params, print view rendering

## Open Questions

- Should expense amount be included in `total_amount` / Grand Total, or shown as a separate subtotal?
- Should we gate the expense section per-customer, or show it for all and leave it blank?
- Later: `customer_expenses` template table for recurring expense defaults per customer
