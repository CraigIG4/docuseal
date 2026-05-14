# frozen_string_literal: true

class CreateCompanySignatories < ActiveRecord::Migration[7.2]
  def change
    create_table :company_signatories do |t|
      t.references :company, null: false, foreign_key: true
      t.string  :name,            null: false
      t.string  :email,           null: false
      t.string  :phone
      t.string  :role_title
      t.text    :authority_basis
      t.integer :times_signed,    null: false, default: 0
      t.datetime :first_seen_at
      t.datetime :last_seen_at
      t.references :last_workflow, foreign_key: { to_table: :caf_workflows }, null: true
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :company_signatories, %i[company_id email], unique: true
  end
end
