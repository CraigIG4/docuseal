# frozen_string_literal: true
# IGSIGN — Ignition Group People Directory & Signatory Authority
# Roles sourced from official IG directory. Emails preserved as provided.
# Entity groupings derived from role titles and entity structure.
module IgSignatories

  # ── People Directory ──────────────────────────────────────────────────────────
  # Emails kept exactly as provided. Entity inferred from role title.
  PEOPLE = {
    # ── Ignition Group (executive/group-level) ───────────────────────────────
    sean_bergsma:       { name: 'Sean Bergsma',        email: 'sean.bergsma@ignitiongroup.co.za',        title: 'Chief Executive Officer',                 entity: :ig_group },
    donovan_bergsma:    { name: 'Donovan Bergsma',      email: 'don.bergsma@ignitiongroup.co.za',          title: 'Chief Operating Officer',                 entity: :ig_group },
    craig_lawrence:     { name: 'Craig G. Lawrence',    email: 'craig.lawrence@ignitiongroup.co.za',       title: 'Group Chief Legal Officer',               entity: :ig_group },
    laren_farquharson:  { name: 'Laren Farquharson',    email: 'laren.farquharson@ignitiongroup.co.za',    title: 'Chief Financial Officer',                 entity: :ig_group },
    callie_baney:       { name: 'Callie Baney',          email: 'callie.baney@ignitiongroup.co.za',         title: 'Head: Project Management & Procurement',  entity: :ig_group },
    nic_williamson:     { name: 'Nic Williamson',        email: 'nic.williamson@ignitiongroup.co.za',       title: 'Chief of Staff',                          entity: :ig_group },
    simon_bowes:        { name: 'Simon Bowes',           email: 'simon.bowes@ignitiongroup.co.za',          title: 'Chief Growth Officer',                    entity: :ig_group },
    ferdi_gribb:        { name: 'Ferdi Gribb',           email: 'ferdi.gribb@ignitiongroup.co.za',          title: 'Chief Information Security Officer',      entity: :ig_group },
    richelle_swart:     { name: 'Richelle Swart',        email: 'richelle.swart@ignitiongroup.co.za',       title: 'Director: Strategic Projects',            entity: :ig_group },
    abel_rajoo:         { name: 'Abel Rajoo',            email: 'abel.rajoo@ignitiongroup.co.za',           title: 'Group Head of Data Analytics & AI Strategy', entity: :ig_group },
    adam_stockden:      { name: 'Adam Stockden',         email: 'adam.stockden@ignitiongroup.co.za',        title: 'Head of Group Engineering',               entity: :ig_group },
    adil_bux:           { name: 'Adil Bux',              email: 'adil.bux@ignitiongroup.co.za',             title: 'Head of Operations',                      entity: :ig_group },
    caleb_charles:      { name: 'Caleb Charles',          email: 'caleb.charles@ignitiongroup.co.za',        title: 'Group Head of Environments',              entity: :ig_group },
    guy_groom:          { name: 'Guy Groom',              email: 'guy.groom@ignitiongroup.co.za',            title: 'Head of IT',                              entity: :ig_group },
    sam_groom:          { name: 'Sam Groom',              email: 'sam.groom@ignitiongroup.co.za',            title: 'Head: Group Marketing',                   entity: :ig_group },
    nashlyn_ramparsad:  { name: 'Nashlyn Ramparsad',     email: 'nashlyn.ramparsad@ignitiongroup.co.za',    title: 'Head of Shared Services',                 entity: :ig_group },
    peta_ann_rens:      { name: 'Peta-Ann Rens',         email: 'peta-ann.rens@ignitiongroup.co.za',        title: 'Head of Employee Experience',             entity: :ig_group },
    louren_zeidler:     { name: 'Louren Zeidler',        email: 'louren.zeidler@ignitiongroup.co.za',       title: 'Personal Assistant',                      entity: :ig_group },
    daniel_schauffer:   { name: 'Daniel Schauffer',      email: 'daniel.schauffer@ignitiongroup.co.za',     title: 'Senior Finance Manager',                  entity: :ig_group },
    yonela_mbotho:      { name: 'Yonela Mbotho',         email: 'yonela.mbotho@ignitiongroup.co.za',        title: 'Head of HR: Group and Product',           entity: :ig_group },
    vicky_koekemoer:    { name: 'Vicky Koekemoer',       email: 'vicky.koekemoer@ignitiongroup.co.za',      title: 'Chief Human Resource Officer',            entity: :ig_group },
    tim_lombard:        { name: 'Tim Lombard',           email: 'tim.lombard@ignitiongroup.co.za',          title: 'Chief Marketing Officer',                 entity: :ig_group },
    stuart_pitt:        { name: 'Stuart Pitt',           email: 'stuart.pitt@ignitiongroup.co.za',          title: 'Head of Operations',                      entity: :ig_group },
    wesley_thaver:      { name: 'Wesley Thaver',         email: 'wesley.thaver@ignitiongroup.co.za',        title: 'Head of Learning and Development',         entity: :ig_group },
    llewellyn_vanwyk:   { name: 'Llewellyn VanWyk',      email: 'llewellyn.vanwyk@ignitiongroup.co.za',     title: 'Head of Data and Systems Operations',     entity: :ig_group },
    damian_moodley:     { name: 'Damian Moodley',        email: 'damian.moodley@ignitiongroup.co.za',       title: 'Head of Operations',                      entity: :ig_group },
    saleesha_govender:  { name: 'Saleesha Govender',     email: 'saleesha.govender@ignitiongroup.co.za',    title: 'Head of Client Management',               entity: :ig_group },
    sean_martin:        { name: 'Sean Martin',            email: 'sean.martin@ignitiongroup.co.za',          title: 'Business Unit Manager',                   entity: :ig_group },
    jantez_quarsingh:   { name: 'Jantez Quarsingh',      email: 'jantez.quarsingh@ignitiongroup.co.za',     title: 'Chief Sales Officer',                     entity: :ig_group },
    junaid_mahomed:     { name: 'Junaid Mahomed',        email: 'junaid.mahomed@ignitiongroup.co.za',       title: 'Head of Operations',                      entity: :ig_group },
    william_talbot:     { name: 'William Talbot',        email: 'william.talbot@ignitiongroup.co.za',       title: 'Chief Product Officer: NRP and Platforms', entity: :iti },
    craig_daroche:      { name: 'Craig DaRocha',         email: 'craig.darocha@ignitiongroup.co.za',        title: 'Head of Client Management',               entity: :ig_group },

    # ── IgnitionCX (Comit Technologies) ──────────────────────────────────────
    richard_swart:      { name: 'Richard Swart',         email: 'richard.swart@ignitioncx.co.za',           title: 'Executive Head: Telco',                   entity: :comit },
    verona_naidoo:      { name: 'Verona Naidoo',         email: 'verona.naidoo@ignitioncx.co.za',           title: 'Chief Financial Officer: Ignition CX',    entity: :comit },
    daryl_firmani:      { name: 'Daryl Firmani',         email: 'daryl.firmani@ignitioncx.co.za',           title: 'IT Director: Ignition CX',                entity: :comit },
    kerushan_naidu:     { name: 'Kerushan Naidu',        email: 'kerushan.naidu@ignitioncx.co.za',          title: 'Director: Call Centre Operations',        entity: :comit },

    # ── MVNX ─────────────────────────────────────────────────────────────────
    daniel_swart:       { name: 'Daniel Swart',          email: 'daniel.swart@mvnx.co.za',                 title: 'Executive Head: Wholesale & Business Dev', entity: :mvnx },
    jaco_myburgh:       { name: 'Jaco Myburgh',          email: 'jaco.myburgh@mvnx.co.za',                 title: 'Chief Information Officer',               entity: :mvnx },
    valde_ferradaz:     { name: 'Valde Ferradaz',        email: 'valde.ferradaz@mvnx.co.za',               title: 'Chief Executive Officer: Telecoms',        entity: :mvnx },
    matthew_van_as:     { name: 'Matthew Van As',        email: 'matthew.vanas@mvnx.co.za',                title: 'Finance Director',                        entity: :mvnx },

    # ── Gumtree ───────────────────────────────────────────────────────────────
    pedro_casimiro:     { name: 'Pedro Casimiro',        email: 'pedro.casimiro@gumtree.co.za',            title: 'Business Lead: Gumtree',                  entity: :gumtree },
    betine_dreyer:      { name: 'Betine Dreyer',         email: 'betine.dreyer@gumtree.co.za',             title: 'Head of Product - Gumtree South Africa',  entity: :gumtree },
    damian_naidoo:      { name: 'Damian Naidoo',         email: 'damian.naidoo@gumtree.co.za',             title: 'Head of Technology Gumtree SA',           entity: :gumtree },
    erik_vanzyl:        { name: 'Erik VanZyl',           email: 'erik.vanzyl@gumtree.co.za',               title: 'Finance Director',                        entity: :gumtree },

    # ── Spot ──────────────────────────────────────────────────────────────────
    stephen_welgemoed:  { name: 'Stephen Welgemoed',     email: 'stephen.welgemoed@spot.co.za',            title: 'Head of Technology: Spot Banking',         entity: :spot },
    allan_randell:      { name: 'Allan Randell',         email: 'allan.randell@spot.co.za',                title: 'Head of Product: Spot Banking & Spot Super App', entity: :spot },
    nikola_ramsden:     { name: 'Nikola Ramsden',        email: 'nikola.ramsden@spot.co.za',               title: 'Interim Finance Manager',                 entity: :spot },
    andrew_hutchinson:  { name: 'Andrew Hutchinson',     email: 'andrew.hutchinson@spot.co.za',            title: 'Operations Manager',                      entity: :spot },

    # ── UConnect Mobile ───────────────────────────────────────────────────────
    ivor_vonnielen:     { name: 'Ivor vonNielen',        email: 'ivor.vonnielen@uconnect.co.za',           title: 'Chief Operating Officer',                 entity: :uconnect },
    sideek_rahim:       { name: 'Siddeek Rahim',         email: 'sideek.rahim@uconnect.co.za',             title: 'Chief Executive Officer',                 entity: :uconnect },

    # ── IFS (Viva Cover / Viva Life) ──────────────────────────────────────────
    kobus_botha:        { name: 'Kobus Botha',           email: 'kobus.botha@ifs.co.za',                   title: 'Chief Executive Officer',                 entity: :ifs },
    angeline_bennett:   { name: 'Angeline Bennett',      email: 'angeline.bennett@ifs.co.za',              title: 'Finance Director',                        entity: :ifs },

    # ── Ignition Digital LLC ──────────────────────────────────────────────────
    mark_mitchell:      { name: 'Mark Mitchell',         email: 'mark.mitchell@ignitiondigital.com',       title: 'Chief Client Officer',                    entity: :ignition_digital },
    john_hawthorne:     { name: 'John Hawthorne',        email: 'john.hawthorne@ignitiondigital.com',      title: 'Senior Vice President',                   entity: :ignition_digital },
    greg_goosen:        { name: 'Greg Goosen',           email: 'greg.goosen@ignitiondigital.com',         title: 'EVP Business Development',                entity: :ignition_digital },
  }.freeze

  # Convenience: COO alias (Donovan = Don)
  PEOPLE_ALIASES = { don_bergsma: :donovan_bergsma }.freeze

  # ── Entity definitions ────────────────────────────────────────────────────────
  ENTITIES = {
    iti: {
      name: 'Ignition Telecoms Investments',
      bu_heads: %i[william_talbot craig_daroche richard_swart],
      bu_finance: :laren_farquharson,
      final_signatory_operational: :donovan_bergsma,
      final_signatory_other: :sean_bergsma,
    },
    comit: {
      name: 'IgnitionCX (Comit Technologies)',
      bu_heads: %i[richard_swart kerushan_naidu daryl_firmani],
      bu_finance: :verona_naidoo,
      final_signatory: :sean_bergsma,
    },
    mvnx: {
      name: 'MVNX',
      bu_heads: %i[daniel_swart jaco_myburgh valde_ferradaz],
      bu_finance: :matthew_van_as,
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
      bu_heads: %i[kobus_botha],
      bu_finance: :angeline_bennett,
      additional_required: %i[kobus_botha],
      final_signatory: :sean_bergsma,
    },
    gumtree: {
      name: 'Gumtree',
      bu_heads: %i[pedro_casimiro betine_dreyer damian_naidoo],
      bu_finance: :erik_vanzyl,
      final_signatory: :donovan_bergsma,
    },
    spot: {
      name: 'Spot',
      bu_heads: %i[allan_randell andrew_hutchinson],
      bu_finance: :nikola_ramsden,
      final_signatory: :sean_bergsma,
    },
    ig_group: {
      name: 'Ignition Group (General)',
      bu_heads: %i[nic_williamson simon_bowes],
      bu_finance: :laren_farquharson,
      final_signatory: :sean_bergsma,
    },
  }.freeze

  ENTITY_NAMES = ENTITIES.transform_values { |v| v[:name] }.freeze

  # ── Signing chain builders ────────────────────────────────────────────────────

  # NDA: BU Head / Requestor → Craig Lawrence (CLO signs ALL NDAs)
  def self.chain_for_nda(_entity_key)
    [{ key: :bu_head, placeholder: true, name: nil, email: nil, role: 'BU Head / Requestor' },
     person_entry(:craig_lawrence, 'Group Chief Legal Officer')]
  end

  # Short Form: BU Head → Final signatory for entity
  def self.chain_for_short_form(entity_key)
    entity = ENTITIES[entity_key.to_sym] || ENTITIES[:ig_group]
    final  = entity[:final_signatory] || entity[:final_signatory_other]
    [{ key: :bu_head, placeholder: true, name: nil, email: nil, role: 'BU Head / Department Head' },
     person_entry(final, PEOPLE[final][:title])]
  end

  # Long Form: BU Head → Procurement → BU Finance → Legal → CFO → COO → CEO
  # Don signs Gumtree + ITI operational; Sean signs all others
  def self.chain_for_long_form(entity_key)
    entity  = ENTITIES[entity_key.to_sym] || ENTITIES[:ig_group]
    final   = entity[:final_signatory] || entity[:final_signatory_other]
    finance = entity[:bu_finance] || :laren_farquharson
    chain   = []
    chain << { key: :bu_head, placeholder: true, name: nil, email: nil, role: 'BU Head / Requestor' }
    chain << person_entry(:callie_baney, 'Head: Project Management & Procurement')
    chain << person_entry(finance, 'BU Finance') unless finance == :callie_baney
    chain << person_entry(:craig_lawrence, 'Group Chief Legal Officer')
    chain << person_entry(:laren_farquharson, 'Chief Financial Officer') unless finance == :laren_farquharson
    chain << person_entry(:donovan_bergsma, 'Chief Operating Officer') unless final == :donovan_bergsma
    chain << person_entry(final, PEOPLE[final][:title])
    chain.uniq { |s| s[:email] }.compact
  end

  def self.chain_for(caf_type, entity_key)
    case caf_type.to_s
    when 'nda'        then chain_for_nda(entity_key)
    when 'short_form' then chain_for_short_form(entity_key)
    when 'long_form'  then chain_for_long_form(entity_key)
    else []
    end
  end

  # All people sorted alphabetically for dropdowns
  def self.all_people
    PEOPLE.map { |key, p| p.merge(key: key) }.sort_by { |p| p[:name] }
  end

  # People grouped by entity for UI rendering
  def self.people_by_entity
    PEOPLE.group_by { |_k, p| p[:entity] }
          .transform_values { |arr| arr.map { |key, p| p.merge(key: key) }.sort_by { |p| p[:name] } }
  end

  def self.entity_name(entity_key)
    ENTITIES.dig(entity_key.to_sym, :name) || entity_key.to_s.humanize
  end

  def self.bu_heads_for(entity_key)
    keys = ENTITIES.dig(entity_key.to_sym, :bu_heads) || []
    keys.map { |k| PEOPLE[k]&.merge(key: k) }.compact
  end

  private_class_method def self.person_entry(key, role_override = nil)
    p = PEOPLE[key]&.dup
    return nil unless p
    p[:key]         = key
    p[:placeholder] = false
    p[:role]        = role_override || p[:title]
    p
  end
end
