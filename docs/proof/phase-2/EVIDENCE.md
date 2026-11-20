# EVIDENCE.md — Phase 2 Verification

> Repo: hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long
> Branch: `phase-2`
> Contract: v1.1 (TICKET-02 "Ba hòn đảo")
> Test suite: `bash tests/run_tests.sh` → 34/34 pass

## Requirement → Evidence table

| Requirement | Source | Test | Evidence | Result |
|---|---|---|---|---|
| Contract v1.1 with standardized tuning | TICKET-02 §1 | Config load + JSON validate | game.contract.json | ✅ PASS |
| 60 tick/s fixed, time_left_s math | TICKET-02 §1 | F11 (dawn via time_left_s) | out/t_f11.jsonl | ✅ PASS |
| 5 lanterns L1–L5 Night 1 (canonical pos) | TICKET-02 §2 | F1 | out/t_f1.jsonl | ✅ PASS |
| 6 lanterns Night 2 | TICKET-02 §2 | headless --night 2 | out/n2_t0.jsonl | ✅ PASS (6 lanterns) |
| 7 lanterns Night 3 + wind field | TICKET-02 §2 | headless --night 3 | out/n3_t0.jsonl | ✅ PASS (7 lanterns, wind:{active,dir_deg}) |
| 20 initial motes at 24 canonical points | TICKET-02 §1 (C4) | F1 (motes_active=20) | out/t_f1.jsonl | ✅ PASS |
| Tick-0 snapshot before inputs | TICKET-02 §Contract | F21 | out/t_f21.jsonl | ✅ PASS |
| No events/score during scenario setup | TICKET-02 §D | F12 | out/t_f12.jsonl | ✅ PASS |
| Determinism (byte-identical double run) | TICKET-02 §Contract | F2 | out/t_det1.jsonl, t_det2.jsonl | ✅ PASS |
| mote_picked event + carried count | TICKET-02 §Contract | F3 | out/t_f3.jsonl | ✅ PASS |
| deposit + lantern_lit (cost 10) | TICKET-02 §1 | F4 | out/t_f4.jsonl | ✅ PASS |
| Shade chase (hysteresis 12/18m) | TICKET-02 §1 | F5 | out/t_f5.jsonl | ✅ PASS |
| Shade safe-radius 6m avoidance | TICKET-02 §1 | F6 | out/t_f6.jsonl | ✅ PASS |
| Pulse 3D, cost 3, stun 120 tick | TICKET-02 §1 | F7 | out/t_f7.jsonl | ✅ PASS |
| player_hit + floor(carried/2) drop | TICKET-02 §1 | F8 | out/t_f8.jsonl | ✅ PASS |
| Win all_lit + score bonus | TICKET-02 §1 | F9 | out/t_f9.jsonl | ✅ PASS |
| Loss no_flames | TICKET-02 §1 | F10 | out/t_f10.jsonl | ✅ PASS |
| Loss dawn (time_left_s) | TICKET-02 §1 | F11 | out/t_f11.jsonl | ✅ PASS |
| Invalid scenario JSON → exit 2 | TICKET-02 §Contract | F15 | (exit code) | ✅ PASS |
| End record on tick-limit (state=playing) | TICKET-02 §Contract | F16 | out/t_f16.jsonl | ✅ PASS |
| Snapshot cadence (tick 0 + every N) | TICKET-02 §Contract | F20 | out/t_f20.jsonl | ✅ PASS |
| Zero-tick = snapshot + end only | TICKET-02 §Contract | F21 | out/t_f21.jsonl | ✅ PASS |
| Input persistence across frames | TICKET-02 §C | F13 | out/t_f13.jsonl | ✅ PASS |
| Non-increasing ticks → exit 2 | TICKET-02 §C | F14 | (exit code) | ✅ PASS |
| Jump physics (vel_y=7, gravity -20) | TICKET-02 §1 | F19 | out/t_f19.jsonl | ✅ PASS |
| Dash event + cooldown | TICKET-02 §1 | G1 | out/g1_dash.jsonl | ✅ PASS (dash event, vel 14, cd_s) |
| Pause: sim_tick frozen, resume runs logic | TICKET-02 §Thứ tự | G21 | out/g21_pause.jsonl | ✅ PASS (sim_tick frozen 6-10, resumes 11) |
| night_start event | TICKET-02 §Contract | determinism run | out/det1_v2.jsonl | ✅ PASS |
| Drifter spawn Night 2 (tick 1200) | TICKET-02 §3 | headless --night 2 | out/n2_drft5.jsonl | ✅ PASS (D1 at sim_tick 1200) |
| Wind Night 3 (warning 1680, active 1800) | TICKET-02 §2 | headless --night 3 | out/n3_wnd.jsonl | ✅ PASS (dir_deg set at 1680, active at 1860) |

## Benchmark (headless full-night, ≤30s required)

| Night | Ticks | Wall time | Limit | Result |
|---|---|---|---|---|
| 1 | 18000 | 1248 ms | 30000 ms | ✅ PASS |
| 2 | 19800 | 1882 ms | 30000 ms | ✅ PASS |
| 3 | 21600 | 2955 ms | 30000 ms | ✅ PASS |

Machine: Windows, Godot 4.7.2 stable, GL Compatibility renderer.

## Phase 2 mechanics verified

- 12-step tick order (TICKET-02 §Thứ tự xử lý)
- Pause/resume: executed_ticks advances, sim_tick frozen, resume runs full logic
- Velocity physics: semi-implicit Euler, jump vel_y=7, gravity -20
- Dash: 14 m/s, 12 ticks, cooldown 1.5s, charm removes cooldown
- Shade state machine: spawning→wander, hysteresis 12/18m, recoil 2m/60t, stunned 120t
- Drifter: idle circle R~3.82m, chase ≥5 motes ≤15m, flee 240t, steal min(3,carried)
- Charm: 600 tick effect, 7.2 m/s, dash no cooldown
- Fall: Y<-10 → -1 flame, lose all motes, wait 60t, respawn, invuln 90t
- Mote spawn +1 every 240t at empty point, cap 30, dropped TTL 480
- Wind (Night 3): warning 1680, active 1800, cycle 1800, push 2 m/s
- Score: +5/deposit, +100/light, +5/stun, win floor(s)×2 + 50×flames
- Snapshot v1.1: night, wind, player.{vel,grounded,invuln,dash_cd_s,pulse_cd_s,charm_s}, motes[].{kind,ttl_s}, drifters[], charms[]

## Open items

| ID | Status |
|---|---|
| OPEN-B15 | Drifter mist_spawn_points use ring over sea gap (assumption; WorldDefs defines separately from mote points) |
