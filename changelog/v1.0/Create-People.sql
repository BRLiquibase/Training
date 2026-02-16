--liquibase formatted sql

--changeset benriley:1CreatePeopleTable
CREATE TABLE people (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL
);

--rollback DROP TABLE people;

--changeset benriley:2InsertSampleData
INSERT INTO people (first_name, last_name) VALUES ('John', 'Doe');
INSERT INTO people (first_name, last_name) VALUES ('Jane', 'Smith');

--rollback DELETE FROM people WHERE first_name IN ('John', 'Jane') AND last_name IN ('Doe', 'Smith');

--changeset benriley:3AddEmailColumn
ALTER TABLE people ADD COLUMN email VARCHAR(100);

--rollback ALTER TABLE people DROP COLUMN email;

--changeset benriley:4CreatePersonTable
CREATE TABLE people (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL
);