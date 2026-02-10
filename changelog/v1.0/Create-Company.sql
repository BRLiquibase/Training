--liquibase formatted sql

--changeset benriley:4CreateCompanyTable
CREATE TABLE company (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT
);

--rollback DROP TABLE company;

--changeset benriley:5InsertSampleCompanyData
INSERT INTO company (name, address) VALUES ('Acme Corporation', '123 Main St, Anytown, USA');
INSERT INTO company (name, address) VALUES ('Globex Inc.', '456 Elm St, Othertown, USA');
--rollback DELETE FROM company WHERE name IN ('Acme Corporation', 'Globex Inc.');

--changeset benriley:5CreateHumanTable
CREATE TABLE Human (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT
);

--rollback DROP TABLE human;
