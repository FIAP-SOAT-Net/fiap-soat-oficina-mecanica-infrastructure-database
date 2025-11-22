-- V1__create_initial_schema.sql
-- Purpose: Create initial database schema for Smart Mechanical Workshop
-- Date: 2025-11-22

-- This migration creates the foundational tables for the Smart Mechanical Workshop

START TRANSACTION;

create table if not exists addresses (
    id char(36) charset ascii not null primary key,
    street varchar(100) not null,
    city varchar(60) not null,
    state varchar(30) not null,
    zip_code varchar(15) not null,
    created_at datetime(6) not null,
    updated_at datetime(6) not null,
    constraint IX_addresses_street_city_state_zip_code unique (street, city, state, zip_code)
);

create table if not exists available_services (
    id char(36) charset ascii not null primary key,
    name varchar(100) not null,
    price decimal(18, 2) not null,
    created_at datetime(6) not null,
    updated_at datetime(6) not null,
    constraint IX_available_services_name unique (name)
);

create table if not exists people (
    id char(36) charset ascii not null primary key,
    document varchar(100) not null,
    fullname varchar(255) not null,
    person_type varchar(100) not null,
    employee_role varchar(100) null,
    phone varchar(25) not null,
    email varchar(255) not null,
    address_id char(36) charset ascii not null,
    created_at datetime(6) not null,
    updated_at datetime(6) not null,
    password varchar(100) default '' not null,
    constraint IX_people_address_id unique (address_id),
    constraint IX_people_document unique (document),
    constraint IX_people_email unique (email),
    constraint FK_people_addresses_address_id foreign key (address_id) references addresses (id) on delete cascade
);

create table if not exists supplies (
    id char(36) charset ascii not null primary key,
    name varchar(100) not null,
    quantity int not null,
    price decimal(18, 2) not null,
    created_at datetime(6) not null,
    updated_at datetime(6) not null,
    constraint IX_supplies_name unique (name)
);

create table if not exists available_services_supply (
    available_service_id char(36) charset ascii not null,
    supply_id char(36) charset ascii not null,
    quantity int default 0 not null,
    primary key (
        available_service_id,
        supply_id
    ),
    constraint fk_available_service_supplies_available_service_id foreign key (available_service_id) references available_services (id) on delete cascade,
    constraint fk_available_service_supplies_supply_id foreign key (supply_id) references supplies (id) on delete cascade
);

create index IX_available_services_supply_supply_id on available_services_supply (supply_id);

create table if not exists vehicles (
    id char(36) charset ascii not null primary key,
    license_plate varchar(20) not null,
    manufacture_year int not null,
    brand varchar(50) not null,
    model varchar(100) not null,
    person_id char(36) charset ascii not null,
    created_at datetime(6) not null,
    updated_at datetime(6) not null,
    constraint IX_vehicles_license_plate unique (license_plate),
    constraint FK_vehicles_people_person_id foreign key (person_id) references people (id) on delete cascade
);

create table if not exists service_orders (
    id char(36) charset ascii not null primary key,
    status varchar(100) not null,
    client_id char(36) charset ascii not null,
    vehicle_id char(36) charset ascii not null,
    title varchar(250) not null,
    description varchar(500) not null,
    created_at datetime(6) not null,
    updated_at datetime(6) not null,
    constraint FK_service_orders_people_client_id foreign key (client_id) references people (id),
    constraint FK_service_orders_vehicles_vehicle_id foreign key (vehicle_id) references vehicles (id)
);

create table if not exists available_services_services_orders (
    available_service_id char(36) charset ascii not null,
    service_order_id char(36) charset ascii not null,
    primary key (
        available_service_id,
        service_order_id
    ),
    constraint fk_available_service_service_order foreign key (available_service_id) references available_services (id) on delete cascade,
    constraint fk_service_order_available_service foreign key (service_order_id) references service_orders (id) on delete cascade
);

create index IX_available_services_services_orders_service_order_id on available_services_services_orders (service_order_id);

create table if not exists quotes (
    id char(36) charset ascii not null primary key,
    service_order_id char(36) charset ascii not null,
    status varchar(100) not null,
    total decimal(18, 2) not null,
    created_at datetime(6) not null,
    updated_at datetime(6) not null,
    constraint FK_quotes_service_orders_service_order_id foreign key (service_order_id) references service_orders (id) on delete cascade
);

create table if not exists quote_services (
    id char(36) charset ascii not null primary key,
    quote_id char(36) charset ascii not null,
    service_id char(36) charset ascii not null,
    price decimal(18, 2) not null,
    constraint FK_quote_services_available_services_service_id foreign key (service_id) references available_services (id),
    constraint FK_quote_services_quotes_quote_id foreign key (quote_id) references quotes (id) on delete cascade
);

create index IX_quote_services_quote_id on quote_services (quote_id);

create index IX_quote_services_service_id on quote_services (service_id);

create table if not exists quote_supplies (
    id char(36) charset ascii not null primary key,
    quote_id char(36) charset ascii not null,
    supply_id char(36) charset ascii not null,
    price decimal(18, 2) not null,
    quantity int not null,
    constraint FK_quote_supplies_quotes_quote_id foreign key (quote_id) references quotes (id) on delete cascade,
    constraint FK_quote_supplies_supplies_supply_id foreign key (supply_id) references supplies (id)
);

create index IX_quote_supplies_quote_id on quote_supplies (quote_id);

create index IX_quote_supplies_supply_id on quote_supplies (supply_id);

create index IX_quotes_service_order_id on quotes (service_order_id);

create table if not exists service_order_events (
    id char(36) charset ascii not null primary key,
    status varchar(100) not null,
    service_order_id char(36) charset ascii not null,
    created_at datetime(6) not null,
    updated_at datetime(6) not null,
    constraint FK_service_order_events_service_orders_service_order_id foreign key (service_order_id) references service_orders (id) on delete cascade
);

COMMIT;
