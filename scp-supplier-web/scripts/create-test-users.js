const axios = require('axios');
const bcrypt = require('bcrypt');

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000/api/v1';

async function createTestUsers() {
  try {
    // First, we need to create users directly via database or via a setup endpoint
    // Since CreateUser requires auth, let's create a simple script that can be run
    // with direct database access or via an admin endpoint
    
    console.log('⚠️  This script requires direct database access.');
    console.log('Please run the Go script instead: cd ../scp-backend && go run scripts/create-test-users.go');
    console.log('\nOr use the SQL script: migrations/012_create_test_users.sql');
    console.log('\nAlternatively, you can use psql to insert users directly:');
    console.log('\n1. Connect to your database:');
    console.log('   psql -d your_database_name');
    console.log('\n2. Run the SQL script or manually insert:');
    
    const passwordHash = await bcrypt.hash('Test1234!', 10);
    
    console.log('\nSQL to create users:');
    console.log(`
-- Create supplier first
INSERT INTO suppliers (id, name, email, created_at)
VALUES ('00000000-0000-0000-0000-000000000001', 'Test Supplier', 'supplier@test.com', NOW())
ON CONFLICT (email) DO NOTHING;

-- Create owner user (1@gmail.com)
-- Password hash: ${passwordHash}
INSERT INTO users (id, email, password_hash, first_name, last_name, role, supplier_id, created_at)
SELECT 
  '00000000-0000-0000-0000-000000000011',
  '1@gmail.com',
  '${passwordHash}',
  'Owner',
  'User',
  'owner',
  '00000000-0000-0000-0000-000000000001',
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = '1@gmail.com');

-- Create manager user (2@gmail.com)
INSERT INTO users (id, email, password_hash, first_name, last_name, role, supplier_id, created_at)
SELECT 
  '00000000-0000-0000-0000-000000000012',
  '2@gmail.com',
  '${passwordHash}',
  'Manager',
  'User',
  'manager',
  '00000000-0000-0000-0000-000000000001',
  NOW()
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = '2@gmail.com');
    `);
    
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

createTestUsers();

