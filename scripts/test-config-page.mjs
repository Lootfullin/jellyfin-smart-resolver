import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const html = fs.readFileSync(
    new URL(
        '../src/Jellyfin.Plugin.SmartResolver/Configuration/ConfigPage.html',
        import.meta.url),
    'utf8');
const functionSource = html.match(
    /function resolverMode\(value\) \{[\s\S]*?\n            \}/)?.[0];
assert.ok(functionSource, 'resolverMode helper is missing');
const resolverMode = vm.runInNewContext(`${functionSource}; resolverMode`);

assert.equal(resolverMode('YearPrefix'), '0');
assert.equal(resolverMode('AnySingleNestedSeries'), '1');
assert.equal(resolverMode('CustomRegex'), '2');
assert.equal(resolverMode(0), '0');
assert.equal(resolverMode('1'), '1');
assert.equal(resolverMode(null), '0');
assert.equal(resolverMode('unexpected'), '0');

console.log('Smart Resolver configuration enum checks passed.');
