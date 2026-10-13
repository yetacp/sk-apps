"""Validate the source registry and prepare one deterministic release candidate."""

from __future__ import annotations

import hashlib
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "apps.json"
VERSION = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?\Z")
ID = re.compile(r"[a-z0-9]+(?:[.-][a-z0-9]+)+\Z")


def fail(message: str) -> None:
    raise SystemExit(f"app-release: {message}")


def manifest_fields(path: pathlib.Path) -> dict[str, str]:
    fields: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("["):
            break
        match = re.fullmatch(r'(id|version) = "([^"]+)"', line)
        if match:
            if match[1] in fields:
                fail(f"duplicate {match[1]} in {path}")
            fields[match[1]] = match[2]
    return fields


def registry() -> dict[str, dict[str, str]]:
    data = json.loads(REGISTRY.read_text(encoding="utf-8"))
    if set(data) != {"schema", "apps"} or data["schema"] != 1 or not isinstance(data["apps"], list):
        fail("unsupported registry schema")
    entries: dict[str, dict[str, str]] = {}
    ids: set[str] = set()
    for item in data["apps"]:
        if not isinstance(item, dict) or set(item) != {"path", "id", "version"}:
            fail("invalid registry entry")
        name, app_id, version = item["path"], item["id"], item["version"]
        if not isinstance(name, str) or not re.fullmatch(r"[a-z][a-z0-9-]*", name):
            fail("invalid app path")
        if not isinstance(app_id, str) or not ID.fullmatch(app_id):
            fail(f"invalid app ID for {name}")
        if not isinstance(version, str) or not VERSION.fullmatch(version):
            fail(f"invalid version for {name}")
        if name in entries or app_id in ids:
            fail("duplicate app path or ID")
        directory = ROOT / name
        if directory.is_symlink() or not directory.is_dir():
            fail(f"invalid app directory: {name}")
        manifest = directory / "manifest.stk"
        if manifest.is_symlink() or not manifest.is_file():
            fail(f"missing manifest: {name}")
        if manifest_fields(manifest) != {"id": app_id, "version": version}:
            fail(f"registry disagrees with manifest: {name}")
        entries[name] = item
        ids.add(app_id)
    directories = {p.name for p in ROOT.iterdir() if p.is_dir() and (p / "manifest.stk").exists()}
    if directories != set(entries):
        fail(f"registry does not match app directories: {sorted(directories ^ set(entries))}")
    return entries


def prepare(name: str, entries: dict[str, dict[str, str]]) -> None:
    if name not in entries:
        fail(f"unknown app: {name}")
    item = entries[name]
    source = ROOT / "dist" / f"{name}.stkp"
    if not source.is_file():
        fail(f"package missing: {source}")
    contents = source.read_bytes()
    if not contents:
        fail("empty package")
    stem = f"{item['id']}-v{item['version']}"
    artifact = ROOT / "dist" / f"{stem}.stkp"
    metadata = ROOT / "dist" / f"{stem}.json"
    digest = hashlib.sha256(contents).hexdigest()
    record = {
        "schema": 1,
        "id": item["id"],
        "version": item["version"],
        "asset": artifact.name,
        "size": len(contents),
        "sha256": digest,
    }
    encoded = (json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n").encode()
    if artifact.exists() and artifact.read_bytes() != contents:
        fail(f"release version already has different bytes: {artifact.name}")
    if metadata.exists() and metadata.read_bytes() != encoded:
        fail(f"release metadata already differs: {metadata.name}")
    artifact.write_bytes(contents)
    metadata.write_bytes(encoded)
    print(f"prepared {artifact.name} sha256={digest}")


def catalog(revision: str, entries: dict[str, dict[str, str]]) -> None:
    if not re.fullmatch(r"[1-9][0-9]*", revision):
        fail("catalog revision must be a positive integer")
    private_key = ROOT / ".release" / "ed25519.pem"
    if not private_key.is_file():
        fail("private signing key missing: .release/ed25519.pem")
    public_der = subprocess.run(
        ["openssl", "pkey", "-in", str(private_key), "-pubout", "-outform", "DER"],
        check=True, capture_output=True,
    ).stdout
    expected_key = (ROOT / "../startk/src/crates/startkd/src/catalog-public-key.hex").read_text().strip()
    if len(public_der) != 44 or public_der[-32:].hex() != expected_key:
        fail("signing key does not match StartK public key")
    published = []
    for app in entries.values():
        stem = f"{app['id']}-v{app['version']}"
        metadata_path = ROOT / "dist" / f"{stem}.json"
        bundle_path = ROOT / "dist" / f"{stem}.stkp"
        if not metadata_path.exists() or not bundle_path.exists():
            continue
        metadata = json.loads(metadata_path.read_text())
        contents = bundle_path.read_bytes()
        if (metadata.get("id") != app["id"] or metadata.get("version") != app["version"]
                or metadata.get("asset") != bundle_path.name
                or metadata.get("size") != len(contents)
                or metadata.get("sha256") != hashlib.sha256(contents).hexdigest()):
            fail(f"release metadata disagrees with bundle: {stem}")
        published.append({
            "path": app["path"], "id": app["id"], "version": app["version"],
            "url": f"https://github.com/yetacp/sk-apps/releases/download/{stem}/{stem}.stkp",
            "size": len(contents), "sha256": metadata["sha256"],
        })
    if not published:
        fail("no prepared app releases")
    published.sort(key=lambda app: app["id"])
    output = ROOT / "dist" / f"catalog-v{revision}"
    output.mkdir(parents=True, exist_ok=True)
    encoded = (json.dumps({"schema": 1, "revision": int(revision), "apps": published},
                          sort_keys=True, separators=(",", ":")) + "\n").encode()
    catalog_path = output / "catalog.json"
    signature_path = output / "catalog.json.sig"
    if catalog_path.exists() and catalog_path.read_bytes() != encoded:
        fail("catalog revision already has different bytes")
    catalog_path.write_bytes(encoded)
    if not signature_path.exists():
        subprocess.run(["openssl", "pkeyutl", "-sign", "-rawin", "-inkey", str(private_key),
                        "-in", str(catalog_path), "-out", str(signature_path)], check=True)
    if len(signature_path.read_bytes()) != 64:
        fail("invalid Ed25519 catalog signature")
    print(f"prepared catalog-v{revision} with {len(published)} apps")


if __name__ == "__main__":
    if len(sys.argv) not in (2, 3) or sys.argv[1] not in {"check", "prepare", "catalog", "tag"}:
        fail("usage: release_app.py check | prepare APP | catalog REVISION | tag APP")
    entries = registry()
    if sys.argv[1] == "prepare":
        if len(sys.argv) != 3:
            fail("APP is required")
        prepare(sys.argv[2], entries)
    elif sys.argv[1] == "catalog":
        if len(sys.argv) != 3:
            fail("REVISION is required")
        catalog(sys.argv[2], entries)
    elif sys.argv[1] == "tag":
        if len(sys.argv) != 3 or sys.argv[2] not in entries:
            fail("known APP is required")
        app = entries[sys.argv[2]]
        print(f"{app['id']}-v{app['version']}")
    elif len(sys.argv) != 2:
        fail("check takes no app")
    else:
        print(f"ok - {len(entries)} apps registered")
