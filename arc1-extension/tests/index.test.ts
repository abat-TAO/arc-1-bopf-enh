import assert from 'node:assert/strict';
import { test, type TestContext } from 'node:test';
import { z } from 'zod';
import type { ToolContext, ToolResult } from 'arc-1/public';
import { findPolicyViolation, isPackageAllowed, isTransportAllowed } from '../src/policy.js';
import { get, read, write } from '../src/service.js';
import { readTool } from '../src/tools/read.js';
import { writeTool } from '../src/tools/write.js';
import { deleteTool } from '../src/tools/delete.js';
import { maintainTool } from '../src/tools/maintain.js';

type Response = { headers: Record<string, string>; body: string };
type Call = { method: string; path: string; body?: Record<string, unknown>; headers?: Record<string, string>; contentType?: string };
const json = (body: unknown): Response => ({ headers: { 'content-type': 'application/json; charset=utf-8' }, body: JSON.stringify(body) });
function mockHttp(...answers: (Response | Error | object)[]) {
  const calls: Call[] = [];
  async function respond(call: Call) {
    calls.push(call);
    assert.ok(answers.length, 'Unexpected HTTP call');
    const answer = answers.shift()!;
    if (!('headers' in answer)) throw answer;
    return answer as Response;
  }
  // All context capabilities except the mocked HTTP methods fail on access.
  const ctx = new Proxy({ http: {
    get: async (path: string, headers: Record<string, string>) => respond({ method: 'GET', path, headers }),
    post: async (path: string, body: string, contentType: string, headers: Record<string, string>) =>
      respond({ method: 'POST', path, body: JSON.parse(body), contentType, headers }),
  } }, { get(target, property) { assert.equal(property, 'http'); return target.http; } }) as unknown as ToolContext;
  return { ctx, calls };
}
function text(result: ToolResult): string {
  const first = result.content[0];
  assert.equal(first.type, 'text');
  return (first as { text: string }).text;
}
function withPolicy(run: (suite: TestContext) => Promise<void>) {
  return test('tools honor package and transport policy', async (suite) => {
    const packages = process.env.SAP_ALLOWED_PACKAGES;
    const transports = process.env.SAP_ALLOWED_TRANSPORTS;
    process.env.SAP_ALLOWED_PACKAGES = '$TMP';
    process.env.SAP_ALLOWED_TRANSPORTS = 'A4HK900001';
    try { await run(suite); } finally {
      if (packages === undefined) delete process.env.SAP_ALLOWED_PACKAGES; else process.env.SAP_ALLOWED_PACKAGES = packages;
      if (transports === undefined) delete process.env.SAP_ALLOWED_TRANSPORTS; else process.env.SAP_ALLOWED_TRANSPORTS = transports;
    }
  });
}

