// Deployment policy taken from ARC-1's own settings, so this extension writes only where the
// built-in ARC-1 tools may write. The ABAP service enforces its invariants on its own; this is
// the additional guardrail of the deployment.

function entries(value: string | undefined): string[] {
  return (value ?? '')
    .split(',')
    .map((entry) => entry.trim().toUpperCase())
    .filter((entry) => entry !== '');
}

function matches(name: string, pattern: string): boolean {
  if (pattern === '*') {
    return true;
  }
  // A subtree grant (ROOT/**) needs the package hierarchy; only its root package is accepted here
  if (pattern.endsWith('/**')) {
    return name === pattern.slice(0, -3);
  }
  if (pattern.endsWith('*')) {
    return name.startsWith(pattern.slice(0, -1));
  }
  return name === pattern;
}

export function isPackageAllowed(packageName: string, env: NodeJS.ProcessEnv = process.env): boolean {
  const allowed = entries(env.SAP_ALLOWED_PACKAGES);
  const patterns = allowed.length > 0 ? allowed : ['$TMP'];
  return patterns.some((pattern) => matches(packageName.toUpperCase(), pattern));
}

export function isTransportAllowed(transport: string, env: NodeJS.ProcessEnv = process.env): boolean {
  const allowed = entries(env.SAP_ALLOWED_TRANSPORTS);
  return transport === '' || allowed.length === 0 || allowed.some((pattern) => matches(transport.toUpperCase(), pattern));
}

export interface PlannedChange {
  package?: string;
  transport?: string;
}

// Package and transport come from the service's dry run or preview of the change. Without a package the
// policy cannot be checked, so the change is refused; local packages legitimately have no transport.
export function findPolicyViolation(planned: PlannedChange, env: NodeJS.ProcessEnv = process.env): string | undefined {
  if (!planned.package) {
    return 'The service did not report the package of this change, so SAP_ALLOWED_PACKAGES cannot be checked';
  }
  if (!isPackageAllowed(planned.package, env)) {
    return `Package ${planned.package} is not in SAP_ALLOWED_PACKAGES of this ARC-1 server`;
  }
  if (planned.transport && !isTransportAllowed(planned.transport, env)) {
    return `Transport ${planned.transport} is not in SAP_ALLOWED_TRANSPORTS of this ARC-1 server`;
  }
  return undefined;
}
