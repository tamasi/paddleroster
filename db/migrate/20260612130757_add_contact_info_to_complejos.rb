class AddContactInfoToComplejos < ActiveRecord::Migration[8.1]
  def change
    add_column :complejos, :contact_info, :string
  end
end
