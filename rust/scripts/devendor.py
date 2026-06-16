#!/usr/bin/env python3
"""
De-workspace the vendored anki crates.

Replaces all `workspace = true` references with actual values from the
original workspace Cargo.toml, making each crate standalone.

Usage: python3 scripts/devendor.py [vendor_dir]
  vendor_dir defaults to ../vendor/anki (relative to script location)

Run after vendor.sh to make the vendored crates buildable.
"""

import os
import re
import shutil
import sys


def parse_workspace(ws_path: str) -> tuple[dict[str, str], dict[str, str]]:
    """Parse [workspace.package] and [workspace.dependencies] from a Cargo.toml."""
    with open(ws_path) as f:
        lines = f.readlines()

    ws_package: dict[str, str] = {}
    ws_deps: dict[str, str] = {}
    section = None
    table_dep_name = None
    table_val_lines: list[str] = []

    for line in lines:
        s = line.strip()
        if s.startswith('['):
            if table_dep_name is not None:
                val = '\n'.join(table_val_lines).strip()
                if val:
                    ws_deps[table_dep_name] = val
                table_dep_name = None
                table_val_lines = []
            if s == '[workspace.package]':
                section = 'package'
            elif s == '[workspace.dependencies]':
                section = 'deps'
            elif re.match(r'^\[workspace\.dependencies\.([\w-]+)\]$', s):
                section = 'dep_table'
                m = re.match(r'^\[workspace\.dependencies\.([\w-]+)\]$', s)
                table_dep_name = m.group(1) if m else None
                table_val_lines = []
            else:
                section = 'other'
            continue
        if section == 'package':
            m = re.match(r'^([\w-]+)\s*=\s*"([^"]*)"', s)
            if m:
                ws_package[m.group(1)] = m.group(2)
        elif section == 'deps':
            m = re.match(r'^([\w][\w-]*)\s*=\s*(.+)', s)
            if m:
                ws_deps[m.group(1)] = m.group(2).strip()
        elif section == 'dep_table' and table_dep_name:
            table_val_lines.append(s.rstrip())

    if table_dep_name is not None:
        val = '\n'.join(table_val_lines).strip()
        if val:
            ws_deps[table_dep_name] = val

    return ws_package, ws_deps


def fmt_dep(name: str, raw: str) -> str:
    """Format a dep value as a single-line TOML string."""
    v = raw.strip()
    if v.startswith('{') and v.endswith('}'):
        return name + ' = ' + v
    if v.startswith('"'):
        return name + ' = ' + v
    pairs = []
    for line in v.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        m = re.match(r'^(\w[\w-]*)\s*=\s*(.+)', line)
        if m:
            pairs.append(m.group(1) + ' = ' + m.group(2).strip())
    if pairs:
        return name + ' = { ' + ', '.join(pairs) + ' }'
    return name + ' = ' + v


