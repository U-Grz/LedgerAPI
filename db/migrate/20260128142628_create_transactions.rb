class CreateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :transaction_type, null: false
      t.text :description
      t.date :date, null: false
      t.timestamps
    end
    
    add_index :transactions, :transaction_type
    add_index :transactions, :date
    add_index :transactions, [:user_id, :date]
  end
end