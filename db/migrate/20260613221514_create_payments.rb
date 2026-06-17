class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :turno, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.datetime :paid_at, null: false
      t.references :registered_by, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
