"""Validate Rouge content without Godot. Does not execute the game or prove gameplay quality."""
from pathlib import Path
from collections import deque
from copy import deepcopy
import json,re,sys
ROOT=Path(__file__).resolve().parent
D=ROOT/'dados'
errors=[];checks=[]
def check(ok,message):
 (checks if ok else errors).append(message)
def load(name):return json.loads((D/name).read_text(encoding='utf-8-sig'))
def unique(values,what):check(len(values)==len(set(values)),what+' unique IDs')
def acyclic(graph,label):
 visiting=set();done=set()
 def visit(v):
  if v in visiting:raise ValueError(v)
  if v in done:return
  visiting.add(v)
  for w in graph.get(v,[]):visit(w)
  visiting.remove(v);done.add(v)
 try:
  for v in graph:visit(v)
  check(True,label+' has no dependency cycle')
 except ValueError as e:check(False,label+' contains cycle at '+str(e))
scenes=load('dialogos.pt-BR.json')['scenes'];by={s['id']:s for s in scenes}
items=load('itens.json')['items'];item_ids={i['id'] for i in items}
missions=load('missoes.json')['missions'];mids={m['id'] for m in missions}
unique([s['id'] for s in scenes],'Scenes');unique([s['trigger_id'] for s in scenes],'Triggers');unique([i['id'] for i in items],'Items');unique([m['id'] for m in missions],'Missions')
external=set(load('eventos.json')['world_facts']);known_flags=external|{'seen.'+s['id'] for s in scenes}|{e['flag'] for s in scenes for e in s['completion_effects'] if e['op']=='set_flag'}
allowed_ops={'set_flag','grant_unique','grant_bronze_unique','unlock_skin','set_wallet_capacity_min','set_flask_capacity_min','set_resonance_max_min','consume_quest_items_once'}
all_receipts=[];scene_deps={}
for s in scenes:
 nodes={n['id']:n for n in s['nodes']};unique([n['id'] for n in s['nodes']],s['id']+' nodes')
 check(s['entry_node'] in nodes,s['id']+' entry exists');edges={}
 for n in s['nodes']:
  targets=[o['next'] for o in n.get('options',[])] if n['type']=='choice' else [n['next']] if 'next' in n else []
  edges[n['id']]=targets
  check(all(t in nodes for t in targets),n['id']+' references valid next nodes')
  if n['type'] in ['line','direction','choice']:check(bool(n.get('text','').strip()),n['id']+' contains text')
 reachable=set();stack=[s['entry_node']]
 while stack:
  n=stack.pop()
  if n in reachable or n not in nodes:continue
  reachable.add(n);stack+=edges[n]
 check(len(reachable)==len(nodes),s['id']+' has no unreachable nodes')
 ending={n['id'] for n in s['nodes'] if n['type']=='end'}
 can_end=set(ending)
 while True:
  nxt=can_end|{n for n,t in edges.items() if t and all(x in can_end for x in t)}
  if nxt==can_end:break
  can_end=nxt
 check(set(nodes)<=can_end,s['id']+' every choice can terminate')
 for f in s['requires_all']+s['requires_none']:check(f in known_flags,s['id']+' known flag '+f)
 scene_deps[s['id']]=[f[5:] for f in s['requires_all'] if f.startswith('seen.')]
 for e in s['completion_effects']:
  check(e['op'] in allowed_ops,s['id']+' supported effect '+e['op'])
  if 'item_id' in e:check(e['item_id'] in item_ids,s['id']+' known reward item')
  if 'receipt_id' in e:all_receipts.append(e['receipt_id'])
 for it in s.get('requires_items',{}):check(it in item_ids,s['id']+' requires known item')
unique(all_receipts,'Scene reward receipts');acyclic(scene_deps,'Story prerequisites')
for m in missions:
 check(all(x in mids for x in m['requires_missions']),m['id']+' mission prerequisites exist')
 check(all(x in by for x in m['complete_when_all_scenes_seen']),m['id']+' completion scenes exist')
