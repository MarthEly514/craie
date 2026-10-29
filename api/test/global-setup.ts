import { execSync } from 'node:child_process';

// Runs once before the tests: applies the migrations to the TEST database.
// The API tests only run when TEST_DATABASE_URL is set, and never against a hosted database,
// because they empty the tables.
export default function setup() {
  const url = process.env.TEST_DATABASE_URL;
  if (!url) {
    console.warn('TEST_DATABASE_URL is not set: API tests are skipped (unit tests still run).');
    return;
  }
  if (/neon\.tech|render\.com/.test(url)) {
    throw new Error('TEST_DATABASE_URL points to a hosted database. Use a throwaway local one.');
  }
  execSync('npx prisma migrate deploy', {
    stdio: 'inherit',
    env: { ...process.env, DATABASE_URL: url },
  });
}
