class AddHeaderToInvoiceLines < ActiveRecord::Migration[8.1]
  def change
    add_column :invoice_lines, :header, :string
  end
end
