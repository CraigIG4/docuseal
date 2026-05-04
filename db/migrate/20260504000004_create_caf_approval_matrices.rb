class CreateCafApprovalMatrices < ActiveRecord::Migration[8.1]
  def change
    create_table :caf_approval_matrices do |t|
      t.references :account,       null: false, foreign_key: true
      t.string     :document_type, null: false
      t.jsonb      :stages_config, null: false, default: []
      t.boolean    :active,        null: false, default: true
      t.timestamps
    end

    add_index :caf_approval_matrices,
              %i[account_id document_type],
              unique: true,
              where: 'active = true',
              name:  'idx_caf_approval_matrices_active_unique'
  end
end