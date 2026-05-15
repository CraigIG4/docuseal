# frozen_string_literal: true

FactoryBot.define do
  factory :caf_approval_matrix do
    account
    sequence(:name) { |n| "Test Matrix #{n}" }
    agreement_types { ['nda'] }
    entity_scope    { nil }
    value_threshold { nil }
    active          { true }
    stages_config do
      [
        {
          'name'                       => 'Internal CAF Approval',
          'routing'                    => 'ordered',
          'required_roles'             => ['CLO', 'CEO'],
          'strip_internal_on_complete' => true
        },
        {
          'name'           => 'Counterparty Signing',
          'routing'        => 'parallel',
          'required_roles' => ['counterparty']
        }
      ]
    end

    trait :inactive do
      active { false }
    end

    trait :entity_scoped do
      entity_scope { ['iti'] }
    end

    trait :with_threshold do
      value_threshold { 5_000_000 }
    end

    trait :multi_type do
      agreement_types { %w[nda msa] }
    end
  end
end
