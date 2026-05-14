# frozen_string_literal: true

FactoryBot.define do
  factory :company do
    account
    name                  { Faker::Company.name }
    domain                { Faker::Internet.domain_name }
    primary_contact_name  { Faker::Name.name }
    primary_contact_email { Faker::Internet.email }
    registration_number   { "2024/#{Faker::Number.number(digits: 6)}/07" }
    country               { 'ZA' }
  end
end