for (const [pattern, accepted, rejected] of [
  ['zexact', 'ZEXACT', 'ZEXACT_CHILD'], ['ZPRE*', 'zprefix', 'OTHER'],
  ['*', '/ANY/NAME', ''], ['ROOT/**', 'root', 'ROOT/CHILD'],
] as const) {
  test(`policy matches ${pattern}`, () => {
    assert.equal(isPackageAllowed(accepted, { SAP_ALLOWED_PACKAGES: pattern }), true);
    assert.equal(isTransportAllowed(accepted, { SAP_ALLOWED_TRANSPORTS: pattern }), true);
    if (rejected) {
      assert.equal(isPackageAllowed(rejected, { SAP_ALLOWED_PACKAGES: pattern }), false);
      assert.equal(isTransportAllowed(rejected, { SAP_ALLOWED_TRANSPORTS: pattern }), false);
    }
  });
}
test('empty package policy allows only $TMP; empty transport policy allows all', () => {
  for (const value of [undefined, '', ' , ']) {
    const env = { SAP_ALLOWED_PACKAGES: value, SAP_ALLOWED_TRANSPORTS: value };
    assert.equal(isPackageAllowed('$tmp', env), true);
    assert.equal(isPackageAllowed('$LOCAL', env), false);
    assert.equal(isPackageAllowed('ZPACKAGE', env), false);
    assert.equal(isTransportAllowed('A4HK900001', env), true);
  }
  assert.equal(isTransportAllowed('', { SAP_ALLOWED_TRANSPORTS: 'OTHER' }), true);
  assert.equal(isPackageAllowed('ZSECOND', { SAP_ALLOWED_PACKAGES: ' zfirst, , zsecond ' }), true);
});
test('policy reports package before transport and accepts a local plan', () => {
  const env = { SAP_ALLOWED_PACKAGES: '$TMP', SAP_ALLOWED_TRANSPORTS: 'A4HK900001' };
  assert.match(findPolicyViolation({ package: 'ZBAD', transport: 'BAD' }, env)!, /Package ZBAD/);
  assert.match(findPolicyViolation({ package: '$TMP', transport: 'BAD' }, env)!, /Transport BAD/);
  assert.equal(findPolicyViolation({ package: '$TMP', transport: '' }, env), undefined);
});
test('service encodes queries, omits undefined and requests JSON', async () => {
  const { ctx, calls } = mockHttp(json({ result: [] }));
  assert.equal((await get(ctx, 'enhancement', { name: '/BOBF/NAME', scope: undefined })).ok, true);
  const query = new URL(calls[0].path, 'https://mock.invalid');
  assert.equal(query.searchParams.get('name'), '/BOBF/NAME');
  assert.equal(query.searchParams.has('scope'), false);
  assert.deepEqual(calls[0].headers, { Accept: 'application/json' });
});
for (const statusCode of [400, 404, 409, 422, 499]) {
  test(`service returns JSON ${statusCode} as isError for GET and POST`, async () => {
    const body = '  {"error":"business error"}';
    const { ctx } = mockHttp({ statusCode, responseBody: body }, { statusCode, responseBody: body });
    const result = await read(ctx, 'enhancement', {});
    assert.equal(result.isError, true); assert.equal(text(result), body);
    const answer = await write(ctx, { operation: 'updateNode' });
    assert.equal(answer.ok, false);
    if (!answer.ok) { assert.equal(answer.result.isError, true); assert.equal(text(answer.result), body); }
  });
}
for (const statusCode of [429, 503]) {
  test(`service rethrows unconfirmed POST ${statusCode} unchanged`, async () => {
    const error = {
      statusCode,
      responseBody: JSON.stringify({ messages: [{ text: 'POST completion is unconfirmed' }] }),
      pluginPostOutcome: 'unknown',
    };
    const { ctx, calls } = mockHttp(error);
    await assert.rejects(() => write(ctx, { operation: 'updateNode', dryRun: true }), (actual) => actual === error);
    assert.equal(calls.length, 1);
    assert.equal(calls[0].method, 'POST');
  });
}
test('service rejects non-JSON success responses', async () => {
  for (const contentType of ['text/html', 'text/plain', '']) {
    const { ctx } = mockHttp({ headers: { 'content-type': contentType }, body: '<html>login</html>' });
    const answer = await get(ctx, 'check', {});
    assert.equal(answer.ok, false);
    if (!answer.ok) { assert.equal(answer.result.isError, true); assert.match(text(answer.result), /Unexpected response/); }
  }
});
test('service rethrows network, 5xx and non-object 4xx errors unchanged', async () => {
  for (const error of [new Error('offline'), { statusCode: 500, responseBody: '{}' },
    { statusCode: 404, responseBody: '<html>inactive</html>' }, { statusCode: 422, responseBody: '[]' }]) {
    for (const send of [() => read(mockHttp(error).ctx, 'check', {}), () => write(mockHttp(error).ctx, {})]) {
      await assert.rejects(send, (actual) => actual === error);
    }
  }
});
test('read tool validates required parameters before HTTP', async () => {
  for (const what of ['enhancements', 'enhancement']) {
    const { ctx, calls } = mockHttp();
    assert.equal((await readTool.handler({ what }, ctx)).isError, true);
    assert.equal(calls.length, 0);
  }
});
test('read tool routes all resources and normalizes names', async () => {
  for (const args of [{ what: 'businessObjects' }, { what: 'enhancements', baseBo: '/bobf/epm_sales_order' },
    { what: 'enhancement', name: 'zbe_test_so', scope: 'all' }]) {
    const { ctx, calls } = mockHttp(json({ result: [] }));
    assert.equal((await readTool.handler(args, ctx)).isError, undefined);
    const url = new URL(calls[0].path, 'https://mock.invalid');
    assert.ok(url.pathname.endsWith(`/${args.what}`));
    if (args.name) assert.equal(url.searchParams.get('name'), 'ZBE_TEST_SO');
    if (args.baseBo) assert.equal(url.searchParams.get('baseBo'), '/BOBF/EPM_SALES_ORDER');
    if (args.scope) assert.equal(url.searchParams.get('scope'), 'all');
  }
});

