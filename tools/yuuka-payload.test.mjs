import assert from 'node:assert/strict';
import test from 'node:test';
import vm from 'node:vm';
import {buildMotionPayload} from '../runtime/motion-payload.mjs';
const config = {themeId:'yuuka-seminar',artKey:'8d4c2008c9f7e7a5d74c',artMetadata:{width:1672,height:941}};
async function captured(overrides={}) {
  const page=vm.createContext({window:{},captured:null});
  await vm.runInContext(buildMotionPayload({basePayload:'void 0',extensionPayload:'void 0',motionTemplate:'captured=__DREAM_SKIN_MOTION_CONFIG_JSON__',config:{...config,...overrides}}),page);
  return page.captured;
}
test('registered Yuuka light and night receive trusted PNG eye frame',async()=>{
  for(const themeId of ['yuuka-seminar','yuuka-seminar-night']) {
    const result=await captured({themeId});
    assert.equal(result.yuukaMotionArt.length,1);
    assert.match(result.yuukaMotionArt[0],/^data:image\/png;base64,iVBOR/);
    assert.ok(JSON.stringify(result.yuukaMotionArt).length<3_000_000);
  }
});
test('changed artwork, dimensions and unrelated themes never receive eye overlay',async()=>{
  for(const override of [{artKey:'changed'},{artKey:'8fe73b0cd207f60fdc08'},{artMetadata:{width:800,height:600}},{themeId:'unrelated'}]) {
    assert.equal((await captured(override)).yuukaMotionArt,undefined);
  }
});

test('the full closed-eye source occurs once in the payload and never in unrelated themes',async()=>{
  const result=await captured();
  const args={basePayload:'void 0',extensionPayload:'void 0',motionTemplate:'void __DREAM_SKIN_MOTION_CONFIG_JSON__',config};
  const source=result.yuukaMotionArt[0];
  assert.equal(buildMotionPayload(args).split(source).length-1,1);
  assert.equal(buildMotionPayload({...args,config:{...config,themeId:'unrelated'}}).includes(source),false);
});
test('caller-provided animation URL is stripped, never forwarded',async()=>{
  assert.equal((await captured({themeId:'unrelated',yuukaClosedArt:'https://example.com/untrusted.png'})).yuukaClosedArt,undefined);
  assert.match((await captured({yuukaMotionArt:['https://example.com/untrusted.png']})).yuukaMotionArt[0],/^data:image\/png;base64,/);
});
