import fs from 'node:fs/promises';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import test from 'node:test';
const source = await fs.readFile(new URL('../runtime/renderer-inject.js', import.meta.url), 'utf8');
new vm.Script(source);
const block = source.slice(source.indexOf('  let yuukaGreetingNode ='), source.indexOf('  const refreshParts ='));
function node(tag = 'div') {
  return { tag, attrs: new Map(), children: [], parentElement: null,
    getAttribute(k) { return this.attrs.get(k) ?? null; },
    setAttribute(k,v) { this.attrs.set(k,v); }, removeAttribute(k) { this.attrs.delete(k); },
    hasAttribute(k) { return this.attrs.has(k); },
    appendChild(n) { this.children.push(n); n.parentElement = this; return n; },
    remove() { if(this.parentElement) this.parentElement.children = this.parentElement.children.filter(n=>n!==this); this.parentElement=null; },
    matches() { return this.unsafe === true; }, querySelector(selector) { return selector === 'button' ? this.projectButton || null : this.editor || null; },
    contains(n) { return this.children.includes(n); },
  };
}
function setup(id, appearance = 'light') {
  const parent=node(), hero=parent.appendChild(node()), icon=parent.appendChild(node()), composer=parent.appendChild(node('textarea'));
  const sidebar=node(), chatButton=sidebar.appendChild(node('button'));
  chatButton.textContent='新聊天'; chatButton.clientWidth=220;
  sidebar.querySelectorAll=()=>[chatButton];
  const document={createElement: tag=>node(tag)};
  const selectorNodes=k=> k==='game-source'?[hero]:k==='home-icon'?[icon]:k==='left-panel'?[sidebar]:[];
  const api=new Function('isYuukaTheme','selectorNodes','document','THEME',block+'return {syncYuukaGreeting,clearYuukaGreeting,syncYuukaSidebar,clearYuukaSidebar};')(
    ['yuuka-seminar','yuuka-seminar-night'].includes(id),selectorNodes,document,{appearance});
  return {parent,hero,icon,composer,sidebar,chatButton,...api};
}
test('only Yuuka themes replace exact greeting, preserving composer and icon anchors',()=>{
  for(const id of ['yuuka-seminar','yuuka-seminar-night']) {
    const f=setup(id), greeting=f.syncYuukaGreeting(f.hero);
    assert.notEqual(greeting,f.hero);
    assert.equal(f.hero.getAttribute('data-yuuka-native-hidden'),'true');
    assert.equal(f.hero.getAttribute('aria-hidden'),'true');
    assert.equal(f.icon.parentElement,f.parent);
    assert.equal(f.composer.parentElement,f.parent);
    assert.equal(f.composer.attrs.size,0);
    assert.equal(greeting.children.at(-1).textContent,'老师，今天也一起加油吧。');
    assert.equal(f.syncYuukaGreeting(f.hero),greeting,'idempotent refresh');
    f.clearYuukaGreeting();
    assert.equal(f.hero.getAttribute('data-yuuka-native-hidden'),null);
    assert.equal(f.hero.getAttribute('aria-hidden'),null);
    assert.equal(greeting.parentElement,null);
  }
  for(const id of ['preset-internet-angel-default','custom-yuuka','standard']) {
    const f=setup(id); assert.equal(f.syncYuukaGreeting(f.hero),f.hero); assert.equal(f.hero.attrs.size,0);
  }
});
test('cleanup restores prior accessibility values and unsafe broad nodes fail closed',()=>{
  const f=setup('yuuka-seminar-night','dark'); f.hero.setAttribute('aria-hidden','false');
  const greeting=f.syncYuukaGreeting(f.hero);
  assert.equal(greeting.children.at(-1).textContent,'老师，剩下的工作，我们一起完成吧。');
  f.clearYuukaGreeting(); assert.equal(f.hero.getAttribute('aria-hidden'),'false');
  f.hero.editor=f.composer;
  assert.equal(f.syncYuukaGreeting(f.hero),f.hero);
  assert.equal(f.hero.getAttribute('data-yuuka-native-hidden'),null);
});
test('CSS preserves native titlebar geometry and home-icon anchor box',async()=>{
  const css=await fs.readFile(new URL('../runtime/yuuka-skin.css',import.meta.url),'utf8');
  assert.doesNotMatch(css,/--app-shell-titlebar-top-inset|--app-shell-page-inline-end-inset/);
  assert.doesNotMatch(css,/\[data-testid="home-icon"\]\s*\{[^}]*display:\s*none/);
  assert.doesNotMatch(css,/\[data-ds-part="sidebar"\]::after/);
});

