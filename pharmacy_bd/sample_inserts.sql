-- Ejemplos de INSERTs ordenados para respetar claves foráneas
-- Ajustar ids/valores según necesidades

INSERT INTO pharmacy.permissions (id, name, description) VALUES
(1, 'manage_sales', 'Permite gestionar ventas'),
(2, 'manage_purchases', 'Permite gestionar compras');

INSERT INTO pharmacy.roles (id, name, description, created_at) VALUES
(1, 'admin', 'Administrador', now()),
(2, 'cashier', 'Cajero', now());

INSERT INTO pharmacy.users (id, username, password_hash, full_name, email, status, created_at) VALUES
(1, 'admin', 'hash_admin', 'Admin User', 'admin@example.com', 'active', now()),
(2, 'cashier', 'hash_cashier', 'Cashier User', 'cashier@example.com', 'active', now());

INSERT INTO pharmacy.role_permissions (role_id, permission_id) VALUES
(1,1),(1,2),(2,1);

INSERT INTO pharmacy.user_roles (user_id, role_id) VALUES
(1,1),(2,2);

INSERT INTO pharmacy.payment_methods (id, name, method_type, active) VALUES
(1, 'Cash', 'cash', true),
(2, 'Card', 'card', true);

INSERT INTO pharmacy.inventory_locations (id, name, type, description) VALUES
(1, 'Main Store', 'store', 'Almacén principal');

INSERT INTO pharmacy.units (id, code, name, "precision") VALUES
(1, 'pcs', 'Pieces', 0);

INSERT INTO pharmacy.tax_profiles (id, name, rate, is_inclusive) VALUES
(1, 'IVA', 0.12, false);

INSERT INTO pharmacy.categories (id, "name", parent_id, description) VALUES
(1, 'Medicamentos', NULL, 'Categoría principal'),
(2, 'Analgesicos', 1, 'Subcategoría analgesicos');

INSERT INTO pharmacy.suppliers (id, "name", created_at) VALUES
(1, 'Acme Pharma', now());

INSERT INTO pharmacy.customers (id, "name", document_id, phone, email, credit_limit, status, created_at) VALUES
(1, 'John Doe', '12345678', '+551199999999', 'john@example.com', 0.0, 'active', now());

INSERT INTO pharmacy.products (id, sku, "name", description, brand, category_id, unit_id, is_sellable, track_batches, tax_profile_id, default_cost, sale_price, default_price, created_at) VALUES
(1, 'PARA-100', 'Paracetamol 500mg', 'Tabletas 500mg', 'Genérico', 2, 1, true, true, 1, 2.00, 5.00, 5.00, now());
--Aqui nos quedamos
INSERT INTO pharmacy.product_barcodes (id, product_id, barcode, barcode_type, created_at) VALUES
(1, 1, '1234567890123', 'ean13', now());

INSERT INTO pharmacy.product_prices (id, product_id, price_type, price, created_at) VALUES
(1, 1, 'retail', 5.00, now());


INSERT INTO pharmacy.product_lots (id, product_id, lot_number, qty_on_hand, expiry_date, purchase_id, created_at) VALUES
(1, 1, 'L001', 100.0000, NULL, 1, now());

INSERT INTO pharmacy.purchases (id, supplier_id, invoice_no, "date", subtotal, tax_total, total, status, created_at, created_by) VALUES
(1, 1, 'INV-100', now(), 200.00, 0.00, 200.00, 'completed', now(), 1);

INSERT INTO pharmacy.product_lots (id, product_id, lot_number, qty_on_hand, expiry_date, purchase_id, created_at) VALUES
(1, 1, 'L001', 100.0000, NULL, 1, now());

INSERT INTO pharmacy.purchase_items (id, purchase_id, product_id, lot_id, qty, unit_cost, discount, tax_amount, line_total) VALUES
(1, 1, 1, 1, 100.0000, 2.0000, 0.00, 0.00, 200.00);

INSERT INTO pharmacy.purchase_payments (id, purchase_id, amount, method_id, paid_at, reference) VALUES
(1, 1, 200.00, 2, now(), 'Pago tarjeta');

INSERT INTO pharmacy.sales (id, customer_id, user_id, invoice_no, "date", subtotal, tax_total, discount_total, total, status, is_credit, created_at) VALUES
(1, 1, 2, 'S-100', now(), 50.00, 0.00, 0.00, 50.00, 'finalized', false, now());

INSERT INTO pharmacy.sale_items (id, sale_id, product_id, lot_id, qty, unit_price, discount, tax_amount, line_total) VALUES
(1, 1, 1, 1, 10.0000, 5.0000, 0.00, 0.00, 50.00);

INSERT INTO pharmacy.sale_payments (id, sale_id, amount, method_id, paid_at, reference) VALUES
(1, 1, 50.00, 2, now(), 'Pago venta tarjeta');

INSERT INTO pharmacy.sale_payment_allocations (id, payment_id, credit_invoice_id, amount) VALUES
(1, 1, NULL, 50.00);

INSERT INTO pharmacy.customer_credit_accounts (id, customer_id, balance, limit_amount, last_overdue_date) VALUES
(1, 1, 0.00, 100.00, NULL);

INSERT INTO pharmacy.discounts (id, code, "name", description, discount_type, value, applies_to, product_id, category_id, customer_id, min_qty, priority, active, created_at, created_by) VALUES
(1, 'PROMO10', '10% Off', 'Descuento general 10%', 'percentage', 10.0000, 'all', NULL, 2, NULL, 0.0000, 100, true, now(), 1);

INSERT INTO pharmacy.inventory_movements (id, product_id, lot_id, location_id, change_qty, reason, reference_type, reference_id, "cost", created_at, created_by) VALUES
(1, 1, 1, 1, -10.0000, 'sale', 'sales', 1, 5.00, now(), 2);

INSERT INTO pharmacy.cash_journals (id, "name", description, opening_amount, opened_at, opened_by, status, created_at) VALUES
(1, 'Main Day', 'Jornal caja principal', 0.00, now(), 2, 'open', now());

INSERT INTO pharmacy.cash_entries (id, "name", entry_type, amount, method_id, related_type, related_id, description, recorded_at, recorded_by) VALUES
(1, 'Venta S-100', 'inflow', 50.00, 2, 'sale', 1, 'Pago venta tarjeta', now(), 2);

INSERT INTO pharmacy.audit_log (id, entity_type, table_name, entity_id, "action", changed_by, changed_at, change_data) VALUES
(1, 'sale', 'pharmacy.sales', 1, 'create', 2, now(), '{"total":50.00}'::jsonb);

-- Fin de ejemplo. Ajustar ids, montos y fechas según entorno.
