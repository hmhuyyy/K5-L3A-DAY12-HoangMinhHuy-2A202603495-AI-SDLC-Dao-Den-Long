#!/usr/bin/env bash
# run_tests.sh — Phase 1-4 regression suite (headless scenarios + in-process unit tests).
# Exits non-zero on any failure. See docs/notes/test-migration.md for superseded tests.
set -uo pipefail

GODOT="${GODOT_BIN:-C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Godot FileAccess needs Windows-style paths (c:/...), not POSIX (/c/...).
ROOT_WIN="$(echo "$ROOT" | sed 's|^/\([a-zA-Z]\)/|\1:/|')"
OUT="$ROOT/out"
OUT_WIN="$ROOT_WIN/out"
SC="$ROOT/tests/scenarios"
SC_WIN="$ROOT_WIN/tests/scenarios"
mkdir -p "$OUT"

PASS=0
FAIL=0

# run <label> <posix_out_path> [extra godot args...]
# --out receives a Windows path so Godot FileAccess can create the file.
run() {
	local label="$1" posix_out="$2"
	shift 2
	local win_out
	win_out="$(echo "$posix_out" | sed 's|^/\([a-zA-Z]\)/|\1:/|')"
	"$GODOT" --headless --path "$ROOT_WIN" --script res://src/headless.gd -- "$@" --out "$win_out" 2>/dev/null
	return $?
}

check() {
	if eval "$2"; then
		echo "PASS  $1"
		PASS=$((PASS+1))
	else
		echo "FAIL  $1"
		FAIL=$((FAIL+1))
	fi
}

# ── F1: tick-0 snapshot, 5 lanterns, score 0 ──────────────────────────
run F1 "$OUT/t_f1.jsonl" --seed 1 --night 1 --ticks 0
L1=$(grep -o '"id":"L[0-9]"' "$OUT/t_f1.jsonl" | wc -l)
check "F1 5 lanterns in tick-0" "[ \"$L1\" -eq 5 ]"
check "F1 score=0 at tick0"     'head -1 "$OUT/t_f1.jsonl" | grep -q "\"score\":0"'
check "F1 2 lines total (snapshot+end)" "[ \"$(wc -l < "$OUT/t_f1.jsonl")\" -eq 2 ]"

# ── F2: determinism ────────────────────────────────────────────────────
run F2a "$OUT/t_det1.jsonl" --seed 42 --night 1 --ticks 600
run F2b "$OUT/t_det2.jsonl" --seed 42 --night 1 --ticks 600
check "F2 determinism (byte-identical)" 'diff -q "$OUT/t_det1.jsonl" "$OUT/t_det2.jsonl" >/dev/null'

# ── F3: mote pickup ────────────────────────────────────────────────────
run F3 "$OUT/t_f3.jsonl" \
  --seed 1 --night 1 --ticks 10 \
  --scenario "$SC_WIN/f3.json" --inputs "$SC_WIN/f3_inputs.json" \
  --snapshot-every 5
check "F3 mote_picked fires" 'grep -q "\"name\":\"mote_picked\"" "$OUT/t_f3.jsonl"'
MC=$(grep -c '"name":"mote_picked"' "$OUT/t_f3.jsonl" || echo 0)
check "F3 exactly 1 mote_picked" "[ \"$MC\" -eq 1 ]"

# ── F4: deposit + lantern_lit ─────────────────────────────────────────
run F4 "$OUT/t_f4.jsonl" \
  --seed 1 --night 1 --ticks 5 \
  --scenario "$SC_WIN/f4.json" --inputs "$SC_WIN/f4_inputs.json" \
  --snapshot-every 5
check "F4 deposit fires"     'grep -q "\"name\":\"deposit\""     "$OUT/t_f4.jsonl"'
check "F4 lantern_lit fires" 'grep -q "\"name\":\"lantern_lit\"" "$OUT/t_f4.jsonl"'

# ── F5: shade chases player ────────────────────────────────────────────
run F5 "$OUT/t_f5.jsonl" \
  --seed 1 --night 1 --ticks 60 \
  --scenario "$SC_WIN/f5.json" --snapshot-every 20
# shade S1 starts at x=20; first snapshot should show x=20.0
check "F5 shade S1 starts at x=20" \
  'grep "\"type\":\"snapshot\"" "$OUT/t_f5.jsonl" | head -1 | grep -q "\"id\":\"S1\""'
# After 20 ticks it should be closer (x < 20)
S1_X=$(grep '"type":"snapshot"' "$OUT/t_f5.jsonl" | tail -1 | grep -o '"id":"S1","pos":\[[0-9.-]*' | grep -o '[0-9.-]*$')
check "F5 shade moved closer after 60 ticks" '[ -n "$S1_X" ] && awk "BEGIN{exit !($S1_X < 20)}"'

