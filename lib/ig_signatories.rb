# frozen_string_literal: true

# IGSIGN -- IG entity registry and signatory chains
# Registration numbers confirmed by Craig Daroche 2026-05-06
# Verify against CIPC extracts before live signature use

module IgSignatories
  REGISTERED_ADDRESS = "Quadrant 4, Centenary Building, 30 Meridian Drive\nUmhlanga, KwaZulu-Natal, South Africa"

  PEOPLE = {
    sean_bergsma: { name: 'Sean Bergsma', title: 'Group CEO', email: 'sean.bergsma@ignitiongroup.co.za' },
    donovan_bergsma: { name: 'Donovan Bergsma', title: 'Group COO', email: 'donovan.bergsma@ignitiongroup.co.za' },
    william_talbot: { name: 'William Talbot', title: 'BU Head - Technology', email: 'william.talbot@ignitiongroup.co.za' },
    craig_daroche: { name: 'Craig Daroche', title: 'BU Head - Commercial', email: 'craig.daroche@ignitiongroup.co.za' },
    richard_swart: { name: 'Richard Swart', title: 'BU Head - Operations', email: 'richard.swart@ignitiongroup.co.za' },
    laren_farquharson: { name: 'Laren Farquharson', title: 'Group Finance Director', email: 'laren.farquharson@ignitiongroup.co.za' },
    gavin_lucas: { name: 'Gavin Lucas', title: 'BU Head - Digital', email: 'gavin.lucas@ignitiongroup.co.za' },
    megan_venter: { name: 'Megan Venter', title: 'BU Head - Financial Services', email: 'megan.venter@ignitiongroup.co.za' },
    brett_impson: { name: 'Brett Impson', title: 'BU Head - Marketplace', email: 'brett.impson@ignitiongroup.co.za' },
    ashley_fourie: { name: 'Ashley Fourie', title: 'BU Head - Connectivity', email: 'ashley.fourie@ignitiongroup.co.za' },
    grant_harris: { name: 'Grant Harris', title: 'BU Head - Spot', email: 'grant.harris@ignitiongroup.co.za' }
  }.freeze

  ENTITIES = {
    iti: {
      name: 'Ignition Telecoms Investments (Pty) Ltd',
      short_name: 'ITI',
      registration: '2010/016551/07',
      address: "Quadrant 4, Centenary Building, 30 Meridian Drive\nUmhlanga, KwaZulu-Natal, South Africa\nPO Box 1611, Country Club, 4301",
      bu_heads: %i[william_talbot craig_daroche richard_swart],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma
    },
    comit: {
      name: 'Comit Technologies (Pty) Ltd',
      short_name: 'COMIT',
      registration: '2011/005082/07',
      address: REGISTERED_ADDRESS,
      bu_heads: %i[william_talbot craig_daroche],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma
    },
    mvnx: {
      name: 'MVN-X (Pty) Ltd',
      short_name: 'MVN-X',
      registration: '2012/032479/07',
      address: "Quadrant 4, Centenary Building, 30 Meridian Drive\nUmhlanga, 4319\nKwaZulu-Natal, South Africa",
      bu_heads: %i[ashley_fourie],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma
    },
    uconnect: {
      name: 'UConnect Mobile (Pty) Ltd',
      short_name: 'UConnect',
      registration: '2021/784475/07',
      address: REGISTERED_ADDRESS,
      bu_heads: %i[ashley_fourie],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma
    },
    ccs: {
      name: 'CCS Outsourcing (Pty) Ltd',
      short_name: 'CCS Outsourcing',
      registration: '2011/001454/07',
      address: REGISTERED_ADDRESS,
      bu_heads: %i[craig_daroche richard_swart],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma
    },
    chase_tracking: {
      name: 'Chase Tracking (Pty) Ltd',
      short_name: 'Chase Tracking',
      registration: '2012/206286/07',
      address: REGISTERED_ADDRESS,
      bu_heads: %i[william_talbot],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma
    },
    ignite_training: {
      name: 'Ignite Training Academy (Pty) Ltd',
      short_name: 'Ignite Training',
      registration: '2012/160916/07',
      address: REGISTERED_ADDRESS,
      bu_heads: %i[craig_daroche],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma
    },
    me_and_you: {
      name: 'Me and You Mobile (Pty) Ltd',
      short_name: 'Me & You Mobile',
      registration: '2014/125548/07',
      address: REGISTERED_ADDRESS,
      bu_heads: %i[ashley_fourie],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma
    },
    mobius: {
      name: 'Mobius Mobile Telecommunications (Pty) Ltd',
      short_name: 'Mobius',
      registration: '2012/204893/07',
      address: REGISTERED_ADDRESS,
      bu_heads: %i[ashley_fourie],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma
    },
    ucingo: {
      name: 'Ucingo Administration 321 (Pty) Ltd',
      short_name: 'Ucingo',
      registration: '2009/010610/07',
      address: REGISTERED_ADDRESS,
      bu_heads: %i[craig_daroche],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma
    },
    all_sevens: {
      name: 'All Sevens Trade and Invest (Pty) Ltd',
      short_name: 'All Sevens',
      registration: '2019/040427/07',
      address: REGISTERED_ADDRESS,
      bu_heads: %i[craig_daroche],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma
    },
    benjistar: {
      name: 'Benjistar (Pty) Ltd',
      short_name: 'Benjistar',
      registration: '2015/412308/07',
      address: REGISTERED_ADDRESS,
      bu_heads: %i[craig_daroche],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma
    },
    so_music: {
      name: 'So Music Industries (Pty) Ltd',
      short_name: 'So Music',
      registration: '2012/045745/07',
      address: REGISTERED_ADDRESS,
      bu_heads: %i[craig_daroche],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma
    }
  }.freeze

  def self.chain_for(caf_type, entity_key)
    entity = ENTITIES[entity_key.to_sym]
    return { stage1: [], stage2: [] } unless entity

    case caf_type.to_s
    when 'nda'
      bu_signers = Array(entity[:bu_heads]).first(1)
      final = entity[:final_signatory_other]
    when 'short_form'
      bu_signers = Array(entity[:bu_heads]).first(1)
      final = entity[:final_signatory_operational]
    else
      bu_signers = Array(entity[:bu_heads])
      final = entity[:final_signatory_other]
    end

    chain = (bu_signers + [entity[:bu_finance], final]).compact.uniq.filter_map do |k|
      p = PEOPLE[k]
      next unless p

      { key: k, name: p[:name], title: p[:title], email: p[:email] }
    end

    { stage1: chain, stage2: [] }
  end

  def self.entity_details(entity_key)
    ENTITIES[entity_key.to_sym]
  end

  def self.person(person_key)
    PEOPLE[person_key.to_sym]
  end

  def self.entities_for_js
    ENTITIES.map do |key, e|
      {
        key: key.to_s,
        name: e[:name],
        short_name: e[:short_name],
        registration: e[:registration],
        address: e[:address]
      }
    end
  end
end