test('project greeting uses only native button text and follows project changes',()=>{
  const f=setup('yuuka-seminar');
  f.hero.textContent='What shall we work on in Entire wrong sentence?';
  f.hero.projectButton={textContent:'  Research\n  Lab  '};
  const greeting=f.syncYuukaGreeting(f.hero);
  assert.equal(greeting.children.at(-1).textContent,'老师，一起推进「Research Lab」吧');
  f.hero.projectButton.textContent='<img src=x onerror=alert(1)>';
  assert.equal(f.syncYuukaGreeting(f.hero),greeting);
  assert.equal(greeting.children.at(-1).textContent,'老师，一起推进「<img src=x onerror=alert(1)>」吧');
  f.hero.projectButton=null;
  f.syncYuukaGreeting(f.hero);
  assert.equal(greeting.children.at(-1).textContent,'老师，今天也一起加油吧。');
  f.clearYuukaGreeting();
  assert.equal(f.hero.textContent,'What shall we work on in Entire wrong sentence?');
});

test('Schale badge stays inside roomy new-chat controls and cleans up',()=>{
  const f=setup('yuuka-seminar');
  f.syncYuukaSidebar();
  assert.equal(f.chatButton.children.length,1);
  assert.equal(f.chatButton.children[0].getAttribute('aria-hidden'),'true');
  assert.equal(f.sidebar.children.length,1,'no shell-level ornament');
  f.syncYuukaSidebar(); assert.equal(f.chatButton.children.length,1);
  f.chatButton.clientWidth=120; f.syncYuukaSidebar();
  assert.equal(f.chatButton.children.length,0);
  f.chatButton.clientWidth=220; f.syncYuukaSidebar(); f.clearYuukaSidebar();
  assert.equal(f.chatButton.children.length,0);
  assert.equal(f.chatButton.getAttribute('data-yuuka-new-chat'),null);
  const other=setup('standard'); other.syncYuukaSidebar(); assert.equal(other.chatButton.children.length,0);
});


test('project dossier replacement preserves disclosure and cleans up',()=>{
  const f=setup('yuuka-seminar'), row=node(), icon=node('span'), disclosure=node('span'), actions=node('button');
  row.appendChild(icon); row.appendChild(disclosure); row.appendChild(actions);
  row.querySelector=selector=>selector.includes('aria-label')?actions:selector.includes('icon-leading-slot')?icon:null;
  f.sidebar.querySelectorAll=selector=>selector.includes('group/folder-row')?[row]:[f.chatButton];
  f.syncYuukaSidebar();
  assert.equal(icon.getAttribute('data-yuuka-project-icon'),'');
  assert.equal(disclosure.attrs.size,0);
  assert.equal(actions.attrs.size,0);
  f.syncYuukaSidebar();
  f.clearYuukaSidebar();
  assert.equal(icon.getAttribute('data-yuuka-project-icon'),null);
});

test('Workspace labels only the native project section and preserves its controls',()=>{
  const f=setup('yuuka-seminar'), title=node('button'), unrelated=node('button');
  title.textContent='项目'; title.setAttribute('data-app-action-sidebar-section-toggle','');
  title.setAttribute('aria-expanded','false'); unrelated.textContent='项目';
  f.sidebar.querySelectorAll=selector=>selector.includes('group/folder-row')?[]:[title,unrelated];
  f.syncYuukaSidebar();
  assert.equal(title.getAttribute('data-yuuka-workspace-title'),'');
  assert.equal(title.getAttribute('aria-expanded'),'false');
  assert.equal(title.textContent,'项目');
  assert.equal(unrelated.getAttribute('data-yuuka-workspace-title'),null);
  f.clearYuukaSidebar();
  assert.equal(title.getAttribute('data-yuuka-workspace-title'),null);
});