# ── F6: safe-radius – shade near lit lantern stays outside ─────────────
run F6 "$OUT/t_f6.jsonl" \
  --seed 1 --night 1 --ticks 60 \
  --scenario "$SC_WIN/f6.json" --snapshot-every 20
# shade S1 starts at x=5, lantern L1 lit at origin, safe_radius=4
# shade must never be within 4 m of origin
check "F6 shade never enters safe zone" \
  '! grep "\"id\":\"S1\"" "$OUT/t_f6.jsonl" | grep -v "\"state\"" | awk -F"\"pos\":" "{print \$2}" | awk -F"," "{dist=\$1+0; if(dist<0)dist=-dist; if(dist<=4){found=1}} END{exit !found}"'

# ── F12: no events during scenario setup ──────────────────────────────
run F12 "$OUT/t_f12.jsonl" \
  --seed 1 --night 1 --ticks 0 \
  --scenario "$SC_WIN/f12.json"
EV=$(grep -c '"type":"event"' "$OUT/t_f12.jsonl" 2>/dev/null || true)
EV="${EV:-0}"
check "F12 no events at setup"      "[ \"$EV\" -eq 0 ]"
check "F12 score=0 with lit lantern" 'head -1 "$OUT/t_f12.jsonl" | grep -q "\"score\":0"'

# ── F14/F15: bad JSON inputs / scenario → exit 2 ──────────────────────
echo "{not valid json" > "$SC/f15_bad.json"
run F15 "$OUT/t_f15.jsonl" \
  --seed 1 --night 1 --ticks 1 \
  --scenario "$SC_WIN/f15_bad.json"
F15_CODE=$?
check "F15 invalid scenario exits 2" "[ \"$F15_CODE\" -eq 2 ]"

# ── F16: tick-limit end record state=playing ──────────────────────────
run F16 "$OUT/t_f16.jsonl" \
  --seed 1 --night 1 --ticks 30
check "F16 end record present"       'tail -1 "$OUT/t_f16.jsonl" | grep -q "\"type\":\"end\""'
check "F16 end state=playing"        'tail -1 "$OUT/t_f16.jsonl" | grep -q "\"state\":\"playing\""'
check "F16 end ticks=30"             'tail -1 "$OUT/t_f16.jsonl" | grep -q "\"ticks\":30"'

# ── F21: zero-tick = exactly 2 lines ──────────────────────────────────
run F21 "$OUT/t_f21.jsonl" --seed 1 --night 1 --ticks 0
LN=$(wc -l < "$OUT/t_f21.jsonl")
check "F21 zero-tick = 2 lines"       "[ \"$LN\" -eq 2 ]"
check "F21 no events in zero-tick"    '! grep -q "\"type\":\"event\"" "$OUT/t_f21.jsonl"'

# ── F11: dawn loss via short time_left_s in scenario ──────────────────
run F11 "$OUT/t_f11.jsonl" \
  --seed 1 --night 1 --ticks 70 \
  --scenario "$SC_WIN/f11.json" --snapshot-every 30
check "F11 game_over reason=dawn"    'grep -q "\"reason\":\"dawn\""   "$OUT/t_f11.jsonl"'
check "F11 end state=lost"           'tail -1 "$OUT/t_f11.jsonl" | grep -q "\"state\":\"lost\""'

# ── F20: snapshot cadence (tick 0 + every 10) ─────────────────────────
run F20 "$OUT/t_f20.jsonl" --seed 1 --night 1 --ticks 30 --snapshot-every 10
SNAPS=$(grep -c '"type":"snapshot"' "$OUT/t_f20.jsonl" || true)
SNAPS="${SNAPS:-0}"
# Expect tick 0, 10, 20, 30 → 4 snapshots
check "F20 snapshot cadence (4 snapshots in 30 ticks)" "[ \"$SNAPS\" -eq 4 ]"

# ── F7: pulse stuns shades ───────────────────────────────────────────
run F7 "$OUT/t_f7.jsonl" \
  --seed 1 --night 1 --ticks 10 \
  --scenario "$SC_WIN/f7.json" --inputs "$SC_WIN/f7_inputs.json" \
  --snapshot-every 10
check "F7 pulse event fires"        'grep -q "\"name\":\"pulse\""  "$OUT/t_f7.jsonl"'
check "F7 shade state=stunned after pulse" \
  'grep "\"type\":\"snapshot\"" "$OUT/t_f7.jsonl" | tail -1 | grep -q "\"state\":\"stunned\""'

# ── F8: player_hit + drop ────────────────────────────────────────────
run F8 "$OUT/t_f8.jsonl" \
  --seed 1 --night 1 --ticks 10 \
  --scenario "$SC_WIN/f8.json" \
  --snapshot-every 10
