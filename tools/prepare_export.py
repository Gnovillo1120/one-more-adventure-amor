"""Fetch official Godot 4.7.2 Windows templates without changing editor installs.

Uses HTTP byte ranges to fetch only ZIP metadata and two Windows members when
the official object storage supports ranges. Falls back to the complete TPZ.
"""
from __future__ import annotations

import io
import pathlib
import shutil
import urllib.request
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEST = ROOT / ".tools"
URL = "https://godot-releases.nbg1.your-objectstorage.com/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
MIRROR = "https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
NAMES = ("windows_release_x86_64.exe", "windows_debug_x86_64.exe")


class HTTPRangeFile(io.RawIOBase):
    def __init__(self, url: str):
        self.url = url
        self.position = 0
        request = urllib.request.Request(url, headers={"Range": "bytes=0-0"})
        with urllib.request.urlopen(request, timeout=60) as response:
            content_range = response.headers.get("Content-Range", "")
            if response.status != 206 or not content_range.startswith("bytes "):
                raise OSError("Official storage did not support HTTP byte ranges")
            self.length = int(content_range.rsplit("/", 1)[1])
            response.read(1)
        self.transferred = 1
        print(f"Official archive: {self.length:,} bytes; HTTP ranges supported", flush=True)

    def readable(self):
        return True

    def seekable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=io.SEEK_SET):
        if whence == io.SEEK_SET:
            position = offset
        elif whence == io.SEEK_CUR:
            position = self.position + offset
        elif whence == io.SEEK_END:
            position = self.length + offset
        else:
            raise ValueError("Invalid seek mode")
        if position < 0:
            raise ValueError("Negative seek")
        self.position = position
        return position

    def read(self, size=-1):
        if size is None or size < 0:
            size = self.length - self.position
        size = min(size, self.length - self.position)
        if size <= 0:
            return b""
        start = self.position
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={start}-{start + size - 1}"})
        with urllib.request.urlopen(request, timeout=180) as response:
            expected = f"bytes {start}-{start + size - 1}/{self.length}"
            if response.status != 206 or response.headers.get("Content-Range") != expected:
                raise OSError("Unexpected HTTP range response")
            data = response.read()
        if len(data) != size:
            raise OSError("Incomplete archive range")
        self.position += size
        self.transferred += size
        return data


def extract(archive):
    with zipfile.ZipFile(archive) as package:
        members = {pathlib.PurePosixPath(info.filename).name: info for info in package.infolist()}
        for name in NAMES:
            target = DEST / name
            if target.exists() and target.stat().st_size == members[name].file_size:
                print(f"Already prepared: {name}", flush=True)
                continue
            print(f"Extracting {name}: {members[name].file_size:,} bytes", flush=True)
            temporary = target.with_suffix(".exe.download")
            with package.open(members[name]) as source, temporary.open("wb") as output:
                shutil.copyfileobj(source, output, 1024 * 1024)
            # ZIP reading verifies the member CRC; never replace source photos.
            if temporary.stat().st_size != members[name].file_size:
                raise OSError(f"Template size mismatch: {name}")
            temporary.replace(target)
            print(f"Ready: {target}", flush=True)


def main():
    DEST.mkdir(exist_ok=True)
    for source_name, destination in (("LICENSE.txt", "GODOT_LICENSE.txt"), ("COPYRIGHT.txt", "GODOT_THIRD_PARTY_NOTICES.txt")):
        target = DEST / destination
        if not target.is_file():
            source_url = f"https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/{source_name}"
            with urllib.request.urlopen(source_url, timeout=60) as response:
                target.write_bytes(response.read())
            print(f"License prepared: {destination}", flush=True)
    if all((DEST / name).is_file() and (DEST / name).stat().st_size > 10_000_000 for name in NAMES):
        print("Both local Windows templates already prepared", flush=True)
        return
    remote = None
    for url in (URL, MIRROR):
        try:
            remote = HTTPRangeFile(url)
            break
        except OSError as error:
            print(f"Range endpoint unavailable ({error}); trying official mirror", flush=True)
    if remote is None:
        print("Downloading complete archive from official GitHub mirror", flush=True)
        archive = DEST / "Godot_v4.7.2-stable_export_templates.tpz"
        if not archive.is_file():
            with urllib.request.urlopen(MIRROR, timeout=180) as source, archive.open("wb") as output:
                shutil.copyfileobj(source, output, 1024 * 1024)
        extract(archive)
    else:
        extract(remote)
        print(f"Downloaded {remote.transferred:,} archive bytes total", flush=True)


if __name__ == "__main__":
    main()