withPolicy(async (suite) => {
  const request = { operation: 'updateNode', enhancement: 'ZBE_TEST_SO', name: 'ZBE_TEST_NOTE', description: 'Note' };
  const plan = json({ result: { package: '$TMP', transport: '' } });
  const saved = json({ result: { changed: true } });
  await suite.test('write runs a dry run before the requested write', async () => {
    const { ctx, calls } = mockHttp(plan, saved);
    assert.equal(text(await writeTool.handler(request, ctx)), saved.body);
    assert.deepEqual(calls.map(call => call.body), [{ ...request, dryRun: true }, request]);
    assert.ok(calls.every(call => call.method === 'POST' && call.path.endsWith('/write') && call.contentType === 'application/json'));
  });
  await suite.test('write forwards databaseTable to the dry run and the real request', async () => {
    const args = { operation: 'createNode', enhancement: 'ZBE_TEST_SO', node: 'ZBE_TEST_NOTE',
      name: 'ZBE_TEST_NOTE_SUB', dataStructure: 'ZBE_S_TEST_NOTE', databaseTable: 'ZBE_D_UNIT_SUB' };
    const { ctx, calls } = mockHttp(plan, saved);
    assert.equal(text(await writeTool.handler(args, ctx)), saved.body);
    assert.deepEqual(calls.map(call => call.body), [{ ...args, dryRun: true }, args]);
    assert.ok(calls.every(call => call.method === 'POST' && call.path.endsWith('/write')));
  });
  for (const args of [
    { operation: 'createEnhancement', name: 'ZBE_UNIT', baseBusinessObject: '/BOBF/EPM_SALES_ORDER',
      package: '$TMP', constantsInterface: 'zif_be_unit' },
    { operation: 'createNode', enhancement: 'ZBE_TEST_SO', node: 'ZBE_TEST_NOTE', name: 'ZBE_TEST_UNIT',
      isTransient: true, combinedStructure: 'zbe_s_unit_c', combinedTableType: 'zbe_t_unit_c' },
  ]) {
    await suite.test(`write forwards generated name overrides for ${args.operation}`, async () => {
      const generated = args.operation === 'createEnhancement'
        ? [{ type: 'constantsInterface', name: 'ZIF_BE_UNIT' }]
        : [{ type: 'combinedStructure', name: 'ZBE_S_UNIT_C' }, { type: 'combinedTableType', name: 'ZBE_T_UNIT_C' }];
      const preview = json({ result: { package: '$TMP', generated } });
      const response = json({ result: { generated, alreadyExisted: false } });
      const { ctx, calls } = mockHttp(preview, response);
      assert.equal(text(await writeTool.handler(args, ctx)), response.body);
      assert.deepEqual(calls.map(call => call.body), [{ ...args, dryRun: true }, args]);
      const dry = mockHttp(preview);
      assert.equal(text(await writeTool.handler({ ...args, dryRun: true }, dry.ctx)), preview.body);
      assert.deepEqual(dry.calls.map(call => call.body), [{ ...args, dryRun: true }]);
    });
  }
  await suite.test('write override schemas reject invalid characters and lengths before HTTP', async () => {
    for (const property of ['constantsInterface', 'combinedStructure', 'combinedTableType']) {
      for (const value of ['ZBAD-NAME', 'Z' + 'A'.repeat(30), '']) {
        const { ctx, calls } = mockHttp();
        await assert.rejects(() => writeTool.handler({ ...request, [property]: value }, ctx));
        assert.deepEqual(calls, []);
      }
    }
  });
  await suite.test('write propagates override rejection and never sends a second request', async () => {
    const body = JSON.stringify({ messages: [{ id: 'ZBE_BOPF_ENH', number: '034', text: 'Name already exists' }] });
    const { ctx, calls } = mockHttp({ statusCode: 422, responseBody: body });
    const result = await writeTool.handler({ ...request, constantsInterface: 'ZIF_EXISTING' }, ctx);
    assert.equal(result.isError, true);
    assert.equal(text(result), body);
    assert.equal(calls.length, 1);
    assert.equal(calls[0].body?.dryRun, true);
  });
  for (const tool of [writeTool, maintainTool]) {
    await suite.test(`${tool.name} stops after denied or failed dry runs and respects dryRun`, async () => {
      const args = tool === writeTool ? request : { operation: 'refresh', enhancement: 'ZBE_TEST_SO' };
      for (const result of [{ package: 'ZBAD' }, { package: '$TMP', transport: 'A4HK900002' }]) {
        const { ctx, calls } = mockHttp(json({ result }));
        assert.equal((await tool.handler(args, ctx)).isError, true);
        assert.equal(calls.length, 1); assert.equal(calls[0].body?.dryRun, true);
      }
      const { ctx, calls } = mockHttp(plan);
      assert.equal(text(await tool.handler({ ...args, dryRun: true }, ctx)), plan.body);
      assert.equal(calls.length, 1);
      const failed = mockHttp({ statusCode: 422, responseBody: '{"error":"invalid"}' });
      assert.equal((await tool.handler(args, failed.ctx)).isError, true);
      assert.equal(failed.calls.length, 1);
    });
  }
  await suite.test('tools reject plans without a package after the first HTTP call', async () => {
    for (const tool of [writeTool, maintainTool, deleteTool]) {
      const args = tool === writeTool ? request : tool === maintainTool
        ? { operation: 'refresh', enhancement: 'ZBE_TEST_SO' }
        : { enhancement: 'ZBE_TEST_SO', entityType: 'node', name: 'ZBE_TEST_NOTE', token: 'a'.repeat(64) };
      for (const body of [{}, { result: {} }, { result: { package: '' } }, { result: { transport: 'A4HK900001' } }]) {
        const { ctx, calls } = mockHttp(json(body));
        const result = await tool.handler(args, ctx);
        assert.equal(result.isError, true);
        assert.equal(text(result), 'The service did not report the package of this change, so SAP_ALLOWED_PACKAGES cannot be checked');
        assert.equal(calls.length, 1);
        assert.equal(calls[0].method, tool === deleteTool ? 'GET' : 'POST');
      }
      const allowed = mockHttp(json({ result: { package: '$TMP' } }), saved);
      assert.equal(text(await tool.handler(args, allowed.ctx)), saved.body);
      assert.equal(allowed.calls.length, 2);
    }
  });
  await suite.test('create checks the requested package independently of the server plan', async () => {
    const { ctx, calls } = mockHttp(plan);
    assert.equal((await writeTool.handler({ operation: 'createEnhancement', name: 'ZNEW', baseBusinessObject: '/BOBF/EPM_SALES_ORDER', package: 'ZBAD' }, ctx)).isError, true);
    assert.equal(calls.length, 1);
  });
  await suite.test('delete previews without token and posts only after token and policy checks', async () => {
    const args = { enhancement: 'zbe_test_so', entityType: 'node', name: 'zbe_test_note', transport: 'a4hk900001' };
    const target = { enhancement: 'ZBE_TEST_SO', entityType: 'node', name: 'ZBE_TEST_NOTE', transport: 'A4HK900001' };
    const token = 'a'.repeat(64);
    const preview = json({ result: { package: '$TMP', token, deletes: [{ type: 'node', name: 'ZBE_TEST_NOTE' }] } });
    const first = mockHttp(preview);
    assert.equal(text(await deleteTool.handler(args, first.ctx)), preview.body);
    assert.equal(first.calls.length, 1); assert.equal(first.calls[0].method, 'GET');
    const second = mockHttp(preview, saved);
    assert.equal(text(await deleteTool.handler({ ...args, token }, second.ctx)), saved.body);
    assert.deepEqual(second.calls.map(call => call.method), ['GET', 'POST']);
    assert.deepEqual(second.calls[1].body, { operation: 'delete', ...target, token });
    const url = new URL(second.calls[0].path, 'https://mock.invalid');
    assert.ok(url.pathname.endsWith('/deletePreview')); assert.equal(url.searchParams.has('token'), false);
    for (const [key, value] of Object.entries(target)) assert.equal(url.searchParams.get(key), value);
    for (const result of [{ package: 'ZBAD' }, { package: '$TMP', transport: 'A4HK900002' }]) {
      const blocked = mockHttp(json({ result }));
      assert.equal((await deleteTool.handler({ ...args, token }, blocked.ctx)).isError, true);
      assert.equal(blocked.calls.length, 1);
    }
    const failed = mockHttp({ statusCode: 404, responseBody: '{"error":"missing"}' });
    assert.equal((await deleteTool.handler({ ...args, token }, failed.ctx)).isError, true);
    assert.equal(failed.calls.length, 1);
  });
  await suite.test('maintain routes check to GET and refresh through a dry run', async () => {
    const check = json({ result: {
      enhancement: 'ZBE_TEST_SO',
      findings: [
        { severity: 'W', text: 'Own node finding', entityType: 'node', entityName: 'ZBE_TEST_NOTE' },
        { severity: 'E', text: 'Lost elements', entityType: '', entityName: '' },
      ],
      baseFindings: [
        { severity: 'W', text: 'Determination is never executed', entityType: 'determination', entityName: 'DET_PROP_DOCREF_BR' },
      ],
    } });
    const checked = mockHttp(check);
    const result = await maintainTool.handler({ operation: 'check', enhancement: 'zbe_test_so' }, checked.ctx);
    assert.equal(result.isError, undefined);
    assert.equal(text(result), check.body);
    assert.equal(checked.calls.length, 1); assert.equal(checked.calls[0].method, 'GET');
    assert.ok(checked.calls[0].path.endsWith('/check?enhancement=ZBE_TEST_SO'));
    const refreshed = mockHttp(plan, saved);
    await maintainTool.handler({ operation: 'refresh', enhancement: 'zbe_test_so', transport: 'a4hk900001' }, refreshed.ctx);
    const refresh = { operation: 'refresh', enhancement: 'ZBE_TEST_SO', transport: 'A4HK900001' };
    assert.deepEqual(refreshed.calls.map(call => call.body), [{ ...refresh, dryRun: true }, refresh]);
  });
});

