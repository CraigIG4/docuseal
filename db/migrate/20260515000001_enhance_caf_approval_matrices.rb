# frozen_string_literal: true

# Enhances caf_approval_matrices for the admin UI:
#   - Adds a human name column
#   - Replaces single document_type with a JSONB array of agreement_types
#   - Adds optional entity_scope (array of entity keys, null = all entities)
#   - Adds optional value_threshold (decimal, null = no threshold)
#   - Drops the old partial unique index (name uniqueness is now handled in app)
#   - Creates matrix_audit_events for MATRIX_CREATED / UPDATED / DEACTIVATED / APPLIED
class EnhanceCafApprovalMatrices < ActiveRecord::Migration[8.1]
  def up
    # ---- caf_approval_matrices ------------------------------------------------

    # Add new columns (nullable initially so existing rows survive)
    add_column :caf_approval_matrices, :name,            :string
    add_column :caf_approval_matrices, :agreement_types, :jsonb,   default: [], null: false
    add_column :caf_approval_matrices, :entity_scope,    :jsonb                         # null = all entities
    add_column :caf_approval_matrices, :value_threshold, :decimal, precision: 15, scale: 2

    # Migrate existing document_type → agreement_types array
    execute <<~SQL
      UPDATE caf_approval_matrices
      SET agreement_types = jsonb_build_array(document_type),
          name            = initcap(replace(document_type, '_', ' ')) || ' (migrated)'
      WHERE document_type IS NOT NULL
    SQL

    # Drop the old partial unique index (we allow multiple active matrices per account now)
    remove_index :caf_approval_matrices,
                 name: 'idx_caf_approval_matrices_active_unique'

    # Make document_type nullable — kept for backward compat but no longer authoritative
    change_column_null :caf_approval_matrices, :document_type, true

    # Back-fill name on any rows that somehow had a NULL document_type
    execute <<~SQL
      UPDATE caf_approval_matrices SET name = 'Unnamed Matrix' WHERE name IS NULL
    SQL

    # Now enforce NOT NULL on name
    change_column_null :caf_approval_matrices, :name, false

    # New index: prevent duplicate active matrices for the same account + name
    add_index :caf_approval_matrices,
              %i[account_id name],
              unique: true,
              where: 'active = true',
              name: 'idx_caf_approval_matrices_active_name_unique'

    # ---- matrix_audit_events --------------------------------------------------

    create_table :matrix_audit_events do |t|
      t.bigint   :account_id,             null: false
      t.bigint   :user_id                               # null = system/seed
      t.bigint   :caf_approval_matrix_id, null: false
      t.string   :event_type,             null: false   # MATRIX_CREATED etc.
      t.jsonb    :data,                   null: false, default: {}
      t.datetime :created_at,             null: false
    end

    add_index :matrix_audit_events, :account_id
    add_index :matrix_audit_events, :caf_approval_matrix_id
    add_index :matrix_audit_events, :event_type

    add_foreign_key :matrix_audit_events, :accounts
    add_foreign_key :matrix_audit_events, :caf_approval_matrices
  end

  def down
    drop_table :matrix_audit_events

    remove_index :caf_approval_matrices,
                 name: 'idx_caf_approval_matrices_active_name_unique'

    change_column_null :caf_approval_matrices, :document_type, false

    add_index :caf_approval_matrices,
              %i[account_id document_type],
              unique: true,
              where: 'active = true',
              name: 'idx_caf_approval_matrices_active_unique'

    remove_column :caf_approval_matrices, :value_threshold
    remove_column :caf_approval_matrices, :entity_scope
    remove_column :caf_approval_matrices, :agreement_types
    remove_column :caf_approval_matrices, :name
  end
end
