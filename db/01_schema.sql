CREATE TABLE countries (
    id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE
);

CREATE TABLE tour_tags (
    id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE
);

CREATE TABLE hotels (
    id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_id integer NOT NULL REFERENCES countries (id) ON DELETE RESTRICT,
    name       text    NOT NULL,
    stars      integer NOT NULL CHECK (stars BETWEEN 1 AND 5),
    UNIQUE (country_id, name)
);

CREATE TABLE tours (
    id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hotel_id  integer NOT NULL REFERENCES hotels (id) ON DELETE RESTRICT,
    title     text    NOT NULL,
    starts_at timestamptz NOT NULL,
    ends_at   timestamptz NOT NULL,
    price     numeric(10,2) NOT NULL CHECK (price > 0),
    CHECK (ends_at > starts_at)
);

CREATE TABLE clients (
    id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email     text NOT NULL UNIQUE,
    full_name text NOT NULL
);

CREATE TABLE bookings (
    id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id  integer NOT NULL REFERENCES clients (id) ON DELETE CASCADE,
    tour_id    integer NOT NULL REFERENCES tours   (id) ON DELETE RESTRICT,
    seats      integer NOT NULL CHECK (seats > 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (client_id, tour_id, created_at)
);

CREATE TABLE tour_tag_links (
    tour_id integer NOT NULL REFERENCES tours     (id) ON DELETE CASCADE,
    tag_id  integer NOT NULL REFERENCES tour_tags (id) ON DELETE CASCADE,
    PRIMARY KEY (tour_id, tag_id)
);