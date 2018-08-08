class CreateCorporateDrinkPreferences < ActiveRecord::Migration[5.1]
  def change
    create_table :corporate_drink_preferences do |t|
      t.references :account, foreign_key: true
      t.string :drink_type
      t.integer :number_of_employees
      t.integer :number_of_drinks_per_employee
      t.decimal :budget_per_employee
      t.text :admin_comments

      t.timestamps
    end
  end
end
