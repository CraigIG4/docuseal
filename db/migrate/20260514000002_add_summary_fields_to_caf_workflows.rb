# frozen_string_literal: true

class AddSummaryFieldsToCafWorkflows < ActiveRecord::Migration[7.2]
  def change
    add_column :caf_workflows, :agreement_purpose, :text
    add_column :caf_workflows, :agreement_value,   :string
    add_column :caf_workflows, :agreement_term,    :string
    add_column :caf_workflows, :payment_terms,     :string
    add_column :caf_workflows, :key_risks,         :text
  end
end
