# frozen_string_literal: true

FactoryBot.define do
  factory :caf_stage do
    submission
    name     { 'Internal Approval' }
    position { 0 }
    routing  { 'ordered' }
    status   { 'active' }
  end
end