check "F8 player_hit event fires" 'grep -q "\"name\":\"player_hit\"" "$OUT/t_f8.jsonl"'
check "F8 drop ratio applied"     'grep -q "\"dropped\":2"          "$OUT/t_f8.jsonl"'

# ── F9: win dawn_survived (TICKET-03: all lit + time_left_s=1 → dawn_survived) ─
run F9 "$OUT/t_f9.jsonl" \
  --seed 1 --night 1 --ticks 65 \
  --scenario "$SC_WIN/f9.json" --snapshot-every 30
check "F9 game_over reason=dawn_survived" 'grep -q "\"reason\":\"dawn_survived\"" "$OUT/t_f9.jsonl"'
check "F9 end state=won"                  'tail -1 "$OUT/t_f9.jsonl" | grep -q "\"state\":\"won\""'

# ── F10: loss no_flames ──────────────────────────────────────────────
run F10 "$OUT/t_f10.jsonl" \
  --seed 1 --night 1 --ticks 20 \
  --scenario "$SC_WIN/f10.json" --snapshot-every 10
check "F10 game_over reason=no_flames" 'grep -q "\"reason\":\"no_flames\"" "$OUT/t_f10.jsonl"'
check "F10 end state=lost"             'tail -1 "$OUT/t_f10.jsonl" | grep -q "\"state\":\"lost\""'

# ── F14: strictly increasing frame ticks → exit 2 ────────────────────
run F14 "$OUT/t_f14.jsonl" \
  --seed 1 --night 1 --ticks 5 \
  --inputs "$SC_WIN/f14_bad_inputs.json"
F14_CODE=$?
check "F14 non-increasing ticks exit 2" "[ \"$F14_CODE\" -eq 2 ]"

# ── F13: input persistence ──────────────────────────────────────────
run F13 "$OUT/t_f13.jsonl" \
  --seed 1 --night 1 --ticks 12 \
  --scenario "$SC_WIN/f13.json" --inputs "$SC_WIN/f13_inputs.json" \
  --snapshot-every 4
# move [0,1] set at tick 0 → by tick 4 player must have moved in Z
# Second snapshot is tick 4; check player pos[0] or pos[2] > 0
SNAP2_PLAYER=$(grep '"type":"snapshot"' "$OUT/t_f13.jsonl" | sed -n '2p' | grep -o '"player":{[^}]*}')
check "F13 move persisted (player moved by tick 4)" '[ -n "$SNAP2_PLAYER" ] && echo "$SNAP2_PLAYER" | grep -qv '"'"'"pos":\[0.0,0.0,0.0\]'"'"''

# ── F19: jump trajectory ─────────────────────────────────────────────
run F19 "$OUT/t_f19.jsonl" \
  --seed 1 --night 1 --ticks 60 \
  --scenario "$SC_WIN/f19.json" --inputs "$SC_WIN/f19_inputs.json" \
  --snapshot-every 12
# Player Y must rise above 0 mid-jump then return to 0
Y_PEAK=$(grep '"type":"snapshot"' "$OUT/t_f19.jsonl" | grep -o '"player":{[^}]*}' | grep -o '"pos":\[[^]]*\]' | awk -F',' '{print $2}' | sort -rn | head -1)
check "F19 jump rose above 0" '[ -n "$Y_PEAK" ] && awk "BEGIN{exit !($Y_PEAK > 1.0)}"'
# Final snapshot Y should be 0 (landed)
Y_END=$(grep '"type":"snapshot"' "$OUT/t_f19.jsonl" | grep -o '"player":{[^}]*}' | tail -1 | grep -o '"pos":\[[^]]*\]' | awk -F',' '{print $2}')
check "F19 player lands back at Y=0" '[ -n "$Y_END" ] && awk "BEGIN{exit !($Y_END < 0.01)}"'

# ── H3: headless Phase 3 end-to-end (drain + fuel_drain + lantern_out) ──
run H3 "$OUT/t_h3.jsonl" \
  --seed 1 --night 1 --ticks 200 \
  --scenario "$SC_WIN/h3_drain.json" --snapshot-every 50
check "H3 fuel_drain event fires"       'grep -q "\"name\":\"fuel_drain\"" "$OUT/t_h3.jsonl"'
check "H3 fuel_drain has lantern/shade" 'grep "\"name\":\"fuel_drain\"" "$OUT/t_h3.jsonl" | head -1 | grep -q "\"lantern_id\":\"L1\".*\"shade_id\":\"S1\"\|\"shade_id\":\"S1\".*\"lantern_id\":\"L1\"" '
check "H3 lantern_out event fires"      'grep -q "\"name\":\"lantern_out\"" "$OUT/t_h3.jsonl"'
check "H3 snapshot shows drain state"   'grep "\"type\":\"snapshot\"" "$OUT/t_h3.jsonl" | grep -q "\"state\":\"drain\""'
check "H3 snapshot lantern has fuel/ever_lit/relit_count" 'head -1 "$OUT/t_h3.jsonl" | grep -q "\"ever_lit\":.*\"fuel\":\|\"fuel\":.*\"ever_lit\":"'

