SET search_path TO virustc_core, public;

-- =====================================================================
-- 1. SYSTEM ROLES REGISTER
-- =====================================================================
CREATE TABLE IF NOT EXISTS roles (
    role_name VARCHAR(50) PRIMARY KEY,
    description TEXT NOT NULL
);

INSERT INTO roles (role_name, description) VALUES
('ATTENDING_PHYSICIAN', 'Full clinical, telemetry oversight, and automated lot quarantine operational authority.'),
('MEDICAL_STUDENT', 'Read-only access to de-identified cases, tracking maps, and residency rotation logs.');

-- =====================================================================
-- 2. PERMISSIONS REGISTER
-- =====================================================================
CREATE TABLE IF NOT EXISTS permissions (
    permission_key VARCHAR(100) PRIMARY KEY,
    description TEXT NOT NULL
);

INSERT INTO permissions (permission_key, description) VALUES
('read:maps', 'Permission to view geographic vector and transmission maps.'),
('write:prescriptions', 'Permission to draft and authorize digital prescription manifolds.'),
('execute:quarantine', 'Permission to manually fire geofencing or lot quarantine triggers.'),
('read:academic_records', 'Permission to view residency and student milestone evaluations.');

-- =====================================================================
-- 3. ROLE-PERMISSIONS MAP MATRIX
-- =====================================================================
CREATE TABLE IF NOT EXISTS role_permissions (
    role_name VARCHAR(50) REFERENCES roles(role_name) ON DELETE CASCADE,
    permission_key VARCHAR(100) REFERENCES permissions(permission_key) ON DELETE CASCADE,
    PRIMARY KEY (role_name, permission_key)
);

-- Map Attending Physician Matrix (Full access suite)
INSERT INTO role_permissions (role_name, permission_key) VALUES
('ATTENDING_PHYSICIAN', 'read:maps'),
('ATTENDING_PHYSICIAN', 'write:prescriptions'),
('ATTENDING_PHYSICIAN', 'execute:quarantine'),
('ATTENDING_PHYSICIAN', 'read:academic_records');

-- Map Medical Student Matrix (Restricted profile)
INSERT INTO role_permissions (role_name, permission_key) VALUES
('MEDICAL_STUDENT', 'read:maps'),
('MEDICAL_STUDENT', 'read:academic_records');

-- =====================================================================
-- 4. LINK USERS TO SYSTEM ROLES
-- =====================================================================
CREATE TABLE IF NOT EXISTS user_roles (
    username VARCHAR(100) REFERENCES system_users(username) ON DELETE CASCADE,
    role_name VARCHAR(50) REFERENCES roles(role_name) ON DELETE CASCADE,
    PRIMARY KEY (username, role_name)
);

-- Bind initial administrative user to Attending Physician parameters
INSERT INTO user_roles (username, role_name) 
VALUES ('vtc_command_admin', 'ATTENDING_PHYSICIAN')
ON CONFLICT DO NOTHING;
