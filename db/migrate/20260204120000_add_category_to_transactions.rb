class AddCategoryToTransactions < ActiveRecord::Migration[8.1]
	def change
		add_column :transactions, :category, :string
	end
end
		
