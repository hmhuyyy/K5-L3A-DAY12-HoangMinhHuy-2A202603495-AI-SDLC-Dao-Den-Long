# EVIDENCE.md — Phase 1 Verification

> Repo: hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long  
> Tag: `phase-1`  
> Test suite: `bash tests/run_tests.sh` → 22 passed, 0 failed

## Requirement → Evidence table

| Requirement | Source | Test | Evidence file | Result |
|---|---|---|---|---|
| 60 tick/s, time_left_s math | PRD-0 §B | F11 (time_left_s=1 → dawn at tick 61) | out/t_f11.jsonl | ✅ PASS |
| Exactly 5 lanterns L1–L5 in tick-0 | PRD-0 §1 | F1 | out/t_f1.jsonl | ✅ PASS |
| Tick-0 snapshot before inputs | PRD-0 §B | F21 (0 ticks → snapshot+end only) | out/t_f21.jsonl | ✅ PASS |
| No events/score during scenario setup | PRD-0 §D | F12 | out/t_f12.jsonl | ✅ PASS |
| Determinism (byte-identical double run) | PRD-0 §E | F2 | out/t_det1.jsonl, out/t_det2.jsonl | ✅ PASS |
| mote_picked event + carried count | PRD-0 §E | F3 | out/t_f3.jsonl | ✅ PASS |
| deposit + lantern_lit event | PRD-0 §E | F4 | out/t_f4.jsonl | ✅ PASS |
| Shade chases player | PRD-0 §1 | F5 | out/t_f5.jsonl | ✅ PASS |
| Shade safe-radius around lit lantern | PRD-0 §1 | F6 | out/t_f6.jsonl | ✅ PASS |
| game_over reason=dawn | PRD-0 §E | F11 | out/t_f11.jsonl | ✅ PASS |
| End record always last, state=playing on tick-limit | PRD-0 §E | F16 | out/t_f16.jsonl | ✅ PASS |
| Invalid scenario JSON → exit 2 | PRD-0 §B | F15 | (exit code check) | ✅ PASS |
| Snapshot cadence: tick 0 + every snapshot-every | PRD-0 §E | F20 | out/t_f20.jsonl | ✅ PASS |
| game.contract.json complete | PRD-0 §A | schema check | game.contract.json | ✅ PASS |

## Not yet implemented

| Item | Reason | Plan |
|---|---|---|
| 3D GameScene (visual gameplay) | headless core complete first; 3D scene is passive view | Will add before phase-1 tag |
| pulse mechanic | test scenario not in F-suite yet; logic implemented in GameSim | Manual verify via headless before tag |
| player_hit + drop | logic implemented; dedicated test scenario pending | Add F8 scenario before tag |
| win condition (all_lit) | logic implemented; scenario needs 5-lantern flow | Add F9 scenario before tag |

## How to reproduce

```bash
git clone https://github.com/hmhuyyy/K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long.git
cd K5-L3A-DAY12-HoangMinhHuy-2A202603495-AI-SDLC-Dao-Den-Long
git checkout phase-1   # (after tag is applied)
bash tests/run_tests.sh
```

Expected output: `Results: 22 passed, 0 failed`
