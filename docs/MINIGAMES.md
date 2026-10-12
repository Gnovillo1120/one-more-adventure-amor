# Interactive memory challenges

Branch: `feature/interactive-memory-minigames`, based on Claude's `9d5a754`. No changes to Claude's voxel world, characters, style or shaders. Memory chapters stay 2D with existing pixel portraits/sprites and nearest filtering.

## Gameplay and data

- MUN: five exchanges, 0/1/2 points each, pass at 7/10. Four strong responses suffice; three strong plus one partial also suffice. Assessment rewards economic mechanisms, evidence and diplomatic proposals, not political allegiance. Failure retries only the debate. `data/mun_debate.json` contains choices, assessment and sources.
- Ikura: select all three dishes before submission. Only `[gyozas, ramen, sushi]` passes. Illustrated food cards and Q/W/R category shortcuts; retry clears only the current order.
- Guillermo: ten supplied personal questions, answers A/D/D/B/B/C/B/B/C/E. Q1–9 have four choices; Q10 has five. Score 8 or higher passes. Explicit animated Hard Mode screen before Q8. `data/guillermo_quiz.json` supports optional per-question image paths. The historical conversations remain ordinary dialogue. Old quiz templates are preserved as unused historical files.
- Cookies: one continuous kitchen, with optional pantry/mixing/fridge/oven interactions. Thirteen ingredients include distinct dough sugar and topping sugar. Five quantities and six major preparation decisions; chilling and oven come before the final shaping decision. Timers are compressed. Every completed batch advances and awards the chapter keepsake.

## Scoring and presentation contract

`scripts/memory_challenge_session.gd` is a serializable RefCounted state machine with no UI dependencies. `setup(kind, config, saved)` restores a session. `act(identifier, value)` validates phase and makes semantic actions; false means no change. Cookies use `ingredient`, `gather`, `measure`, `prepare`, `chill`, `temperature`, `minutes`. This contract can drive future walking/pouring/mixing/tray animations without rewriting recipe evaluation. The view emits `action_performed(id, value)` after accepted actions, plus `reaction` and `completed` signals.

The recipe JSON holds numeric quantities with explicit units, all fourteen reference steps and weights. Deterministic score: ingredients 25 (correct selections minus distractors, floor zero), five measurements 25, six preparation decisions 20, at least 60 minutes chill 10, 190 °C 10, 8–10 minutes bake 10. Round once and clamp 0–100. Golden/uneven/chaotic tint tiers and affectionate reactions are presentation only. A poor batch is never a failure state.

`memory_challenge_view.gd` builds color-specific, scrollable containers, dynamic wrapped answer heights, variable choice counts, food illustration cards, pantry toggles and result particles. Mouse, Tab/arrows, Enter/Space and number keys work. Pantry Enter gathers; Space toggles the focused ingredient. The game intercepts challenge shortcuts before native Buttons consume them. Existing pause/settings UI suspends the active view.

## Save compatibility

The additive v1 save keeps old top-level fields. Per-scene `challenge_sessions`, `active_challenge`, `successful_challenges` retain phase, answers, selections, score and feedback. Exploration step, optional seen list and seated pose remain intact. Scene/target/closing dialogue checkpoints store lines and index with a semantic continuation identifier; callbacks are reconstructed, never serialized. A passed result remains a checkpoint until closing dialogue completes. Restart Chapter intentionally erases that chapter's local objectives, as before.

Legacy second-cookie scene index is clamped to the sole kitchen scene; completed legacy saves remain completed. Older incomplete cookie sessions begin the new recipe; their former three-question baking answers have no equivalent scoring contract. The old restaurant's per-dish progress does not imply a valid submitted three-dish order, so incomplete legacy orders start the new order challenge when interacting.

## Factual references

No historical UN statistics are fabricated. Conservative debate mechanisms were checked against [FAO's Ukraine agricultural-market analysis](https://www.fao.org/new-york/news/news-detail/Conflict-in-Ukraine-likely-to-impact-global-agricultural-markets-and-food-security/en) and [WFP's Global Report on Food Crises summary](https://www.wfp.org/news/global-report-food-crises-number-people-facing-acute-food-insecurity-rose-258-million-58). The encounter is explicitly a romantic playable dramatization. Guillermo facts are supplied by the user, not external biography.

## Validation and release

Run Godot 4.7.2 with `--headless --path . --script scripts/memory_minigames_test.gd -- --self-test`. The tests cover all 216 possible dish combinations, every debate option, all quiz totals and answer keys, Hard Mode gating, ideal/poor baking, penalties, challenge save round trips, retries and progression. Existing story, persistence, navigation, visibility, chapter, audio and room/phone tests remain applicable.

Actual native captures: `docs/minigames/screenshots/`, generated by `--capture-minigames`; includes each challenge, fifth choice, Hard Mode, kitchen, cookie results and Claude's 3D world. The capture also sends real native mouse and keyboard events. All capture/test paths isolate player saves.

Known remaining production limitations inherited from the project: final licensed instrumental recordings and personal letter still need the user's content. Kitchen actions currently use the semantic decision UI and simple feedback; elaborate character pouring/oven/tasting choreography is a future presentation replacement. Human pacing and lower-end laptop performance need playtesting.
