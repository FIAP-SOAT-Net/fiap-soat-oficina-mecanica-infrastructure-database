-- V3__seed_service_types.sql
-- Purpose: Populate tables with initial data for Smart Mechanical Workshop
-- Date: 2025-11-22

START TRANSACTION;

-- Preencher addresses
insert into addresses (id, street, city, state, zip_code, created_at, updated_at) values
(uuid(), 'Rua das Flores, 123', 'Porto Alegre', 'RS', '90000-000', now(), now()),
(uuid(), 'Avenida Brasil, 456', 'São Paulo', 'SP', '01000-000', now(), now()),
(uuid(), 'Rua XV de Novembro, 789', 'Curitiba', 'PR', '80000-000', now(), now()),
(uuid(), 'Rua Sete de Setembro, 321', 'Belo Horizonte', 'MG', '30000-000', now(), now()),
(uuid(), 'Rua das Palmeiras, 654', 'Florianópolis', 'SC', '88000-000', now(), now()),
(uuid(), 'Rua do Comércio, 987', 'Salvador', 'BA', '40000-000', now(), now()),
(uuid(), 'Rua dos Andradas, 159', 'Porto Alegre', 'RS', '90010-000', now(), now()),
(uuid(), 'Avenida Independência, 753', 'Recife', 'PE', '50000-000', now(), now()),
(uuid(), 'Rua Augusta, 852', 'São Paulo', 'SP', '01300-000', now(), now()),
(uuid(), 'Rua das Laranjeiras, 951', 'Rio de Janeiro', 'RJ', '22240-003', now(), now());

-- Preencher available_services
insert into available_services (id, name, price, created_at, updated_at) values
(uuid(), 'Troca de Óleo', 120.00, now(), now()),
(uuid(), 'Alinhamento e Balanceamento', 150.00, now(), now()),
(uuid(), 'Revisão Completa', 350.00, now(), now()),
(uuid(), 'Troca de Pastilha de Freio', 180.00, now(), now()),
(uuid(), 'Inspeção Veicular', 90.00, now(), now()),
(uuid(), 'Troca de Filtro de Ar', 60.00, now(), now()),
(uuid(), 'Troca de Pneu', 100.00, now(), now()),
(uuid(), 'Polimento', 200.00, now(), now()),
(uuid(), 'Troca de Correia Dentada', 400.00, now(), now()),
(uuid(), 'Higienização do Ar Condicionado', 130.00, now(), now());

-- Preencher supplies
insert into supplies (id, name, quantity, price, created_at, updated_at) values
(uuid(), 'Óleo 5W30', 50, 35.00, now(), now()),
(uuid(), 'Filtro de Óleo', 30, 25.00, now(), now()),
(uuid(), 'Pastilha de Freio', 40, 80.00, now(), now()),
(uuid(), 'Pneu Aro 15', 20, 250.00, now(), now()),
(uuid(), 'Filtro de Ar', 25, 40.00, now(), now()),
(uuid(), 'Correia Dentada', 15, 120.00, now(), now()),
(uuid(), 'Líquido de Arrefecimento', 35, 30.00, now(), now()),
(uuid(), 'Limpador de Para-brisa', 18, 20.00, now(), now()),
(uuid(), 'Desinfetante Automotivo', 22, 15.00, now(), now()),
(uuid(), 'Polidor de Pintura', 12, 60.00, now(), now());

-- Preencher people (8 clientes, 2 funcionários)
insert into people (id, person_type, document, fullname, phone, email, address_id, created_at, updated_at, password) values
(uuid(), 'Client', '12345678900', 'João da Silva', '51991080001', 'joao.silva@email.com', (select id from addresses limit 1 offset 0), now(), now(), 'METUNNJzqmaJiyiiMELveQ==.CjcklKdg4WGXYvTVILD8lK8EuHOco8a0GN20iZElexg='),
(uuid(), 'Client', '23456789011', 'Maria Oliveira', '51991080002', 'maria.oliveira@email.com', (select id from addresses limit 1 offset 1), now(), now(), 'METUNNJzqmaJiyiiMELveQ==.CjcklKdg4WGXYvTVILD8lK8EuHOco8a0GN20iZElexg='),
(uuid(), 'Client', '34567890122', 'Carlos Souza', '51991080003', 'carlos.souza@email.com', (select id from addresses limit 1 offset 2), now(), now(), 'METUNNJzqmaJiyiiMELveQ==.CjcklKdg4WGXYvTVILD8lK8EuHOco8a0GN20iZElexg='),
(uuid(), 'Client', '45678901233', 'Ana Paula', '51991080004', 'ana.paula@email.com', (select id from addresses limit 1 offset 3), now(), now(), 'METUNNJzqmaJiyiiMELveQ==.CjcklKdg4WGXYvTVILD8lK8EuHOco8a0GN20iZElexg='),
(uuid(), 'Client', '56789012344', 'Pedro Santos', '51991080005', 'pedro.santos@email.com', (select id from addresses limit 1 offset 4), now(), now(), 'METUNNJzqmaJiyiiMELveQ==.CjcklKdg4WGXYvTVILD8lK8EuHOco8a0GN20iZElexg='),
(uuid(), 'Client', '67890123455', 'Juliana Lima', '51991080006', 'juliana.lima@email.com', (select id from addresses limit 1 offset 5), now(), now(), 'METUNNJzqmaJiyiiMELveQ==.CjcklKdg4WGXYvTVILD8lK8EuHOco8a0GN20iZElexg='),
(uuid(), 'Client', '78901234566', 'Ricardo Alves', '51991080007', 'ricardo.alves@email.com', (select id from addresses limit 1 offset 6), now(), now(), 'METUNNJzqmaJiyiiMELveQ==.CjcklKdg4WGXYvTVILD8lK8EuHOco8a0GN20iZElexg='),
(uuid(), 'Client', '89012345677', 'Fernanda Costa', '51991080008', 'fernanda.costa@email.com', (select id from addresses limit 1 offset 7), now(), now(), 'METUNNJzqmaJiyiiMELveQ==.CjcklKdg4WGXYvTVILD8lK8EuHOco8a0GN20iZElexg='),
(uuid(), 'Employee', '90012345688', 'Lucas Mecânico', '51991080009', 'lucas.mecanico@email.com', (select id from addresses limit 1 offset 8), now(), now(), 'METUNNJzqmaJiyiiMELveQ==.CjcklKdg4WGXYvTVILD8lK8EuHOco8a0GN20iZElexg='),
(uuid(), 'Employee', '90123456799', 'Paulo Inspetor', '51991080010', 'paulo.inspetor@email.com', (select id from addresses limit 1 offset 9), now(), now(), 'METUNNJzqmaJiyiiMELveQ==.CjcklKdg4WGXYvTVILD8lK8EuHOco8a0GN20iZElexg=');

