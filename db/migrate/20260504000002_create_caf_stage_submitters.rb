# frozen_string_literal: true

class CreateCafStageSubmitters < ActiveRecord::Migration[8.1]
  def change
    create_table :caf_stage_submitters do |t|
      t.references :caf_stage, null: false, foreign_key: true
      t.references :submitter, null: false, foreign_key: true
      t.string     :role,      null: false  # 'CLO', 'CFO', 'CEO', 'Counterparty', etc.
      t.integer    :position,  null: false, default: 0
      t.timestamps
    end

    add_index :caf_stage_submitters, %i[caf_stage_id submitter_id], unique: true
    add_index :caf_stage_submitters, %i[caf_stage_id position]
  end
end