// Suspicious behavior: a leading brace is accepted without validating the JSON error body.
test('service currently accepts malformed object-shaped 4xx bodies', async () => {
  const { ctx } = mockHttp({ statusCode: 422, responseBody: '{invalid JSON' });
  const answer = await get(ctx, 'check', {});
  assert.equal(answer.ok, false);
  if (!answer.ok) {
    assert.equal(answer.result.isError, true);
    assert.equal(text(answer.result), '{invalid JSON');
  }
});
test('policy requires a package but allows an absent transport', () => {
  const env = { SAP_ALLOWED_PACKAGES: '$TMP', SAP_ALLOWED_TRANSPORTS: 'A4HK900001' };
  const violation = 'The service did not report the package of this change, so SAP_ALLOWED_PACKAGES cannot be checked';
  assert.equal(findPolicyViolation({}, env), violation);
  assert.equal(findPolicyViolation({ package: '', transport: 'A4HK900001' }, env), violation);
  assert.equal(findPolicyViolation({ package: '$TMP' }, env), undefined);
  assert.equal(findPolicyViolation({ package: '$TMP', transport: '' }, env), undefined);
});


test('names lookup requires operation and name before HTTP', async () => {
  for (const args of [{ what: 'names' }, { what: 'names', operation: 'createNode' },
    { what: 'names', name: 'ZBE_TEST_UNIT' }]) {
    const { ctx, calls } = mockHttp();
    const result = await readTool.handler(args, ctx);
    assert.equal(result.isError, true);
    assert.equal(text(result), 'operation and name are required for what=names');
    assert.deepEqual(calls, []);
  }
});

