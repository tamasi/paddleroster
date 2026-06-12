class AddComplejoToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :complejo, foreign_key: true
  end
end
