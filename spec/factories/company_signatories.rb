# frozen_string_literal: true

FactoryBot.define do
  factory :company_signatory do
    company
    name          { Faker::Name.name }
    email         { Faker::Internet.email }
    role_title    { 'Director' }
    times_signed  { 1 }
    first_seen_at { 30.days.ago }
    last_seen_at  { 7.days.ago }
    active        { true }
  end
end
