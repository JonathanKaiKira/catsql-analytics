CREATE SCHEMA catdb;

CREATE TABLE catdb.cats (
    cat_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cat_code text NOT NULL UNIQUE CHECK (btrim(cat_code) <> ''),
    name text NOT NULL CHECK (btrim(name) <> ''),
    birth_date date,
    coat text NOT NULL CHECK (btrim(coat) <> '')
);

CREATE TABLE catdb.caregivers (
    caregiver_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    alias text NOT NULL UNIQUE CHECK (btrim(alias) <> '')
);

CREATE TABLE catdb.cat_caregivers (
    cat_id bigint REFERENCES catdb.cats,
    caregiver_id bigint REFERENCES catdb.caregivers,
    role text NOT NULL CHECK (role IN ('owner', 'caregiver')),
    PRIMARY KEY (cat_id, caregiver_id)
);

CREATE TABLE catdb.foods (
    food_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE CHECK (btrim(name) <> ''),
    food_type text NOT NULL CHECK (food_type IN ('wet', 'dry'))
);

CREATE TABLE catdb.feedings (
    feeding_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cat_id bigint NOT NULL REFERENCES catdb.cats,
    food_id bigint NOT NULL REFERENCES catdb.foods,
    fed_at timestamptz NOT NULL,
    grams integer NOT NULL CHECK (grams > 0)
);

CREATE TABLE catdb.weights (
    weight_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cat_id bigint NOT NULL REFERENCES catdb.cats,
    measured_on date NOT NULL,
    grams integer NOT NULL CHECK (grams > 0),
    UNIQUE (cat_id, measured_on)
);

CREATE TABLE catdb.vet_visits (
    visit_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cat_id bigint NOT NULL REFERENCES catdb.cats,
    visited_on date NOT NULL,
    reason text NOT NULL CHECK (btrim(reason) <> ''),
    follow_up_on date,
    CHECK (follow_up_on > visited_on)
);

CREATE TABLE catdb.vaccines (
    vaccine_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE CHECK (btrim(name) <> '')
);

CREATE TABLE catdb.vaccinations (
    visit_id bigint REFERENCES catdb.vet_visits,
    vaccine_id bigint REFERENCES catdb.vaccines,
    PRIMARY KEY (visit_id, vaccine_id)
);

CREATE TABLE catdb.medications (
    medication_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE CHECK (btrim(name) <> '')
);

CREATE TABLE catdb.treatments (
    treatment_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    visit_id bigint NOT NULL REFERENCES catdb.vet_visits,
    medication_id bigint NOT NULL REFERENCES catdb.medications,
    started_on date NOT NULL,
    ended_on date,
    CHECK (ended_on >= started_on)
);

CREATE TABLE catdb.expenses (
    expense_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cat_id bigint NOT NULL REFERENCES catdb.cats,
    incurred_on date NOT NULL,
    category text NOT NULL CHECK (category IN ('food', 'vet', 'supplies')),
    amount_clp integer NOT NULL CHECK (amount_clp > 0)
);

CREATE TABLE catdb.activities (
    activity_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cat_id bigint NOT NULL REFERENCES catdb.cats,
    occurred_at timestamptz NOT NULL,
    activity_type text NOT NULL CHECK (activity_type IN ('play', 'rest', 'observation')),
    note text NOT NULL CHECK (btrim(note) <> '')
);

CREATE INDEX cat_caregivers_caregiver_idx ON catdb.cat_caregivers (caregiver_id);
CREATE INDEX feedings_cat_time_idx ON catdb.feedings (cat_id, fed_at);
CREATE INDEX feedings_food_idx ON catdb.feedings (food_id);
CREATE INDEX vet_visits_cat_date_idx ON catdb.vet_visits (cat_id, visited_on DESC, visit_id DESC);
CREATE INDEX vet_visits_follow_up_idx ON catdb.vet_visits (follow_up_on)
    WHERE follow_up_on IS NOT NULL;
CREATE INDEX vaccinations_vaccine_idx ON catdb.vaccinations (vaccine_id);
CREATE INDEX treatments_visit_idx ON catdb.treatments (visit_id);
CREATE INDEX treatments_medication_idx ON catdb.treatments (medication_id);
CREATE INDEX expenses_cat_date_idx ON catdb.expenses (cat_id, incurred_on);
CREATE INDEX activities_cat_time_idx ON catdb.activities (cat_id, occurred_at);
