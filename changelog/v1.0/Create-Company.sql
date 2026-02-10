--liquibase formatted sql

--changeset benriley:4CreateCompanyTable
CREATE TABLE company (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT
);

--rollback DROP TABLE company;