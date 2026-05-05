class CreateCafWorkflows < ActiveRecord::Migration[8.0]
  def change
    create_table :caf_workflows do |t|
      t.references :account,          null: false, foreign_key: true
      t.references :created_by_user,  null: false, foreign_key: { to_table: :users }
      t.string  :entity,              null: false
      t.string  :caf_type,            null: false
      t.string  :status,              null: false, default: 'draft'
      t.string  :requestor_name
      t.string  :requestor_email
      t.string  :contracting_party
      t.string  :ignition_company
      t.string  :counterparty_name
      t.string  :counterparty_email
      t.text    :high_level_summary
      t.text    :mandate_description
      t.jsonb   :long_form_data,      default: {}
      t.jsonb   :signatories,         default: []
      t.references :caf_submission,   foreign_key: { to_table: :submissions }
      t.references :contract_submission, foreign_key: { to_table: :submissions }
      t.timestamps
    end

    add_index :caf_workflows, [:account_id, :status]
    add_index :caf_workflows, [:account_id, :created_at]
  end
end
