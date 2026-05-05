# frozen_string_literal: true
# IGSIGN — Ignition Group Signatory Authority
# Based on: "Ignition Group Entity - signatory authority" document
module IgSignatories
  PEOPLE = {
    sean_bergsma:       { name: 'Sean Bergsma',       email: 'sean.bergsma@ignitiongroup.co.za',       title: 'Group Chief Executive Officer',  role: 'CEO' },
    don_bergsma:        { name: 'Don Bergsma',         email: 'don.bergsma@ignitiongroup.co.za',         title: 'Group Chief Operating Officer',  role: 'COO' },
    craig_lawrence:     { name: 'Craig G. Lawrence',   email: 'craig.lawrence@ignitiongroup.co.za',      title: 'Group Chief Legal Officer',      role: 'CLO' },
    laren_farquharson:  { name: 'Laren Farquharson',   email: 'laren.farquharson@ignitiongroup.co.za',   title: 'Group Chief Financial Officer',  role: 'CFO' },
    callie_baney:       { name: 'Callie Baney',         email: 'callie.baney@ignitiongroup.co.za',       title: 'Group Procurement',              role: 'Procurement' },
    yonela_mbotho:      { name: 'Yonela Mbotho',        email: 'yonela.mbotho@ignitiongroup.co.za',      title: 'Group Human Resources Officer',  role: 'HR' },
    vicky_koekemoer:    { name: 'Vicky Koekemoer',      email: 'vicky.koekemoer@ignitiongroup.co.za',    title: 'Group Human Resources Officer',  role: 'HR' },
    william_talbot:     { name: 'William Talbot',       email: 'william.talbot@ignitiongroup.co.za',     title: 'NRP Head',                       role: 'BU Head' },
    craig_daroche:      { name: 'Craig Da Roche',       email: 'craig.daroche@ignitiongroup.co.za',      title: 'OnAir Head',                     role: 'BU Head' },
    richard_swart:      { name: 'Richard Swart',        email: 'richard.swart@comit.co.za',              title: 'Comit Head',                     role: 'BU Head' },
    daniel_swart:       { name: 'Daniel Swart',         email: 'daniel.swart@mvnx.co.za',               title: 'MVNX Executive Head',            role: 'BU Head' },
    jaco_myburgh:       { name: 'Jaco Myburgh',         email: 'jaco.myburgh@mvnx.co.za',               title: 'Chief Information Officer',      role: 'CIO' },
    valde_ferradaz:     { name: 'Valde Ferradaz',       email: 'valde.ferradaz@mvnx.co.za',             title: 'MVNX CEO',                       role: 'BU CEO' },
    ivor_vonnielen:     { name: 'Ivor vonNielen',       email: 'ivor.vonnielen@uconnect.co.za',          title: 'UConnect COO',                   role: 'BU COO' },
    nikola_ramsden:     { name: 'Nikola Ramsden',       email: 'nikola.ramsden@ignitiongroup.co.za',     title: 'Head of Finance',                role: 'BU Finance' },
    sideek_rahim:       { name: 'Sideek Rahim',         email: 'sideek.rahim@uconnect.co.za',           title: 'UConnect CEO',                   role: 'BU CEO' },
    john_hawthorne:     { name: 'John Hawthorne',       email: 'john.hawthorne@ignitiondigital.com',     title: 'Senior Vice President',          role: 'BU Head' },
    greg_goosen:        { name: 'Greg Goosen',           email: 'greg.goosen@ignitiondigital.com',       title: 'EVP Business Development',       role: 'BU Head' },
    mark_mitchell:      { name: 'Mark Mitchell',         email: 'mark.mitchell@ignitiondigital.com',     title: 'Chief Client Officer',           role: 'BU Head' },
    verona_naidoo:      { name: 'Verona Naidoo',         email: 'verona.naidoo@comit.co.za',             title: 'Finance Director',               role: 'BU Finance' },
    angeline_bennett:   { name: 'Angeline Bennett',     email: 'angeline.bennett@ifs.co.za',             title: 'IFS Financial Director',         role: 'BU Finance' },
    kobus_botha:        { name: 'Kobus Botha',           email: 'kobus.botha@ifs.co.za',                 title: 'IFS Chief Executive Officer',    role: 'BU CEO' },
    erik_vanzyl:        { name: 'Erik VanZyl',           email: 'erik.vanzyl@gumtree.co.za',             title: 'Gumtree Financial Director',     role: 'BU Finance' },
    pedro_casimiro:     { name: 'Pedro Casimiro',        email: 'pedro.casimiro@gumtree.co.za',          title: 'Gumtree Business Lead',          role: 'BU Head' },
    andrew_hutchinson:  { name: 'Andrew Hutchinson',    email: 'andrew.hutchinson@spot.co.za',           title: 'Spot Operations Manager',        role: 'BU Head' },
    allan_randell:      { name: 'Allan Randell',         email: 'allan.randell@spot.co.za',              title: 'Head of Product, Spot',          role: 'BU Head' },
    caleb_charles:      { name: 'Caleb Charles',         email: 'caleb.charles@ignitiongroup.co.za',     title: 'Group Facilities',               role: 'Facilities' },
  }.freeze

  ENTITIES = {
    iti: {
      name: 'Ignition Telecoms Investments',
      bu_heads: %i[william_talbot craig_daroche richard_swart],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :don_bergsma,
      final_signatory_other: :sean_bergsma,
    },
    comit: {
      name: 'Comit Technologies',
      bu_heads: %i[richard_swart],
      bu_finance: :verona_naidoo,
      final_signatory: :sean_bergsma,
    },
    mvnx: {
      name: 'MVNX',
      bu_heads: %i[daniel_swart jaco_myburgh valde_ferradaz],
      bu_finance: :laren_farquharson,
      final_signatory: :sean_bergsma,
    },
    uconnect: {
      name: 'UConnect Mobile',
      bu_heads: %i[ivor_vonnielen sideek_rahim],
      bu_finance: :nikola_ramsden,
      final_signatory: :sean_bergsma,
    },
    ignition_digital: {
      name: 'Ignition Digital LLC',
      bu_heads: %i[john_hawthorne greg_goosen mark_mitchell],
      bu_finance: :verona_naidoo,
      final_signatory: :sean_bergsma,
    },
    ifs: {
      name: 'IFS (Viva Cover / Viva Life)',
      bu_heads: %i[kobus_botha angeline_bennett],
      bu_finance: :angeline_bennett,
      additional_required: %i[kobus_botha],
      final_signatory: :sean_bergsma,
    },
    gumtree: {
      name: 'Gumtree',
      bu_heads: %i[pedro_casimiro],
      bu_finance: :erik_vanzyl,
      final_signatory: :don_bergsma,
    },
    spot: {
      name: 'Spot',
      bu_heads: %i[andrew_hutchinson allan_randell],
      bu_finance: :nikola_ramsden,
      final_signatory: :sean_bergsma,
    },
    ig_group: {
      name: 'Ignition Group (General)',
      bu_heads: [],
      bu_finance: :laren_farquharson,
      final_signatory: :sean_bergsma,
    },
  }.freeze

  ENTITY_NAMES = ENTITIES.transform_values { |v| v[:name] }.freeze

  def self.chain_for_nda(_entity_key)
    [{ key: :bu_head, placeholder: true, name: nil, email: nil, role: 'BU Head / Requestor' },
     person_entry(:craig_lawrence, 'CLO — All NDAs')]
  end

  def self.chain_for_short_form(entity_key)
    entity = ENTITIES[entity_key.to_sym] || ENTITIES[:ig_group]
    final  = entity[:final_signatory] || entity[:final_signatory_other]
    [{ key: :bu_head, placeholder: true, name: nil, email: nil, role: 'BU Head / Department Head' },
     person_entry(final, PEOPLE[final][:role])]
  end

  def self.chain_for_long_form(entity_key)
    entity  = ENTITIES[entity_key.to_sym] || ENTITIES[:ig_group]
    final   = entity[:final_signatory] || entity[:final_signatory_other]
    finance = entity[:bu_finance] || :laren_farquharson
    chain   = []
    chain << { key: :bu_head, placeholder: true, name: nil, email: nil, role: 'BU Head / Requestor' }
    chain << person_entry(:callie_baney, 'Procurement')
    chain << person_entry(finance, 'BU Finance')
    chain << person_entry(:craig_lawrence, 'Legal (CLO)')
    chain << person_entry(:laren_farquharson, 'CFO') unless finance == :laren_farquharson
    chain << person_entry(:don_bergsma, 'COO') unless final == :don_bergsma
    chain << person_entry(final, PEOPLE[final][:role])
    chain.uniq { |s| s[:email] }
  end

  def self.chain_for(caf_type, entity_key)
    case caf_type.to_s
    when 'nda'        then chain_for_nda(entity_key)
    when 'short_form' then chain_for_short_form(entity_key)
    when 'long_form'  then chain_for_long_form(entity_key)
    else []
    end
  end

  def self.all_people
    PEOPLE.map { |key, p| p.merge(key: key) }.sort_by { |p| p[:name] }
  end

  def self.entity_name(entity_key)
    ENTITIES.dig(entity_key.to_sym, :name) || entity_key.to_s.humanize
  end

  private_class_method def self.person_entry(key, role_override = nil)
    p = PEOPLE[key].dup
    p[:key] = key
    p[:placeholder] = false
    p[:role] = role_override if role_override
    p
  end
end