acyclic({m['id']:m['requires_missions'] for m in missions},'Mission graph')
# Both optional routes really are sibling prerequisites, not ordered one after the other.
ma={m['id']:m for m in missions}
check(ma['main_07a']['requires_missions']==ma['main_07b']['requires_missions'],'Agulhas and Vigias can start from the same mission state')
check(set(ma['main_08']['requires_missions'])=={'main_07a','main_07b'},'Submarine access requires both routes')
# Any ordering of available mission completions reaches the end after its corresponding scenes.
for reverse in [False,True]:
 done=set();available_seen={'seen.'+s['id'] for s in scenes}
 while True:
  old=set(done)
  for m in (list(reversed(missions)) if reverse else missions):
   if set(m['requires_missions'])<=done and all('seen.'+x in available_seen for x in m['complete_when_all_scenes_seen']):done.add(m['id'])
  if done==old:break
 check('main_12' in done,'Campaign mission propagation completes in '+('reverse' if reverse else 'forward')+' iteration order')
# Floor plan path checks, including the non-walkable hook gap and explicit traversal edge.
rooms={p.stem:json.loads(p.read_text(encoding='utf-8')) for p in (ROOT/'mapas').glob('*.json')}
unique([e['id'] for r in rooms.values() for e in r['entities']],'World entities')
def flood(r,start,special=True):
 grid=r['grid'];w=r['width'];h=r['height'];q=deque([tuple(start)]);seen=set()
 extra={}
 if special:
  for e in r['special_edges']:
   a,b=tuple(e['from']),tuple(e['to']);extra.setdefault(a,[]).append(b)
   if e.get('bidirectional'):extra.setdefault(b,[]).append(a)
 while q:
  x,y=q.popleft()
  if (x,y) in seen or not(0<=x<w and 0<=y<h) or grid[y][x]!='.':continue
  seen.add((x,y))
  q.extend([(x+1,y),(x-1,y),(x,y+1),(x,y-1)]+extra.get((x,y),[]))
 return seen
for rid,r in rooms.items():
 check(len(r['grid'])==r['height'] and all(len(row)==r['width'] for row in r['grid']),rid+' rectangular grid')
 check(set(''.join(r['grid']))<={'#','.','~'},rid+' known tile types')
 reachable=flood(r,r['entry_default'])
 for e in r['entities']:
  check(tuple(e['tile']) in reachable,rid+' entity on reachable floor: '+e['id'])
 for door in r['doors']:
  check(door['target_room'] in rooms,rid+' target room exists')
  check(tuple(door['tile']) in reachable,rid+' exit reachable: '+door['target_room'])
  if door['target_room'] in rooms:
   target=rooms[door['target_room']]
   check(tuple(door['target_tile']) in flood(target,target['entry_default']),rid+' safe destination: '+door['target_room'])
   reverse=[x for x in target['doors'] if x['id']==door['id'] and x['target_room']==rid]
   check(len(reverse)==1,rid+' door has one matching reverse')
all_room_ids=set();q=['v00_oficina']
while q:
 rid=q.pop()
 if rid in all_room_ids:continue
 all_room_ids.add(rid);q +=[d['target_room'] for d in rooms[rid]['doors']]