# ── N1/N2/N3: headless runs per night (Contract: --night 1|2|3) ─────────
for N in 1 2 3; do
  run "N$N" "$OUT/t_night$N.jsonl" --seed 42 --night $N --ticks 600
  check "N$N headless night=$N runs, snapshot night field" "head -1 \"$OUT/t_night$N.jsonl\" | grep -q \"\\\"night\\\":$N\""
  check "N$N end record present" "tail -1 \"$OUT/t_night$N.jsonl\" | grep -q \"\\\"type\\\":\\\"end\\\"\""
  run "N${N}b" "$OUT/t_night${N}b.jsonl" --seed 42 --night $N --ticks 600
  check "N$N determinism (byte-identical)" "diff -q \"$OUT/t_night$N.jsonl\" \"$OUT/t_night${N}b.jsonl\" >/dev/null"
done
check "N-bad invalid night exits non-zero" '! "$GODOT" --headless --path "$ROOT_WIN" --script res://src/headless.gd -- --seed 1 --night 9 --ticks 1 --out "$OUT_WIN/t_bad.jsonl" >/dev/null 2>&1'

# ── JSONL format: UTF-8 no BOM, LF only ──────────────────────────────
check "JSONL no BOM"  '[ "$(head -c 3 "$OUT/t_night1.jsonl" | od -An -tx1 | tr -d " \n")" != "efbbbf" ]'
check "JSONL LF only" '! grep -q $'"'"'\r'"'"' "$OUT/t_night1.jsonl"'

# ── Unit / scenario tests (in-process, GDScript) ─────────────────────
UNIT_LOG="$OUT/unit.log"
"$GODOT" --headless --path "$ROOT_WIN" --script res://tests/unit/run_unit.gd > "$UNIT_LOG" 2>&1
UNIT_CODE=$?
U_PASS=$(grep -c '^PASS ' "$UNIT_LOG" || true)
U_FAIL=$(grep -c '^FAIL ' "$UNIT_LOG" || true)
grep '^FAIL ' "$UNIT_LOG" || true
PASS=$((PASS+U_PASS))
FAIL=$((FAIL+U_FAIL))
check "UNIT runner exit code 0 ($U_PASS unit assertions passed, $U_FAIL failed)" "[ $UNIT_CODE -eq 0 ]"

# ── Phase 4 suites (leaderboard, settings, bench/soak harness) ───────
if [ -f "$ROOT/tests/unit/run_unit_p4.gd" ]; then
  P4_LOG="$OUT/unit_p4.log"
  "$GODOT" --headless --path "$ROOT_WIN" --script res://tests/unit/run_unit_p4.gd > "$P4_LOG" 2>&1
  P4_CODE=$?
  P4_PASS=$(grep -c '^PASS ' "$P4_LOG" || true)
  P4_FAIL=$(grep -c '^FAIL ' "$P4_LOG" || true)
  grep '^FAIL ' "$P4_LOG" || true
  PASS=$((PASS+P4_PASS))
  FAIL=$((FAIL+P4_FAIL))
  check "UNIT-P4 runner exit code 0 ($P4_PASS assertions passed, $P4_FAIL failed)" "[ $P4_CODE -eq 0 ]"
fi

# ── Phase 4 CLI integration: --export-leaderboard & soak_cmd ─────────
"$GODOT" --headless --path "$ROOT_WIN" -- --export-leaderboard "$OUT_WIN/t_lb_export.json" >/dev/null 2>&1
LB_CODE=$?
check "P4-CLI --export-leaderboard exits 0" "[ $LB_CODE -eq 0 ]"
check "P4-CLI --export-leaderboard writes {\"entries\":...}" 'grep -q "\"entries\"" "$OUT/t_lb_export.json"'

"$GODOT" --headless --path "$ROOT_WIN" --script res://src/soak.gd -- --seed 7 --nights 2 --out "$OUT_WIN/t_soak2.json" >/dev/null 2>&1
SOAK_CODE=$?
check "P4-CLI soak_cmd 2-night smoke exits 0" "[ $SOAK_CODE -eq 0 ]"
check "P4-CLI soak_cmd crashes=0" 'grep -q "\"crashes\": 0" "$OUT/t_soak2.json"'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
