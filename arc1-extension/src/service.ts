import type { ToolContext, ToolResult } from 'arc-1/public';

export const servicePath = '/sap/bc/zbe_bopf_enh';

// Business object names, optionally in a namespace: /SCMTMS/TOR, ZENH_TOR
export const objectNamePattern = /^(?:\/[A-Za-z0-9_]{1,10}\/)?[A-Za-z0-9_]{1,30}$/;

interface HttpError {
  statusCode: number;
  responseBody?: string;
}

// The bundle carries its own copy of the ARC-1 error classes, so instanceof does not work here.
function isHttpError(error: unknown): error is HttpError {
  return typeof error === 'object' && error !== null && typeof (error as HttpError).statusCode === 'number';
}

// ARC-1 marks a POST whose execution it cannot confirm (network error, 429, 5xx). Only the original error
// carries its warning not to repeat the call blindly.
function isUnconfirmedPost(error: unknown): boolean {
  return typeof error === 'object' && error !== null && (error as { pluginPostOutcome?: unknown }).pluginPostOutcome === 'unknown';
}

function toQuery(parameters: Record<string, string | undefined>): string {
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(parameters)) {
    if (value !== undefined) {
      query.set(key, value);
    }
  }
  return query.toString();
}

export function textResult(text: string, isError = false): ToolResult {
  return isError ? { content: [{ type: 'text', text }], isError } : { content: [{ type: 'text', text }] };
}

export type ServiceAnswer = { ok: true; body: string } | { ok: false; result: ToolResult };

async function call(ctx: ToolContext, send: () => Promise<{ headers: Record<string, string>; body: string }>): Promise<ServiceAnswer> {
  try {
    const response = await send();
    const contentType = response.headers['content-type'] ?? '';
    // An HTML logon page with status 200 is not detected by ARC-1 outside /sap/bc/adt/
    if (!contentType.includes('application/json')) {
      return {
        ok: false,
        result: textResult(`Unexpected response from ${servicePath} (content type "${contentType}"). Is the ICF service active?`, true),
      };
    }
    return { ok: true, body: response.body };
  } catch (error) {
    // Business errors come back as JSON with a 4xx status. Everything else (HTML error pages of an inactive
    // node, 5xx, network, POSTs with unconfirmed execution) is rethrown so ARC-1 adds its own hints and warnings.
    if (
      !isUnconfirmedPost(error) &&
      isHttpError(error) &&
      error.statusCode >= 400 &&
      error.statusCode < 500 &&
      error.responseBody?.trimStart().startsWith('{')
    ) {
      return { ok: false, result: textResult(error.responseBody, true) };
    }
    throw error;
  }
}

export async function get(
  ctx: ToolContext,
  resource: string,
  parameters: Record<string, string | undefined>,
): Promise<ServiceAnswer> {
  const path = `${servicePath}/${resource}?${toQuery(parameters)}`;
  return call(ctx, () => ctx.http.get(path, { Accept: 'application/json' }));
}

export async function read(
  ctx: ToolContext,
  resource: string,
  parameters: Record<string, string | undefined>,
): Promise<ToolResult> {
  const answer = await get(ctx, resource, parameters);
  return answer.ok ? textResult(answer.body) : answer.result;
}

export async function write(ctx: ToolContext, request: object): Promise<ServiceAnswer> {
  return call(ctx, () =>
    ctx.http.post(`${servicePath}/write`, JSON.stringify(request), 'application/json', { Accept: 'application/json' }),
  );
}
