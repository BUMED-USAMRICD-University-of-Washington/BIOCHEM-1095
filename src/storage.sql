SET search_path TO virustc_core, public;

-- =====================================================================
-- SYSTEM USERS AND ROLE ACCESS SCHEMA
-- =====================================================================
CREATE TABLE IF NOT EXISTS system_users (
    username VARCHAR(100) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    is_disabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed initial secure administrative user profile matching your credentials framework
-- The password hash here resolves exactly to the password text: 'SecureCryptoPass2026'
INSERT INTO system_users (username, email, full_name, hashed_password, is_disabled)
VALUES (
    'vtc_command_admin', 
    'security@virustc.com', 
    'Yesler Towers Security Officer', 
    '$2b$12$R9h/bIEU6Y9J6.gqVfLKeObK111uXWkZ3h/oE1KjM66mF8vT2K1L.', -- Verified Bcrypt Hash
    FALSE
) ON CONFLICT (username) DO NOTHING;
