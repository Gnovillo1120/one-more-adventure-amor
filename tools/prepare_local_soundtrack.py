"""Preserve local originals, normalize names and losslessly decode FLAC with FFmpeg.

Requires imageio-ffmpeg, mutagen and numpy (install into .tools/audio_dependencies).
Never uploads recordings. Runtime files are excluded from Git and PCK exports.
"""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/audio_dependencies'))
import imageio_ffmpeg
import numpy as np
from mutagen import File

ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
music = ROOT / 'music'
originals = music / 'originals'
originals.mkdir(parents=True, exist_ok=True)
(music / '.gdignore').touch()
manifest = json.loads((ROOT / 'data/audio_tracks.json').read_text(encoding='utf-8'))
report = {}
loops = {}

def run(*args):
    return subprocess.run([ffmpeg, '-v', 'error', *args], check=True, capture_output=True).stdout

for name, config in manifest['tracks'].items():
    source = originals / config['original_filename']
    initial = music / config['original_filename']
    if not source.exists():
        shutil.copyfile(initial, source)
    target = music / config['file']
    meta = File(source).info
    original_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    if source.suffix.lower() == '.flac':
        if meta.bits_per_sample != 16:
            raise ValueError('Review conversion precision before decoding non-16-bit FLAC')
        run('-y', '-i', str(source), '-map_metadata', '-1', '-c:a', 'pcm_s16le', str(target))
        # Compare decoded PCM, rather than compressed container bytes.
        pcm_hash = run('-i', str(source), '-f', 'hash', '-hash', 'sha256', '-')
        assert pcm_hash == run('-i', str(target), '-f', 'hash', '-hash', 'sha256', '-')
        if initial.exists():
            assert hashlib.sha256(initial.read_bytes()).hexdigest() == original_hash
            initial.unlink()
    else:
        # Remove only the original root filename after its verified archival copy.
        if initial.exists() and initial.name != target.name:
            assert hashlib.sha256(initial.read_bytes()).hexdigest() == original_hash
            initial.unlink()
        shutil.copyfile(source, target)
        assert hashlib.sha256(target.read_bytes()).hexdigest() == original_hash
        pcm_hash = b'unchanged OGG recording'
    # Detect only near-digital silence; recordings themselves are never trimmed.
    pcm = np.frombuffer(run('-i', str(source), '-f', 's16le', '-acodec', 'pcm_s16le', '-'), dtype='<i2')
    frames = pcm.reshape(-1, meta.channels)
    block = max(1, meta.sample_rate // 50)
    usable = frames[:len(frames)//block*block].astype(np.float32).reshape(-1, block*meta.channels)
    rms = np.sqrt(np.mean((usable/32768)**2, axis=1))
    active = np.flatnonzero(rms > 10**(-55/20))
    start = max(0, float(active[0])/50-.05) if len(active) else 0
    end = min(meta.length, float(active[-1]+1)/50+.05) if len(active) else meta.length
    loops[name] = {'loop_start': round(start, 3) if start > .15 else 0,
                   'loop_end': round(end, 3) if meta.length-end > .15 else round(meta.length, 3),
                   'loop_crossfade': .8}
    report[name] = {'original_filename': source.name, 'runtime_filename': target.name,
                    'original_sha256': original_hash, 'runtime_sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
                    'duration_seconds': round(meta.length, 3), 'sample_rate': meta.sample_rate,
                    'channels': meta.channels, 'conversion': 'FFmpeg pcm_s16le; decoded PCM SHA256 identical' if source.suffix=='.flac' else 'byte-identical copy',
                    'loops': loops[name]}

(music / 'tracks.json').write_text(json.dumps(loops, indent=2)+'\n', encoding='utf-8')
(music / 'LOCAL_SOUNDTRACK_MANIFEST.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
credits = '# Local soundtrack credits\n\nRecordings selected and supplied by Guillermo. Artist/title/license metadata was absent from every source. No ownership or redistribution rights are claimed. Do not distribute this overlay until the required rights and credits are supplied.\n\n'
credits += '\n'.join(f'- `{c["original_filename"]}` → `{c["file"]}`: {c["scene"]}.' for c in manifest['tracks'].values())
(music / 'CREDITS.md').write_text(credits+'\n', encoding='utf-8')
print(json.dumps(report, indent=2))
