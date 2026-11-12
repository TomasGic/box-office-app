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

  def insert_event(name)
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

  def insert_event_seat(event:, row_label:, seat_number:, status: 'available')
    query = "INSERT INTO event_seats (event_id, seat_id, status) VALUES (
                  (SELECT id FROM events WHERE name = '#{event}'),
                  (SELECT id FROM seats WHERE row_label = '#{row_label}' AND seat_number = #{seat_number}),
                  '#{status}'
              )"
    described_class.connection.execute(query)
  end

  def insert_order(buyer_email:, price:, transaction_id:)
    query = "INSERT INTO orders (buyer_email, total_cents, gateway, transaction_id)
            VALUES ('#{buyer_email}', #{price}, 'paypal', '#{transaction_id}');"

    described_class.connection.execute(query)
  end
  # Venues
  it 'rejects a venue name that is NULL' do
    expect do
      described_class.connection.execute('INSERT INTO venues (name) VALUES (NULL);')
    end.to raise_error(SQLite3::ConstraintException)
  end

  # Sections
  it 'rejects a price that is negative' do
    insert_venue('Melkweg')

    expect do
      described_class.connection.execute(
        'INSERT INTO sections (venue_id, name, price_cents) VALUES (1, "Balcony", -10);'
      )
    end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
  end

  # Seats
  it 'rejects two identical combinations of seat_number and row_label within one section' do
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
  it 'rejects an event with non-existent venue_id' do
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

    # Event seats
    it 'rejects identical seat ids for the same event' do
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

    it 'enforces that event_seat with held status have a hold_token and held_until not null' do
      # query inserting a new held seat for a particular event into event_seats
      query = "INSERT INTO event_seats (event_id, seat_id, status) VALUES (
                  (SELECT id FROM events WHERE name = 'Gojira World Tour 2027'),
                  (SELECT id FROM seats WHERE row_label = 'A' AND seat_number = 25),
                  'held'
              )"

      # Inserting a seat with 'held' status and no hold_token and no held_until will raise error
      expect do
        described_class.connection.execute(query)
      end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
    end

    it 'enforces that event seat with available status and a hold_token is rejected' do
      # query inserting a new available seat with a hold_token
      query = "INSERT INTO event_seats (event_id, seat_id, status, hold_token) VALUES (
                  (SELECT id FROM events WHERE name = 'Gojira World Tour 2027'),
                  (SELECT id FROM seats WHERE row_label = 'A' AND seat_number = 25),
                  'available',
                  'xxxxxxxxxxxxxxxxxxxxxxxxx'
              )"
      expect do
        described_class.connection.execute(query)
      end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
    end

    it 'rejects an event seat with an invalid status' do
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

  # Promo codes
  it 'rejects the same code inserted twice' do
    query = "INSERT INTO promo_codes(code, percent_off) VALUES ('123456abcdef', 50);"

    described_class.connection.execute(query)

    expect do
      described_class.connection.execute(query)
    end.to raise_error(SQLite3::ConstraintException, /UNIQUE constraint failed/)
  end

  it 'rejects percent_off value of 0' do
    query = "INSERT INTO promo_codes(code, percent_off) VALUES ('123456abcdef', 0);"

    expect do
      described_class.connection.execute(query)
    end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
  end

  it 'rejects percent_off value of 101' do
    query = "INSERT INTO promo_codes(code, percent_off) VALUES ('123456abcdef', 101);"

    expect do
      described_class.connection.execute(query)
    end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
  end

  it 'accepts percent_off value of 100' do
    query = "INSERT INTO promo_codes(code, percent_off) VALUES ('123456abcdef', 100);"

    expect do
      described_class.connection.execute(query)
    end.not_to raise_error
  end

  # orders
  it 'rejects an order with negative total_cents' do
    query = "INSERT INTO orders (buyer_email, total_cents, gateway, transaction_id)
            VALUES ('tomas.gic@example.com', -4500, 'paypal', '123456abdefg');"

    expect do
      described_class.connection.execute(query)
    end.to raise_error(SQLite3::ConstraintException, /CHECK constraint failed/)
  end

  it 'accepts an order with total_cents of 0' do
    query = "INSERT INTO orders (buyer_email, total_cents, gateway, transaction_id)
            VALUES ('tomas.gic@example.com', 0, 'paypal', '123456abdefg');"

    expect do
      described_class.connection.execute(query)
    end.not_to raise_error
  end

  # Order items
  it 'rejects the same event_seat_id for two different orders' do
    insert_venue('Melkweg')
    insert_section('Balcony')
    insert_event('Gojira World Tour 2027')
    insert_seat(section: 'Balcony', row_label: 'A', number: 25)
    insert_event_seat(event: 'Gojira World Tour 2027', row_label: 'A', seat_number: 25)
    insert_order(buyer_email: 'tomas.gic@example.com', price: 4500, transaction_id: '1234abcd')
    insert_order(buyer_email: 'lukas.rohac@example.com', price: 4500, transaction_id: '9876xyzt')

    query1 = "INSERT INTO order_items (order_id, event_seat_id, price_cents)
              VALUES (
              (SELECT id FROM orders WHERE buyer_email = 'tomas.gic@example.com'),
              (SELECT id FROM event_seats where event_id = (SELECT id FROM events WHERE name = 'Gojira World Tour 2027')),
              4500
              );"
    query2 = "INSERT INTO order_items (order_id, event_seat_id, price_cents)
              VALUES (
              (SELECT id FROM orders WHERE buyer_email = 'lukas.rohac@example.com'),
              (SELECT id FROM event_seats where event_id = (SELECT id FROM events WHERE name = 'Gojira World Tour 2027')),
              4500
              );"

    described_class.connection.execute(query1)

    expect do
      described_class.connection.execute(query2)
    end.to raise_error(SQLite3::ConstraintException, /UNIQUE constraint failed/)
  end
end
