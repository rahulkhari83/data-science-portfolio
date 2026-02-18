-- Hotel Operations Analytics (SQL) - Portfolio Project
-- Author: Rahul Khari
-- Target: PostgreSQL (adaptable to MySQL)

DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS reservations;

CREATE TABLE reservations (
  reservation_id VARCHAR(20) PRIMARY KEY,
  arrival_date DATE NOT NULL,
  nights INT NOT NULL,
  room_type VARCHAR(20) NOT NULL,
  booking_channel VARCHAR(20) NOT NULL,
  status VARCHAR(20) NOT NULL,
  nightly_rate_eur NUMERIC(10,2) NOT NULL,
  room_revenue_eur NUMERIC(10,2) NOT NULL,
  extras_revenue_eur NUMERIC(10,2) NOT NULL,
  tax_eur NUMERIC(10,2) NOT NULL,
  total_revenue_eur NUMERIC(10,2) NOT NULL
);

CREATE TABLE payments (
  payment_id VARCHAR(20) PRIMARY KEY,
  reservation_id VARCHAR(20) NOT NULL REFERENCES reservations(reservation_id),
  payment_method VARCHAR(20) NOT NULL,
  amount_paid_eur NUMERIC(10,2) NOT NULL,
  payment_date DATE NOT NULL
);

-- Load CSV (PostgreSQL):
-- \copy reservations FROM 'data/reservations.csv' CSV HEADER;
-- \copy payments FROM 'data/payments.csv' CSV HEADER;

-- Q1: Monthly revenue trend (checked-out only)
SELECT DATE_TRUNC('month', arrival_date) AS month,
       ROUND(SUM(CASE WHEN status='CheckedOut' THEN total_revenue_eur ELSE 0 END), 2) AS revenue_eur
FROM reservations
GROUP BY 1
ORDER BY 1;

-- Q2: Cancellation + no-show rate by channel
SELECT booking_channel,
       ROUND(AVG(CASE WHEN status='Cancelled' THEN 1.0 ELSE 0 END)*100, 2) AS cancel_rate_pct,
       ROUND(AVG(CASE WHEN status='NoShow' THEN 1.0 ELSE 0 END)*100, 2) AS noshow_rate_pct
FROM reservations
GROUP BY 1
ORDER BY cancel_rate_pct DESC;

-- Q3: Average Daily Rate (ADR) by room type
SELECT room_type, ROUND(AVG(nightly_rate_eur), 2) AS adr_eur
FROM reservations
WHERE status='CheckedOut'
GROUP BY 1
ORDER BY adr_eur DESC;

-- Q4: Top 10 highest-value stays
SELECT reservation_id, arrival_date, booking_channel, room_type, total_revenue_eur
FROM reservations
WHERE status='CheckedOut'
ORDER BY total_revenue_eur DESC
LIMIT 10;

-- Q5: Payment reconciliation (paid vs expected)
SELECT r.reservation_id,
       r.total_revenue_eur AS expected_eur,
       ROUND(COALESCE(SUM(p.amount_paid_eur),0),2) AS paid_eur,
       ROUND(r.total_revenue_eur - COALESCE(SUM(p.amount_paid_eur),0),2) AS variance_eur
FROM reservations r
LEFT JOIN payments p ON p.reservation_id = r.reservation_id
GROUP BY r.reservation_id, r.total_revenue_eur
ORDER BY variance_eur DESC;
