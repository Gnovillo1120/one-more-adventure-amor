# Targeted polish verification

The invisible-target bug came from target coordinates being independent of object rendering. Each memory target now has a registered prop/actor and aligned interaction area; progression exits are actual doors/gates/arches. Voxel targets likewise register visible geometry. Retained decorative texture references eliminate white-square rendering.

Run Godot --headless --path . --script scripts/<runner>.gd -- --self-test for story_test, persistence_test, chapter_overhaul_test, target_visibility_test and audio_pipeline_test. navigation_test requires no self-test argument. The suites report 503, 231, 161, 255, 12 and 205 checks respectively, zero failures. Memory navigation covers 63 targets; voxel navigation covers 16 destinations. Visibility QA verifies every required phase and completed/restored exit, representation, anchors and interaction radius. Persistence uses isolated actual saves; existing player data is preserved.

Native source and packaged galleries include 25 captures with menu mouse/keyboard and 3D camera rotation checks. Inspect:
- docs/polish_release_screenshots/02_uees.png — accreditation and populated conference.
- docs/polish_release_screenshots/02b_presidencia.png — required chair interaction.
- docs/polish_release_screenshots/03f_diploma.png — visible diploma.
- docs/polish_release_screenshots/04_ikura.png — reservation host and populated restaurant.
- docs/polish_release_screenshots/04b_food.png — food ordering.
- docs/polish_release_screenshots/04e_ikura_exit.png — visible completed exit.

Gold highlights current required objects; cyan rings indicate optional conversations. Decorative props have no interaction marker. Screenshots/builds are local ignored artifacts. Native rendering on RTX 3070 confirms presentation, not older-laptop performance or a human full playthrough. Music QA verifies mechanics with silent fixtures, not recording quality.
