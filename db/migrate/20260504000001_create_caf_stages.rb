# frozen_string_literal: true

class CreateCafStages < ActiveRecord::Migration[8.1]
  def change
    create_table :caf_stages do |t|
      t.references :submission,              null: false, foreign_key: true
      t.string     :name,                    null: false
      t.integer    :position,                null: false, default: 0
      t.string     :routing,                 null: false, default: 'ordered'
      t.string     :status,                  null: false, default: 'pending'
      t.boolean    :strip_internal_on_complete, null: false, default: false
      t.datetime   :activated_at
      t.datetime   :completed_at
      t.timestamps
    end

    add_index :caf_stages, %i[submission_id position], unique: true
    add_index :caf_stages, :status
    add_check_constraint :caf_stages,
                         "routing IN ('ordered', 'parallel', 'hybrid')",
                         name: 'caf_stages_routing_check'
    add_check_constraint :caf_stages,
                         "status IN ('pending', 'active', 'complete', 'skipped')",
                         name: 'caf_stages_status_check'
  end
end
