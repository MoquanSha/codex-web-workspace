// Private cloud export: telemetry disabled; no identity files or network access.
export function optedOut() { return true; }
export async function track() {}
export function __anonymousIdForTest() { return "cloud-private-no-telemetry"; }
export function __resetTelemetryForTest() {}