check(all_room_ids==set(rooms),'All prototype rooms connected with gates considered open')
hook_room=rooms['t03_treino'];right=tuple(next(d['tile'] for d in hook_room['doors'] if d['side']=='east'))
check(right not in flood(hook_room,hook_room['entry_default'],False),'Hook gap cannot be crossed by walking')
check(right in flood(hook_room,hook_room['entry_default'],True),'Hook gap has a valid special traversal')
# Key must be reachable before traversing its first locked door.
key_source='t00_base';check(any(e['trigger_id']=='chest_ak_key' for e in rooms[key_source]['entities'] if 'trigger_id' in e),'Prototype key source exists before locked door')
check(any(d['gate']=='key:key_ak_base' for d in rooms[key_source]['doors']),'Prototype key has a matching door')
economy=load('economia-progressao.json');v=economy['vida'];r=economy['ressonancia']
check(v['inicial']+v['fragmentos_unicos']//v['fragmentos_por_melhoria']==v['maxima'],'Life progression arithmetic matches')
check(r['inicial']+r['ampliadores']*r['aumento_por_ampliador']==r['maxima'],'Resonance arithmetic matches')
fragments=load('recompensas-mundo.json')['fragments'];unique([f['id'] for f in fragments],'Fragment collectibles');check(len(fragments)==32,'32 unique fragments registered')
check(sum(f['scope']=='prototype' for f in fragments)==8,'8 fragments have prototype placements')
myst=load('misterios.json');check(myst['relic_slots']==1,'One active relic slot')
for m in myst['mysteries']:
 check(m['rewards']['relic_id'] in item_ids,m['id']+' relic is in inventory catalog')
 check(m['reward_scene'] in by,m['id']+' reward scene exists')
 check(m['on_correct_set_flag'] in by[m['reward_scene']]['requires_all'],m['id']+' cannot reward before solved')
 check(len(m['clues'])==3,m['id']+' three explicit clues')
check(sum(m['rewards']['bronze'] for m in myst['mysteries'])==600,'Mystery total Bronze budget matches')
combat=load('combate.json');check(combat['dodge']['invulnerability_end']<combat['dodge']['duration']<combat['dodge']['cooldown_from_start'],'Dodge has vulnerable time and cooldown')
guard=next(e for e in load('inimigos.json')['enemies'] if e['id']=='guarda_contrapeso');check(bool(guard['weakness_without_hook']),'Pre-hook guard has an alternative weakness')
# Reference transaction simulation for authored rewards; not a Godot runtime test.
def apply_scene(scene,state):
 st=deepcopy(state)
 for e in scene['completion_effects']:
  op=e['op'];receipt=e.get('receipt_id')
  if receipt and receipt in st['receipts']:continue
  if op=='set_flag':st['flags'][e['flag']]=e['value']
  elif op=='grant_unique':st['inventory'][e['item_id']]=st['inventory'].get(e['item_id'],0)+e['quantity']
  elif op=='grant_bronze_unique':
   fit=min(e['amount'],max(0,st['capacity']-st['bronze']));st['bronze']+=fit;st['reserve']+=e['amount']-fit
  elif op=='set_wallet_capacity_min':st['capacity']=max(st['capacity'],e['value'])
  elif op=='consume_quest_items_once':
   for i,qty in e['items'].items():
    if st['inventory'].get(i,0)<qty:raise ValueError('Missing quest items')
   for i,qty in e['items'].items():st['inventory'][i]-=qty
  elif op in ['unlock_skin','set_flask_capacity_min','set_resonance_max_min']:pass
  else:raise ValueError('Unsupported effect')
  if receipt:st['receipts'].append(receipt)
 return st
initial={'inventory':{'peca_bomba_a':1,'peca_bomba_b':1},'flags':{},'receipts':[],'capacity':200,'bronze':190,'reserve':0}
for sid in ['p04','p05','t03','r04','x01c','x02c']:
 once=apply_scene(by[sid],initial);twice=apply_scene(by[sid],once);check(once==twice,sid+' reward effects idempotent under duplicate completion')
a=apply_scene(by['o10'],initial);b=apply_scene(by['o02'],a);check(b['capacity']==1500,'Wallet cannot shrink if port reward claimed after lighthouse')
# Freeze the final outcome and privacy in content checks.
check(any(e.get('flag')=='memory.livia.private' and e.get('value') for e in by['v10']['completion_effects']),'Livia recording stays private')
check(any(e.get('flag')=='campaign.completed' for e in by['f06']['completion_effects']),'Clock epilogue completes campaign')
# Mystery answer contracts and rare modifier references.
base_relic=load('base-modificadores-reliquias.json')['base']
for m in myst['mysteries']:
 options=m['answer_options']
 check(len(options)==3 and sum(o['id']==m['correct_answer_id'] for o in options)==1,m['id']+' has three answers and one documented solution')
 check(set(c['id'] for c in m['clues'])<=set(m['submit_requires_all_flags']),m['id']+' answer submission requires all clues')
 for dotted,value in m['relic_modifiers'].items():
  current=base_relic
  try:
   for segment in dotted.split('.'):current=current[segment]
   check(isinstance(current,(int,float)) and value>=0,m['id']+' valid numeric modifier '+dotted)
  except (KeyError,TypeError):check(False,m['id']+' unknown modifier path '+dotted)
check(base_relic['hook']['return_cooldown']==combat['hook']['return_cooldown'],'Relic hook base matches combat')
check(base_relic['guard']['perfect_window']==combat['guard']['perfect_window'],'Relic guard base matches combat')
check(base_relic['healing']['startup']==combat['healing']['startup'],'Relic healing base matches combat')

report={'status':'PASS' if not errors else 'FAIL','scope':'Static content and reference transaction simulations only. No executable game or Godot runtime has been tested.','checks_passed':len(checks),'errors':errors,'content':load('resumo-conteudo.json'),'remaining':'Engine implementation, runtime testing, animation, audio, and 24 later fragment placements remain.'}
(ROOT/'relatorio-validacao.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2));sys.exit(1 if errors else 0)
