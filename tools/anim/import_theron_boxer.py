"""Replace every Theron binding; archive old resources and record exact PSA provenance."""
import argparse, hashlib, json, zipfile
from pathlib import Path
from read_exported_psa import read_psa

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('export_root', type=Path)
    args = ap.parse_args()
    project = Path(__file__).resolve().parents[2]
    disk = args.export_root / 'MK12/Content/Disk'
    char = disk / 'Char/JohnnyCage/Anim'
    shared = {p.stem: p for p in (disk / 'Shared/Anim').rglob('*.psa')}
    pack = json.loads((project/'data/animation/mixamo_pack_map.json').read_text())
    actions = pack['fighters']['theron']['actions']
    backup = project/'build/theron_before_boxer.zip'
    if not backup.exists():
        with zipfile.ZipFile(backup, 'w', zipfile.ZIP_DEFLATED) as z:
            for p in (project/'assets/animations/exported/theron').glob('*.res'):
                z.write(p, p.name)
            z.writestr('actions.json', json.dumps(actions, indent=2))
    # No Baraka/Geras clips or previously used Shared reactions are retained.
    states = {
        'idle':'Nav/Stance_Mid_Active', 'walk_fwd':'Nav/StepWalk_WalkFwd_Loop',
        'walk_back':'Nav/StepWalk_WalkBwd_Loop', 'run':'Nav/StepWalk_Fwd',
        'block':'Nav/Block_Loop', 'block_impact':'Nav/Block_HitHigh_1',
        'dodge':'Nav/Dash_Bwd', 'grab':'Attack/Throw_Miss',
        'grab_hold':'Attack/Throw_Bwd_Hit', 'grab_throw':'Attack/Throw_Bwd_Hit',
        'grabbed':'Attack/Throw_Bwd_Hit_Victim', 'win':'Nav/Stance_Taunt_2',
        'zeus_wrath':'Supermove/Roster/InGame/Supermove_InGame_Into',
        'olympian_barrage':'Supermove/Roster/InGame/Supermove_InGame_Hit_Into',
        'zeus_bolt':'Attack/BackPunch_2_Into', 'hermes_dash':'Nav/Dash_Fwd',
        'ares_rage':'Nav/Stance_Taunt_1', 'forge_shield':'Nav/Block_Up_Into',
    }
    reactions = {
        'stagger':'High_F_Stumble_Back_4', 'knockdown':'High_F_Stumble_Stun_ToKnees_FallFwd_1',
        'get_up':'Getup_Back_FeetFacing', 'lose':'High_F_Stumble_Stun_ToKnees_FallFwd_1',
        'crawl':'Brutality_Death_GroundCrawlOnFront', 'torso_scuttle':'Brutality_Death_CrawlOnFront_2',
        'torso_roll':'Brutality_Death_CrawlOnFront_3', 'hit_head_snap':'High_F_InPlace_Face_Back_6',
        'hit_light':'Middle_F_InPlace_6', 'reaction_gut_crumple':'Middle_F_InPlace_7',
        'reaction_wall_splat_bounce':'High_F_Stumble_Back_5', 'hit_low':'Low_F_InPlace_FrontLeg_Low_3',
        'hit_electric':'Brutality_Death_Shocked_2', 'sever_arm':'Brutality_Death_BothArmsFreakout',
        'sever_leg_l':'Brutality_Death_LeftLegHop_2', 'sever_leg_r':'Brutality_Death_RightLegHop_2',
    }
    punches = {'punch_jab':'FrontPunch_1','punch_cross':'BackPunch_1','hook':'FrontPunch_2',
               'overhead_slam':'BackPunch_2_Into','heavy_strike':'BackPunch_1',
               'kick_low':'DuckFrontKick_1','kick_sweep':'DuckBackKick_1',
               'kick_stomp':'FrontKick_1','kick_thrust':'FrontKick_1'}
    core = {'lead':'FrontPunch_1','power':'BackPunch_1','rise':'FrontKick_1','low':'DuckFrontKick_1',
            'counter':'DuckFrontPunch_1','breaker':'FrontPunch_2','finisher':'DuckBackPunch_1'}
    sources, manifest = {}, []
    manifest_path = project/"data/animation/theron_boxer_manifest.json"
    previous = {row["action"]: row.get("previous_resource_sha256") for row in json.loads(manifest_path.read_text())} if manifest_path.exists() else {}
    for action in actions:
        if action in states:
            path = char / (states[action]+'.psa')
        elif action in reactions:
            path = shared[reactions[action]]
        else:
            move = action.removeprefix('move_')
            stem = punches.get(action, core.get(move.removeprefix('theron_'), 'FrontPunch_1'))
            if not move.startswith('theron_') and action.startswith('move_'):
                row = json.loads((project/'data/moves'/f'{move}.json').read_text())
                stem = 'DuckFrontKick_1' if row.get('category') == 'kick' else 'BackPunch_1' if row.get('limb_side') == 'arm_r' else 'FrontPunch_1'
            path = char/'Attack'/(stem+'.psa')
        clip = read_psa(path)
        name = 'TheronBoxerV2_'+action
        (project/'build/exported_motion'/f'{name}.json').write_text(json.dumps(clip,separators=(',',':')))
        sources[action] = name
        existing = project/'assets/animations/exported/theron'/((action.removeprefix('move_') if action.startswith('move_') else 'action_'+action)+'.res')
        manifest.append({'action':action,'source':path.as_posix(),'sha256':clip['sha256'],
                         'previous_resource_sha256':previous.get(action, hashlib.sha256(existing.read_bytes()).hexdigest() if existing.exists() else None)})
    (project/'data/animation/theron_boxer_sources.json').write_text(json.dumps({'theron':sources},indent=2)+'\n')
    (project/'data/animation/theron_boxer_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('Extracted',len(sources),'replacement bindings; backup:',backup)

if __name__ == '__main__': main()
