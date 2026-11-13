import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import test from 'node:test';
const source = await fs.readFile(new URL('../runtime/renderer-inject.js', import.meta.url), 'utf8');
const block = source.slice(source.indexOf('  const YUUKA_PLAN_KEY ='), source.indexOf('  let yuukaGreetingNode ='));
const { createYuukaPlanStore, key } = new Function(block + 'return {createYuukaPlanStore, key:YUUKA_PLAN_KEY};')();
function fixture() {
  const values = new Map([['native-settings', 'unchanged']]);
  const storage = {getItem: k => values.get(k) ?? null, setItem: (k,v) => values.set(k,v)};
  let id = 0;
  const fresh = () => createYuukaPlanStore(() => storage, () => `test-${++id}`);
  return { values, storage, fresh, store: fresh() };
}
test('add, check and delete persist through a fresh store; unrelated native data survives', () => {
  const f = fixture();
  assert.deepEqual(f.store.read(), { items: [], error: null });
  const added = f.store.change('add', '  核算今天的计划  ');
  assert.equal(added.error, null);
  const id = added.items[0].id;
  assert.equal(f.fresh().read().items[0].text, '核算今天的计划');
  assert.equal(f.fresh().change('done', {id, done: true}).items[0].done, true);
  assert.equal(f.fresh().read().items[0].done, true);
  assert.equal(f.fresh().change('remove', id).items.length, 0);
  assert.equal(f.fresh().read().items.length, 0);
  assert.equal(f.values.get('native-settings'), 'unchanged');
});
test('failed writes retain committed data and do not claim success', () => {
  const f = fixture(); f.store.change('add', '已保存');
  const original = f.values.get(key);
  f.storage.setItem = () => { throw new Error('quota'); };
  const result = f.store.change('done', {id: 'test-1', done: true});
  assert.match(result.error, /保存失败/);
  assert.equal(result.items[0].done, false);
  assert.equal(f.values.get(key), original);
  assert.equal(f.store.change('add', '未保存').items.length, 1);
});
test('corrupt, oversized, duplicate and unknown-version records are never overwritten', () => {
  for (const raw of ['bad JSON', 'x'.repeat(65537), '{"version":2,"items":[]}',
    JSON.stringify({version:1,items:[{id:'x',text:'a',done:false},{id:'x',text:'b',done:false}]}),
    JSON.stringify({version:1,items:[{id:'x',text:'a',done:'yes'}]})]) {
    const f = fixture(); f.values.set(key, raw);
    assert.match(f.store.change('add', '不要覆盖').error, /原数据已保留/);
    assert.equal(f.values.get(key), raw);
  }
  const unavailable = createYuukaPlanStore(() => {throw new Error('security');}, () => 'x');
  assert.match(unavailable.change('add', 'test').error, /无法读取/);
});
test('latest other-window writes are read before a change; text is not interpreted as markup', () => {
  const f = fixture(), other = f.fresh();
  f.store.change('add', '<img src=x onerror=alert(1)>');
  other.change('add', '另一个窗口');
  const result = f.store.change('done', {id:'test-1',done:true});
  assert.equal(result.items.length, 2);
  assert.equal(result.items[0].text, '<img src=x onerror=alert(1)>');
  assert.equal(result.items[0].done, true);
  assert.match(source, /text\.textContent = item\.text/);
});
test('blank, excessive length and list capacity are bounded without data loss', () => {
  const f = fixture();
  for (const text of ['  ', 'x'.repeat(121)]) assert.ok(f.store.change('add', text).error);
  for (let i=0;i<100;i++) assert.equal(f.store.change('add', `计划${i}`).error, null);
  assert.match(f.store.change('add', '超出').error, /100/);
  assert.equal(f.fresh().read().items.length, 100);
});
