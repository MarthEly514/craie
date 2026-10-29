import { z } from 'zod';

z.config(z.locales.fr()); // zod validation messages in French

/** An error that is meant to be shown to the client as `{ code, message }`. */
export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

export const unauthorized = (message = 'Authentification requise') =>
  new AppError(401, 'UNAUTHORIZED', message);
export const forbidden = (message = 'Action non autorisée pour votre rôle') =>
  new AppError(403, 'FORBIDDEN', message);
export const notFound = (message = 'Élément introuvable') =>
  new AppError(404, 'NOT_FOUND', message);

/** Validates `data` with a zod schema; throws a 422 with a readable message otherwise. */
export function parse<T extends z.ZodType>(schema: T, data: unknown): z.infer<T> {
  const result = schema.safeParse(data);
  if (!result.success) {
    const issue = result.error.issues[0];
    const field = issue?.path.join('.') || 'données';
    throw new AppError(422, 'VALIDATION_ERROR', `Champ « ${field} » invalide : ${issue?.message}`);
  }
  return result.data;
}
