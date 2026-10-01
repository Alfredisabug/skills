---
name: semantic-release-version
description: Enforce SemVer 2.0.0 bumping across multi-language projects when committing or releasing changes. Detects version constants and manifest files.
---

# Semantic Release Version SOP

Automate and enforce Semantic Versioning (SemVer 2.0.0) consistency across source files and manifests before committing, pushing, or releasing.

---

## 1. Execution Steps

### Step 1: Detect Version Definitions (Sniffing)
Before modifying version numbers, search the workspace for all version definitions using `search_code` or `find_files`:
1. **Source Code Constants**:
   - Python: `APP_VERSION`, `__version__`, `VERSION`
   - C / C++ / Embedded: `FW_VERSION`, `FIRMWARE_VERSION`, `SW_VERSION`, `APP_VERSION_STR`, `VERSION_MAJOR`, `VERSION_MINOR`, `VERSION_PATCH`
   - Go / Rust / TS: `Version`, `VERSION`, `APP_VERSION`
2. **Project Manifests & Configurations**:
   - Python: `pyproject.toml` (`[project] version` or `[tool.poetry] version`), `setup.cfg`, `setup.py`
   - Node.js: `package.json` (`"version"`), `package-lock.json`
   - Rust: `Cargo.toml` (`[package] version`)
   - C/C++: `CMakeLists.txt` (`project(... VERSION ...)`), `Makefile` (`VERSION ?= ...`)
   - Containers / Helm: `Dockerfile`, `Chart.yaml` (`version`, `appVersion`)

### Step 2: Determine Bump Magnitude (SemVer 2.0.0 Rules)
Analyze staged changes (`git diff --staged` or recent code changes):
- **MAJOR (`X.0.0`)**: Breaking changes, removed public APIs, incompatible protocol modifications (signaled by `BREAKING CHANGE:` or `feat!:` / `fix!:`).
- **MINOR (`x.Y.0`)**: Backward-compatible new features (signaled by `feat(...)`), new tools, or non-breaking API additions. Reset PATCH to 0.
- **PATCH (`x.y.Z`)**: Backward-compatible bug fixes (`fix(...)`), performance enhancements (`perf(...)`), internal refactorings (`refactor(...)`), or dependency maintenance.

### Step 3: Atomic Synchronization (No Desync)
1. Atomically update **all** identified version files simultaneously.
2. Verify that secondary version references (e.g. multiple files sharing `APP_VERSION`, or build scripts parsing versions) match the newly bumped version exactly.

### Step 4: Verification & Test Execution
1. Run version consistency tests (e.g. `test_build_script_version_consistency`, `pytest`, or build verification).
2. Ensure no leftover old version strings in target source files.

### Step 5: Append Version Tag to Commit Header
Format the Conventional Commit header with the bumped version tag:
```text
<type>(<scope>): <imperative summary> (vX.Y.Z)
```
Example: `feat(agent): add search_code tool (v1.5.0)`

---

## 2. Hard Constraints & Rules

1. **Strict SemVer Compliance**: Always reset trailing digits when higher digits bump (e.g., `1.4.9` with a `feat` becomes `1.5.0`, NEVER `1.5.9`).
2. **Zero Partial Updates**: Never bump a version constant in one file while leaving another file in the same project outdated.
3. **English Commit Format**: Always include the version in parentheses `(vX.Y.Z)` at the end of the commit summary line when a version bump is performed.
