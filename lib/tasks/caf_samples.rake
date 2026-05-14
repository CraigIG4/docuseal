# frozen_string_literal: true

# Generates sample CAF PDFs for each CAF type and saves them to tmp/caf_samples/.
# Used to verify PDF rendering after template changes.
#
# Usage:
#   bundle exec rake igsign:caf:generate_samples
#   bundle exec rake "igsign:caf:generate_samples[long_form]"

namespace :igsign do
  namespace :caf do
    desc 'Generate sample CAF PDFs for all (or a specified) CAF type. Saves to tmp/caf_samples/'
    task :generate_samples, [:caf_type] => :environment do |_, args|
      require 'fileutils'

      out_dir = Rails.root.join('tmp', 'caf_samples')
      FileUtils.mkdir_p(out_dir)

      types = if args[:caf_type].present?
                [args[:caf_type].strip]
              else
                CafPdfGenerator::TEMPLATES.keys
              end

      # Stub agreement that satisfies CafPdfGenerator#caf_data without hitting
      # the database. We use a plain struct so the generator can call attribute
      # methods without ActiveRecord.
      SampleAgreement = Struct.new(
        :id, :caf_type, :agreement_type_label, :entity, :contracting_party,
        :counterparty_name, :counterparty_email, :mandate_description,
        :requestor_name, :requestor_email,
        :agreement_purpose, :agreement_value, :agreement_term,
        :payment_terms, :key_risks, :template,
        keyword_init: true
      ) unless defined?(SampleAgreement)

      sample_template = Struct.new(:name, keyword_init: true).new(name: 'Sample Agreement v1.0.docx')

      entities = IgSignatories::ENTITIES.keys
      entity   = entities.first || :ig_holdings

      caf_type_to_label = {
        'long_form'  => 'Master Services Agreement',
        'short_form' => 'Addendum / Amendment',
        'nda'        => 'Non-Disclosure Agreement'
      }

      types.each do |caf_type|
        puts "  Generating #{caf_type}..."

        agreement = SampleAgreement.new(
          id:                    9999,
          caf_type:              caf_type,
          agreement_type_label:  caf_type_to_label.fetch(caf_type, caf_type.humanize),
          entity:                entity.to_s,
          contracting_party:     'Acme Technologies (Pty) Ltd',
          counterparty_name:     'Alice Dlamini',
          counterparty_email:    'alice.dlamini@acme.co.za',
          mandate_description:   "Provision of managed IT infrastructure services across all IG data centres.\n" \
                                 "This agreement covers hardware support, software licensing, and 24/7 NOC monitoring.",
          agreement_purpose:     "To formalise the managed services engagement with Acme Technologies in support of " \
                                 "IG's digital transformation programme.",
          agreement_value:       'R 1 200 000 per annum (excl. VAT)',
          agreement_term:        '3 years from effective date, with two 1-year renewal options',
          payment_terms:         'Net 30 days from invoice date',
          key_risks:             "Limitation of liability capped at 12 months' fees — AMBER. " \
                                 "Auto-renewal clause with 90-day notice period — review before expiry. " \
                                 "Data processing addendum required under POPI Act.",
          requestor_name:        'Jane Pretorius',
          requestor_email:       'jane.pretorius@ignitiongroup.co.za',
          template:              sample_template
        )

        begin
          pdf_path = CafPdfGenerator.new(agreement).generate
          dest     = out_dir.join("sample_#{caf_type}.pdf")
          FileUtils.mv(pdf_path, dest)
          puts "    Saved: #{dest}"
        rescue StandardError => e
          puts "    FAILED (#{caf_type}): #{e.message}"
          puts "    Ensure LibreOffice is installed: apt-get install libreoffice-headless"
        end
      end

      puts "\nDone. Samples in #{out_dir}"
    end
  end
end
