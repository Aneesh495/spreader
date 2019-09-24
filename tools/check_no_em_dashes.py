#!/usr/bin/env python3
"""
Lint check: ensure no em dashes (U+2014) or en dashes (U+2013) exist in the repository.
"""
import os
import sys

FORBIDDEN_CHARS = {
    '\u2014': 'EM DASH (U+2014)',
    '\u2013': 'EN DASH (U+2013)',
}

IGNORED_DIRS = {
    '.git',
    'build',
    '.zig-cache',
    '__pycache__',
    'node_modules',
    'dist',
    '.flix',
}

IGNORED_EXTENSIONS = {
    '.jar',
    '.fpkg',
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.ico',
    '.pdf',
    '.tar',
    '.gz',
    '.zip',
    '.class',
    '.o',
    '.so',
    '.dylib',
    '.a',
}

def scan_file(filepath):
    errors = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            for line_no, line in enumerate(f, 1):
                for char, name in FORBIDDEN_CHARS.items():
                    if char in line:
                        errors.append((line_no, name, line.strip()))
    except Exception as e:
        print(f"Warning: could not read {filepath}: {e}", file=sys.stderr)
    return errors

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    total_violations = 0

    for root, dirs, files in os.walk(repo_root):
        dirs[:] = [d for d in dirs if d not in IGNORED_DIRS]
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext in IGNORED_EXTENSIONS:
                continue
            filepath = os.path.join(root, file)
            # Skip checking this script itself for string literals
            if os.path.abspath(filepath) == os.path.abspath(__file__):
                continue
            violations = scan_file(filepath)
            if violations:
                rel_path = os.path.relpath(filepath, repo_root)
                for line_no, name, sample in violations:
                    print(f"Violation in {rel_path}:{line_no}: Found {name}")
                    print(f"  > {sample}")
                    total_violations += 1

    if total_violations > 0:
        print(f"\nFailed: {total_violations} forbidden dash character(s) detected.", file=sys.stderr)
        sys.exit(1)
    else:
        print("Lint passed: 0 forbidden dash characters found across the repository.")
        sys.exit(0)

if __name__ == '__main__':
    main()