for (const operation of ['createEnhancement', 'createNode', 'createAction', 'createDetermination',
  'createValidation', 'createAssociation', 'createActionEnhancement', 'createActionValidation']) {
  test(`names lookup forwards and normalizes identifiers for ${operation}`, async () => {
    const response = json({ result: { class: 'ZCL_BE_UNIT', parameterStructure: 'ZBE_S_UNIT',
      constantsInterface: 'ZIF_BE_UNIT', dataStructure: 'ZBE_S_UNIT_D', transientStructure: 'ZBE_S_UNIT_T',
      combinedStructure: 'ZBE_S_UNIT_C', combinedTableType: 'ZBE_T_UNIT_C', databaseTable: 'ZBE_D_UNIT',
      hints: ['Database table proposal cannot be generated'] } });
    const { ctx, calls } = mockHttp(response);
    const result = await readTool.handler({ what: 'names', operation, name: 'zbe_test_unit',
      enhancement: 'zbe_test_so', node: 'zbe_test_note', baseAction: '/bobf/confirm', action: 'confirm' }, ctx);
    assert.equal(result.isError, undefined);
    assert.equal(text(result), response.body);
    assert.equal(calls.length, 1);
    assert.equal(calls[0].method, 'GET');
    const url = new URL(calls[0].path, 'https://mock.invalid');
    assert.ok(url.pathname.endsWith('/names'));
    assert.deepEqual(Object.fromEntries(url.searchParams), { operation, name: 'ZBE_TEST_UNIT',
      enhancement: 'ZBE_TEST_SO', node: 'ZBE_TEST_NOTE', baseAction: '/BOBF/CONFIRM', action: 'CONFIRM' });
    assert.deepEqual(calls[0].headers, { Accept: 'application/json' });
  });
}

