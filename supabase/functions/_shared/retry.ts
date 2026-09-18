import { HttpError } from "./errors.ts";

export interface RetryOptions {
  maxAttempts?: number;
  baseDelayMs?: number;
  maxDelayMs?: number;
  retryOn?: (error: unknown) => boolean;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  logger?: { warn: (...args: any[]) => void; error: (...args: any[]) => void };
  label?: string;
}

const defaultOptions: Required<Omit<RetryOptions, "logger" | "label">> = {
  maxAttempts: 3,
  baseDelayMs: 1000,
  maxDelayMs: 10000,
  retryOn: (err: unknown) => {
    if (err instanceof HttpError && err.status >= 500) return true;
    if (err instanceof TypeError) return true;
    if (err instanceof DOMException && err.name === "AbortError") return true;
    return false;
  },
};

function shouldRetry(err: unknown, retryOn: (error: unknown) => boolean): boolean {
  if (err instanceof HttpError && err.status < 500) return false;
  return retryOn(err);
}

function computeDelay(attempt: number, baseDelayMs: number, maxDelayMs: number): number {
  const delay = Math.min(baseDelayMs * Math.pow(2, attempt - 1), maxDelayMs);
  const jitter = delay * (0.5 + Math.random() * 0.5);
  return Math.floor(jitter);
}

export async function withRetry<T>(
  fn: () => Promise<T>,
  options?: RetryOptions,
): Promise<T> {
  const maxAttempts = options?.maxAttempts ?? defaultOptions.maxAttempts;
  const baseDelayMs = options?.baseDelayMs ?? defaultOptions.baseDelayMs;
  const maxDelayMs = options?.maxDelayMs ?? defaultOptions.maxDelayMs;
  const retryOn = options?.retryOn ?? defaultOptions.retryOn;
  const logger = options?.logger;
  const label = options?.label ?? "operation";

  let lastError: unknown;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;

      if (attempt < maxAttempts && shouldRetry(err, retryOn)) {
        const delayMs = computeDelay(attempt, baseDelayMs, maxDelayMs);
        logger?.warn(`${label} failed (attempt ${attempt}/${maxAttempts}), retrying in ${delayMs}ms`, {
          attempt,
          maxAttempts,
          delayMs,
          errorMessage: err instanceof Error ? err.message : String(err),
        });
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      } else {
        if (attempt > 1) {
          logger?.error(`${label} failed after ${attempt} attempts`, err, {
            attempt,
            maxAttempts,
          });
        }
        throw err;
      }
    }
  }

  throw lastError;
}