def devendor(crate_path: str, ws_package: dict, ws_deps: dict) -> bool:
    """Patch a Cargo.toml to remove workspace dependencies."""
    filepath = os.path.join(crate_path, 'Cargo.toml')
    if not os.path.exists(filepath):
        return False

    with open(filepath) as f:
        content = f.read()
    original = content

    # 1. Remove workspace = "..."
    content = re.sub(
        r'^\s*workspace\s*=\s*"[^"]*"\s*\n', '', content, flags=re.MULTILINE
    )

    # 2. Package fields
    for key, value in ws_package.items():
        if key in ('version', 'edition', 'license', 'rust-version'):
            content = re.sub(
                r'^' + key + r'\.workspace\s*=\s*true',
                key + ' = "' + value + '"',
                content,
                flags=re.MULTILINE,
            )

    # 3. authors
    content = re.sub(
        r'^authors\.workspace\s*=\s*true',
        'authors = ["Ankitects Pty Ltd and contributors"]',
        content,
        flags=re.MULTILINE,
    )

    # 4. Build inline deps (skip internal path deps)
    skip = {
        'anki', 'anki_i18n', 'anki_io', 'anki_proto',
        'anki_proto_gen', 'anki_process', 'anki_sync', 'anki_linkchecker',
    }
    inline_deps = {}
    for name, raw in ws_deps.items():
        if name not in skip:
            inline_deps[name] = fmt_dep(name, raw)

    # 5. Replace standalone dep.workspace = true
    def repl_standalone(m):
        dep = m.group(1)
        return inline_deps.get(dep, m.group(0))

    content = re.sub(
        r'^(\w[\w-]*)\.workspace\s*=\s*true\s*$',
        repl_standalone,
        content,
        flags=re.MULTILINE,
    )

    # 6. Replace dep = { workspace = true, ... } table form
    def repl_table(m):
        dep = m.group(1)
        after = m.group(2)
        if dep in inline_deps:
            vm = re.search(r'version\s*=\s*"([^"]*)"', inline_deps[dep])
            if vm:
                ver = vm.group(1)
                return dep + ' = { version = "' + ver + '", ' + after.lstrip(', ')
        return m.group(0)

    content = re.sub(
        r'^(\w[\w-]*)\s*=\s*\{\s*workspace\s*=\s*true\s*,?\s*([^}]*)\}',
        repl_table,
        content,
        flags=re.MULTILINE,
    )

    # 7. Internal path deps (relative within vendor/anki/)
    internal_paths = {
        'anki_io': ('rslib', 'io'),
        'anki_proto': ('rslib', 'proto'),
        'anki_proto_gen': ('rslib', 'proto_gen'),
        'anki_i18n': ('rslib', 'i18n'),
    }

    crate_name = os.path.basename(crate_path)
    parent = os.path.basename(os.path.dirname(crate_path))

    # Determine which crate this is
    crate_key = parent + '/' + crate_name if parent != crate_path else crate_name

    for dep, (from_crate, to_path) in internal_paths.items():
        if crate_key == from_crate or crate_path.endswith(from_crate):
            content = re.sub(
                dep + r'\s*=\s*\{\s*path\s*=\s*"[^"]*"([^}]*)\}',
                dep + ' = { path = "' + to_path + '"' + r'\1}',
                content,
            )

    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        return True
    return False


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    vendor_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        script_dir, '..', 'vendor', 'anki'
    )

    # Find the original workspace Cargo.toml
    # Check /tmp/anki-source first, then look for a backup
    sources = ['/tmp/anki-source/Cargo.toml']
    ws_toml = None
    for src in sources:
        if os.path.exists(src):
            ws_toml = src
            break

    if not ws_toml:
        print("ERROR: Cannot find original anki Cargo.toml")
        print("Expected one of:", sources)
        sys.exit(1)

    print("Parsing workspace from:", ws_toml)
    ws_package, ws_deps = parse_workspace(ws_toml)
    print(f"  Package: {ws_package}")
    print(f"  Dependencies: {len(ws_deps)}")

    print("\nDe-workspace patching:")
    crates = [
        'rslib',
        'rslib/i18n',
        'rslib/io',
        'rslib/proto',
        'rslib/proto_gen',
    ]
    for crate in crates:
        crate_path = os.path.join(vendor_dir, crate)
        changed = devendor(crate_path, ws_package, ws_deps)
        print(f"  {'Patched' if changed else 'No change'}: {crate}/Cargo.toml")

    # Apply i18n text_direction_codepoint_in_literal fix
    i18n_lib = os.path.join(vendor_dir, 'rslib/i18n/src/lib.rs')
    if os.path.exists(i18n_lib):
        with open(i18n_lib) as f:
            content = f.read()
        if 'text_direction_codepoint_in_literal' not in content:
            content = content.replace(
                'mod generated;',
                '#![allow(text_direction_codepoint_in_literal)]\nmod generated;',
            )
            with open(i18n_lib, 'w') as f:
                f.write(content)
            print("  Patched: rslib/i18n/src/lib.rs")

    # Manual fixes for known issues
    rslib_toml = os.path.join(vendor_dir, 'rslib/Cargo.toml')
    if os.path.exists(rslib_toml):
        with open(rslib_toml) as f:
            content = f.read()

        fixes = {
            'anki_proto_gen.workspace = true': 'anki_proto_gen = { path = "proto_gen" }',
            'anki_i18n.workspace = true': 'anki_i18n = { path = "i18n" }',
            'anki_io.workspace = true': 'anki_io = { path = "io" }',
            'anki_proto.workspace = true': 'anki_proto = { path = "proto" }',
        }
        for old, new in fixes.items():
            content = content.replace(old, new)

        # Fix unclosed braces in table deps
        content = content.replace(
            'features = ["native-tls"] \nwiremock',
            'features = ["native-tls"] }\nwiremock',
        )
        content = content.replace(
            'optional = true \n\nammonia',
            'optional = true }\n\nammonia',
        )

        with open(rslib_toml, 'w') as f:
            f.write(content)

        # Verify
        remaining = [l for l in content.split('\n') if '.workspace' in l]
        if remaining:
            print("  WARNING: Remaining .workspace refs in rslib/Cargo.toml:")
            for l in remaining:
                print(f"    {l.strip()}")
        else:
            print("  Verified: rslib/Cargo.toml clean")

    print("\nDone! Run 'cargo check -p anki-harmony-wrapper' to verify.")


if __name__ == '__main__':
    main()
