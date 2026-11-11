# frozen_string_literal: true

RSpec.describe TestDatabase do
  def insert_venue(name)
    described_class.connection.execute("INSERT INTO venues (name) VALUES ('#{name}');")
  end

  def insert_section(name)
    described_class.connection.execute(
      "INSERT INTO sections (venue_id, name, price_cents) VALUES (
        (SELECT id FROM venues WHERE name = 'Melkweg'), '#{name}', 4500
      );"
    )
  end

  def insert_event(name = 'Gojira World Tour 2027')
    described_class.connection.execute(
      "INSERT INTO events (name, starts_at, venue_id) VALUES (
        '#{name}',
        '2027-06-01 20:00:00',
        (SELECT id FROM venues WHERE name = 'Melkweg')
      )"
    )
  end

  def insert_seat(section:, row_label:, number:)
    described_class.connection.execute(
      "INSERT INTO seats (section_id, row_label, seat_number) VALUES (
              (SELECT id FROM sections WHERE name = '#{section}'),
              '#{row_label}',
              #{number}
            );"
    )
  end
  # Venues
  it 'enforces that venue name cannot be NULL' do
    expect do
      described_class.connection.execute('INSERT INTO venues (name) VALUES (NULL);')
    end.to raise_error(SQLite3::ConstraintException)
  end

  # Sections
  it 'enforces that price_cents in sections cannot be less then 0' do
    insert_venue('Melkweg')

    expect do
      described_class.connection.execute(
        'INSERT INTO sections (venue_id, name, price_cents) VALUES (1, "Balcony", -10);'
      )
    end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
  end

  # Seats
  it 'enforces unique combination of seat_number and row_label within one section' do
    insert_venue('Melkweg')
    insert_section('Balcony')

    query = "INSERT INTO seats (section_id, row_label, seat_number) VALUES (
              (SELECT id FROM sections WHERE name = 'Balcony'), 'A', 25
            );"
    described_class.connection.execute(query)

    expect do
      described_class.connection.execute(query)
    end.to raise_error(SQLite3::ConstraintException, /UNIQUE constraint failed/)
  end

  #  Events
  it 'enforces the foreign key constraint on venue_id in events' do
    query = "INSERT INTO events (name, starts_at, venue_id) VALUES (
              'Gojira World Tour 2027',
              '2027-06-01 20:00:00',
              999
            );"
    expect do
      described_class.connection.execute(query)
    end.to raise_error(SQLite3::ConstraintException, /FOREIGN KEY constraint failed/)
  end

  context 'examples that require venues, sections, events and seats to contain some data' do
    before do
      insert_venue('Melkweg')
      insert_section('Balcony')
      insert_event('Gojira World Tour 2027')
      insert_seat(section: 'Balcony', row_label: 'A', number: 25)
    end

    it 'enforces that the combination of event_id and seat_id is unique' do
      # query inserting a new available seat for a particular event into event_seats
      query = "INSERT INTO event_seats (event_id, seat_id, status) VALUES (
                  (SELECT id FROM events WHERE name = 'Gojira World Tour 2027'),
                  (SELECT id FROM seats WHERE row_label = 'A' AND seat_number = 25),
                  'available'
              )"

      # execute the query
      described_class.connection.execute(query)

      # we expect adding the same seat for the same event will raise error
      expect do
        described_class.connection.execute(query)
      end.to raise_error(SQLite3::ConstraintException, /UNIQUE constraint failed/)
    end

    # Event_seats
    it 'enforces that event_seat with held status have a hold_token and held_until not null' do
      # query inserting a new held seat for a particular event into event_seats
      query = "INSERT INTO event_seats (event_id, seat_id, status) VALUES (
                  (SELECT id FROM events WHERE name = 'Gojira World Tour 2027'),
                  (SELECT id FROM seats WHERE row_label = 'A' AND seat_number = 25),
                  'held'
              )"

      # Inserting a seat with 'held' status and no hold_token and held_until will raise error
      expect do
        described_class.connection.execute(query)
      end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
    end

    it "enforces that status can only be 'available', 'held' or 'sold'" do
      # query inserting a new seat with invalid status for a particular event into event_seats
      query = "INSERT INTO event_seats (event_id, seat_id, status) VALUES (
                  (SELECT id FROM events WHERE name = 'Gojira World Tour 2027'),
                  (SELECT id FROM seats WHERE row_label = 'A' AND seat_number = 25),
                  'invalid'
              )"
      expect do
        described_class.connection.execute(query)
      end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
    end
  end
end
