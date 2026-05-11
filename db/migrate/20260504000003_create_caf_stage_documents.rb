# frozen_string_literal: true

class CreateCafStageDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :caf_stage_documents do |t|
      t.references :submission,    null: false, foreign_key: true
      t.string     :document_uuid, null: false
      t.string     :document_name, null: false
      t.boolean    :internal_only, null: false, default: false
      t.boolean    :stripped,      null: false, default: false
      t.datetime   :stripped_at
      t.timestamps
    end

    add_index :caf_stage_documents, %i[submission_id document_uuid], unique: true
    add_index :caf_stage_documents, %i[submission_id internal_only]
  end
end
