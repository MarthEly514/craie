import 'dotenv/config';
import { z } from 'zod';

// Everything the server reads from the environment, validated once at startup.
// If a required variable is missing the server refuses to start.
const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters'),
  // Allowed browser origins (comma separated). "*" is fine for a mobile app.
  CORS_ORIGIN: z.string().default('*'),
  // Max login attempts per IP per minute
  LOGIN_RATE_LIMIT: z.coerce.number().int().positive().default(10),
});

export type Env = z.infer<typeof schema>;

export function loadEnv(source: NodeJS.ProcessEnv = process.env): Env {
  const result = schema.safeParse(source);
  if (!result.success) {
    const problems = result.error.issues.map((i) => `- ${i.path.join('.')}: ${i.message}`);
    throw new Error(`Invalid environment variables:\n${problems.join('\n')}`);
  }
  return result.data;
}
