-- SQLite ignores foreign keys unless this is on, and the setting belongs to the connection, not to the file.
-- It applies to whoever runs this file; every other connection that writes has to turn it on again.
PRAGMA foreign_keys = ON;

CREATE TABLE venues (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE sections (
  id INTEGER PRIMARY KEY,
  venue_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  price_cents INTEGER NOT NULL CHECK (price_cents > 0),
  FOREIGN KEY (venue_id) REFERENCES venues(id)
);

-- This is the table containing physical seats of the venue
CREATE TABLE seats (
  id INTEGER PRIMARY KEY,
  section_id INTEGER NOT NULL,
  row_label VARCHAR(50) NOT NULL,
  seat_number INTEGER NOT NULL,
  FOREIGN KEY (section_id) REFERENCES sections(id),

  -- Combination of row_label and seat_number should be unique for each section
  UNIQUE (section_id, row_label, seat_number)
);

CREATE TABLE events (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  starts_at TEXT NOT NULL --this column expects format ISO 8061 in UTC: SQLite has no date type, ,
  venue_id INTEGER NOT NULL,
  FOREIGN KEY (venue_id) REFERENCES venues(id)
);


-- This is the table containing seats for a specific event.
-- An event seat is separate from the physical seat.
-- The table references the physical seat by a foreign key (seat_id)
CREATE TABLE event_seats (
  id INTEGER PRIMARY KEY,
  event_id INTEGER NOT NULL,
  seat_id INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'available',
  hold_token VARCHAR(100),
  held_until TEXT -- this column expects format ISO 8061 in UTC: SQLite has no date type,
  FOREIGN KEY (event_id) REFERENCES events(id),
  FOREIGN KEY (seat_id) REFERENCES seats(id),

  -- Unique constraint ensures that a physical seat (seat_id) can only be sold once for the same event.
  -- However, the same seat id can be sold for different events
  UNIQUE (event_id, seat_id),

  -- Check constraint to ensure status is only one of 'available', 'held', or 'sold'
  CONSTRAINT valid_status CHECK(status IN ('available', 'held', 'sold')),

  -- Check constraint to ensure event_seats with 'held' status have a hold_token and held_until.
  -- Event_seats with status other than 'held' have neither hold_token nor held_until.
  CONSTRAINT valid_held_tokens CHECK (
    (status = 'held' AND (hold_token NOT NULL AND held_until NOT NULL)) OR
    (status != 'held' AND (hold_token IS NULL AND held_until IS NULL))
  )
);

CREATE TABLE promo_codes (
  id INTEGER PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  percent_off INTEGER NOT NULL CHECK (percent_off >= 1 AND percent_off <= 100)
);

CREATE TABLE orders (
  id INTEGER PRIMARY KEY,
  buyer_email TEXT NOT NULL,
  total_cents INTEGER NOT NULL CHECK (total_cents >= 0),
  gateway VARCHAR(50) NOT NULL,
  transaction_id VARCHAR(100) NOT NULL
);

CREATE TABLE order_items (
  id INTEGER PRIMARY KEY,
  order_id INTEGER NOT NULL,
  event_seat_id INTEGER NOT NULL UNIQUE,
  price_cents INTEGER NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (event_seat_id) REFERENCES event_seats(id)
);

-- Create indexes on the foreign keys by which the app will query the most
CREATE INDEX idx_event_seats_event_id ON event_seats(event_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