-- Preencher available_services_supply (relacionando serviços e insumos)
insert into available_services_supply (available_service_id, supply_id, quantity) values
((select id from available_services where name = 'Troca de Óleo' limit 1), (select id from supplies where name = 'Óleo 5W30' limit 1), 3),
((select id from available_services where name = 'Troca de Óleo' limit 1), (select id from supplies where name = 'Filtro de Óleo' limit 1), 1),
((select id from available_services where name = 'Troca de Pastilha de Freio' limit 1), (select id from supplies where name = 'Pastilha de Freio' limit 1), 4),
((select id from available_services where name = 'Troca de Pneu' limit 1), (select id from supplies where name = 'Pneu Aro 15' limit 1), 4),
((select id from available_services where name = 'Troca de Filtro de Ar' limit 1), (select id from supplies where name = 'Filtro de Ar' limit 1), 1),
((select id from available_services where name = 'Troca de Correia Dentada' limit 1), (select id from supplies where name = 'Correia Dentada' limit 1), 1),
((select id from available_services where name = 'Revisão Completa' limit 1), (select id from supplies where name = 'Líquido de Arrefecimento' limit 1), 5),
((select id from available_services where name = 'Polimento' limit 1), (select id from supplies where name = 'Polidor de Pintura' limit 1), 1),
((select id from available_services where name = 'Higienização do Ar Condicionado' limit 1), (select id from supplies where name = 'Desinfetante Automotivo' limit 1), 1),
((select id from available_services where name = 'Revisão Completa' limit 1), (select id from supplies where name = 'Limpador de Para-brisa' limit 1), 2);

-- Preencher vehicles (relacionando com clientes)
insert into vehicles (id, license_plate, manufacture_year, brand, model, person_id, created_at, updated_at) values
(uuid(), 'ABC1A23', 2018, 'Volkswagen', 'Gol', (select id from people where fullname = 'João da Silva' limit 1), now(), now()),
(uuid(), 'DEF2B34', 2020, 'Chevrolet', 'Onix', (select id from people where fullname = 'Maria Oliveira' limit 1), now(), now()),
(uuid(), 'GHI3C45', 2017, 'Fiat', 'Argo', (select id from people where fullname = 'Carlos Souza' limit 1), now(), now()),
(uuid(), 'JKL4D56', 2019, 'Ford', 'Ka', (select id from people where fullname = 'Ana Paula' limit 1), now(), now()),
(uuid(), 'MNO5E67', 2016, 'Hyundai', 'HB20', (select id from people where fullname = 'Pedro Santos' limit 1), now(), now()),
(uuid(), 'PQR6F78', 2021, 'Toyota', 'Corolla', (select id from people where fullname = 'Juliana Lima' limit 1), now(), now()),
(uuid(), 'STU7G89', 2015, 'Renault', 'Sandero', (select id from people where fullname = 'Ricardo Alves' limit 1), now(), now()),
(uuid(), 'VWX8H90', 2018, 'Honda', 'Civic', (select id from people where fullname = 'Fernanda Costa' limit 1), now(), now()),
(uuid(), 'YZA9I01', 2019, 'Nissan', 'Kicks', (select id from people where fullname = 'João da Silva' limit 1), now(), now()),
(uuid(), 'BCD0J12', 2022, 'Jeep', 'Renegade', (select id from people where fullname = 'Maria Oliveira' limit 1), now(), now());

COMMIT;
