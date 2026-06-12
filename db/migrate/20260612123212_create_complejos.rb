class CreateComplejos < ActiveRecord::Migration[8.1]
  def change
    create_table :complejos do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
