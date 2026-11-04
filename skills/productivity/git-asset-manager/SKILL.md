---
name: git-asset-manager
description: Upload, attach, or manage assets for GitHub/GitLab (Release assets, generic packages, Issue/PR/MR attachments). Prioritize official CLIs (gh/glab), fallback to REST APIs.
---

# Git Asset Manager SOP

## 🎯 Objectives

Manage remote Git platform assets on GitHub and GitLab:
1. **Release Binaries**: Binaries, firmware (`.bin`, `.hex`), installer packages, or compressed artifacts.
2. **Issue / PR / MR Attachments**: Logs, reproduction screenshots, and diagnostic documents.

Rule: Prefer official CLI (`gh` / `glab`); fallback to REST APIs when CLI lacks direct feature or hits platform-specific errors.

---

## 📋 Execution Steps

### Step 1: Verification (Facts)
1. Verify target local file existence, exact path, and file size.
2. Determine target platform and repository via `git remote -v` or `glab repo view` / `gh repo view`.
3. Confirm target Tag, Release ID, or Issue/MR IID.

---

### Step 2: Upload by Platform

#### 🐙 1. GitHub Platform

* **Create Release with Assets (Atomic)**:
  ```bash
  gh release create <tag_name> <file_paths...> --title "<title>" --notes "<notes>"
  ```
* **Upload to Existing Release**:
  ```bash
  gh release upload <tag_name> <file_path> [--clobber]
  ```
* **Download / Delete Asset**:
  ```bash
  gh release download <tag_name> -p "<pattern>"
  gh release delete-asset <tag_name> <asset_name> -y
  ```

---

#### 🦊 2. GitLab Platform

##### Method A: Native Release Upload (Standard / Tags without slashes)
* **Create Release with Assets**:
  ```bash
  glab release create <tag_name> <file_paths...> --name "<title>" --notes "<notes>"
  ```
* **Direct Upload to Existing Release**:
  ```bash
  glab release upload <tag_name> <file_path>
  ```

##### Method B: Reliable 2-Step Protocol (Recommended for Self-Hosted GitLab, Binary Files, or Tags with Slashes)
> ⚠️ **Critical Context**:
> 1. `glab release upload` default `/uploads` endpoint often fails with `500 Internal Server Error` on self-hosted GitLab instances for binaries (`.bin`, `.hex`).
> 2. `glab release upload --use-package-registry` automatically passes `<tag_name>` as `package_version`. If the tag contains slashes (e.g., `release/v1.0`), GitLab Generic Package Registry rejects it with `400 {error: package_version is invalid}`.
> 3. Standard resolution: upload directly via Generic Package Registry API with a sanitized version string, then link to the Release.

1. **Upload Binary to Generic Package Registry**:
   * Sanitize version: Strip illegal characters (`/`) so `<sanitized_version>` matches `\A[a-zA-Z0-9\-_.]+\z` (e.g., `release/S1.00B04` → `S1.00B04`).
   ```bash
   glab api "projects/:id/packages/generic/<package_name>/<sanitized_version>/<file_name>" \
     --method PUT --input "<local_file_path>"
   ```
   *Expected response*: `{"message":"201 Created"}`.

2. **Link Package Asset to Release**:
   * URL-encode the tag if it contains slashes (e.g., `release/S1.00B04` → `release%2FS1.00B04`).
   * **Mandatory**: `direct_asset_path` MUST start with a leading slash `/` (e.g., `/<file_name>`).
   ```bash
   glab api "projects/:id/releases/<encoded_tag>/assets/links" --method POST \
     -f name="<file_name>" \
     -f url="https://<gitlab_host>/api/v4/projects/:id/packages/generic/<package_name>/<sanitized_version>/<file_name>" \
     -f direct_asset_path="/<file_name>" \
     -f link_type="package"
   ```

##### Method C: Issue / MR Attachments
* Upload images/logs for markdown embedding:
  ```bash
  glab api "projects/:id/uploads" --form "file=@<local_file_path>"
  ```

---

## ⚠️ Constraints & Boundaries

### Platform CLI Incompatibilities
* ❌ NEVER use `--clobber` in `glab` (GitHub CLI only).
* ❌ NEVER use `--title` for GitLab Release names (`glab` requires `--name` or `-n`).
* ❌ NEVER use `glab upload` (deprecated / non-existent in current glab versions).

### GitLab Generic Package Registry Rules
* `package_name` and `package_version` regex: `\A[a-zA-Z0-9\-_.]+\z`. **NEVER contain slashes `/`**.
* Release asset `direct_asset_path` (filepath) **MUST begin with `/`**.

### Security & Integrity
* Never expose API tokens in console commands or logs.
* Never commit or upload secrets (`.env`, private keys, unsigned test configs).
* Always verify file presence and non-zero size before initiating upload.
