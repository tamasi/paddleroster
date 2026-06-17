class AddPaidAtIndexToPayments < ActiveRecord::Migration[8.1]
  def change
    add_index :payments, :paid_at
  end
end
