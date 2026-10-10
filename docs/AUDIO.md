# Original score and pixel art

Run `python tools/generate_audio.py` and `python tools/generate_sprites.py` from the project root to reproduce these assets. Both scripts use deterministic synthesis and handcrafted geometry; no third party samples or art are included.

Audio is mono 22,050 Hz signed 16-bit PCM WAV. Six 32-beat themes share an original eight-note motif: `memory`, `date`, `halloween`, `mystery`, `boss`, `beach`. Set their Godot AudioStreamWAV loop mode to forward during playback. A 60 ms fade at both boundaries ensures silent endpoints and prevents loop clicks. These are intentionally simple piano-like synthesized drafts, not recorded piano performances. Eight short cues are `collect`, `interact`, `dialogue`, `swing`, `hit`, `victory`, `step`, and `menu`.

Character sheets are transparent PNG, 128x192 pixels, with 32x48 cells. Columns: idle, walk A, centered walk, walk B. Rows: down, left, right, up. Frame indices are row * 4 + column. Both characters have casual, formal, and Halloween outfit sheets. Use nearest filtering, and keep cell dimensions identical when replacing artwork. The six transparent keepsake icons are 32x32 pixels.

The original HEIC reference files are preserved. No HEIC decoder was installed, so no speculative or lossy reference conversion was performed.
