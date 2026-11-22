INSERT INTO venues (name) VALUES ('The Lantern Room');

-- Insert section Floor with price €45
INSERT INTO sections (venue_id, name, price_cents) VALUES (
    (SELECT id FROM venues WHERE venues.name = 'The Lantern Room'),
    'Floor',
    4500
);

-- Insert section Balcony with price €30
INSERT INTO sections (venue_id, name, price_cents) VALUES (
    (SELECT id FROM venues WHERE venues.name = 'The Lantern Room'),
    'Balcony',
    3000
);

-- Insert section Box with price €80
INSERT INTO sections (venue_id, name, price_cents) VALUES (
    (SELECT id FROM venues WHERE venues.name = 'The Lantern Room'),
    'Box',
    8000
);

-- Insert seats for each section of the venue using recursive common table expressions
WITH RECURSIVE venue_rows(section_name, row_label, seats_per_row) AS (
    VALUES
        -- Floor section: rows A-E, 10 seats per row
        ('Floor', 'A', 10), ('Floor', 'B', 10), ('Floor', 'C', 10), ('Floor', 'D', 10), ('Floor', 'E', 10),

        -- Balcony section: rows F-H, 8 seats per row
        ('Balcony', 'F', 8), ('Balcony', 'G', 8), ('Balcony', 'H', 8),

        -- Box section: rows J-K, 4 seats per row
        ('Box', 'J', 4), ('Box', 'K', 4)
),
row_seats(section_name, row_label, seat_number, seats_per_row) AS (
    -- Base query
    SELECT section_name, row_label, 1, seats_per_row
    FROM venue_rows

    UNION ALL

    -- Recursive query
    SELECT section_name, row_label, seat_number + 1, seats_per_row
    FROM row_seats
    WHERE seat_number < seats_per_row
)
INSERT INTO seats (section_id, row_label, seat_number)
SELECT sections.id, rs.row_label, rs.seat_number
FROM sections
JOIN row_seats rs ON sections.name = rs.section_name
ORDER BY sections.id, rs.row_label, rs.seat_number;

INSERT INTO events (name, starts_at, venue_id)
VALUES (
    'Spanish Flamenco Evening',
    '2026-12-15T20:00:00Z',
    (SELECT id FROM venues WHERE venues.name = 'The Lantern Room')
);

-- Insert 3 events on 3 different dates
INSERT INTO events (name, starts_at, venue_id)
VALUES (
    'Christmas Open Mic',
    '2026-12-22T20:00:00Z',
    (SELECT id FROM venues WHERE venues.name = 'The Lantern Room')
);

INSERT INTO events (name, starts_at, venue_id)
VALUES (
    'Christmas Jazz Concert',
    '2026-12-26T20:00:00Z',
    (SELECT id FROM venues WHERE venues.name = 'The Lantern Room')
);

-- Insert an event seat for each event using cross join
INSERT INTO event_seats(event_id, seat_id)
SELECT events.id, seats.id
FROM events
CROSS JOIN seats
ORDER BY events.id, seats.id;

-- Insert two promo codes LANTERN10 (10% off) and FRONTROW (25% off)
INSERT INTO promo_codes (code, percent_off) VALUES ('LANTERN10', 10);
INSERT INTO promo_codes (code, percent_off) VALUES ('FRONTROW', 25);
