-- V2__create_indexes.sql
-- Purpose: Create performance indexes for common queries
-- Date: 2025-11-22

START TRANSACTION;

create index IX_service_order_events_service_order_id on service_order_events (service_order_id);
create index IX_service_orders_client_id on service_orders (client_id);
create index IX_service_orders_vehicle_id on service_orders (vehicle_id);
create index IX_vehicles_person_id on vehicles (person_id);

COMMIT;