test('enhancement names lookup omits optional context', async () => {
  const { ctx, calls } = mockHttp(json({ result: { constantsInterface: 'ZIF_BE_UNIT' } }));
  await readTool.handler({ what: 'names', operation: 'createEnhancement', name: 'zbe_unit' }, ctx);
  const url = new URL(calls[0].path, 'https://mock.invalid');
  assert.deepEqual(Object.fromEntries(url.searchParams), { operation: 'createEnhancement', name: 'ZBE_UNIT' });
});

test('names lookup rejects unsupported operations without HTTP', async () => {
  for (const operation of ['updateEnhancement', 'updateAction', 'createQuery', 'createAlternativeKey', 'unknown']) {
    const { ctx, calls } = mockHttp();
    await assert.rejects(() => readTool.handler({ what: 'names', operation, name: 'ZBE_UNIT' }, ctx));
    assert.deepEqual(calls, []);
  }
});

test('names lookup preserves business errors from SAP', async () => {
  const body = JSON.stringify({ messages: [{ id: 'ZBE_BOPF_ENH', number: '004', text: 'Missing node' }] });
  const { ctx, calls } = mockHttp({ statusCode: 400, responseBody: body });
  const result = await readTool.handler({ what: 'names', operation: 'createNode', name: 'ZBE_UNIT' }, ctx);
  assert.equal(result.isError, true);
  assert.equal(text(result), body);
  assert.equal(calls.length, 1);
});

test('write description documents generated objects and names lookup', () => {
  assert.match(writeTool.description, /result\.generated/);
  assert.match(writeTool.description, /Custom_BopfEnhRead what=names/);
});

test('maintain check description documents both finding lists and entity locations', () => {
  const operation = (maintainTool.schema as z.ZodObject).shape.operation.description ?? '';
  for (const field of ['findings', 'baseFindings', 'entityType', 'entityName']) {
    assert.ok(operation.includes(field), `Missing check result field ${field}`);
  }
  assert.match(operation, /no entity: the enhancement as a whole/);
});

for (const scope of ['own', 'all'] as const) {
  test(`enhancement read uppercases node together with scope ${scope}`, async () => {
    const response = json({ result: { nodes: [{ name: 'ROOT' }] } });
    const { ctx, calls } = mockHttp(response);
    assert.equal(text(await readTool.handler({ what: 'enhancement', name: 'zbe_test_so', node: 'root', scope }, ctx)), response.body);
    assert.equal(calls.length, 1);
    assert.equal(calls[0].method, 'GET');
    const url = new URL(calls[0].path, 'https://mock.invalid');
    assert.ok(url.pathname.endsWith('/enhancement'));
    assert.deepEqual(Object.fromEntries(url.searchParams), { name: 'ZBE_TEST_SO', scope, node: 'ROOT' });
  });
}
for (const scope of [undefined, 'own', 'all'] as const) {
  test(`enhancement read omits absent node with scope ${scope ?? 'default'}`, async () => {
    const { ctx, calls } = mockHttp(json({ result: {} }));
    await readTool.handler({ what: 'enhancement', name: 'zbe_test_so', scope }, ctx);
    assert.equal(calls.length, 1);
    const url = new URL(calls[0].path, 'https://mock.invalid');
    assert.ok(url.pathname.endsWith('/enhancement'));
    assert.equal(url.searchParams.has('node'), false);
    assert.deepEqual(Object.fromEntries(url.searchParams), { name: 'ZBE_TEST_SO', ...(scope ? { scope } : {}) });
  });
}
