---
name: git-asset-manager
description: Use when the user asks to upload, attach, or manage assets for GitHub/GitLab (Release assets, generic packages, Issue/PR/MR attachments). Prioritizes official CLIs (gh/glab), fallbacks to REST APIs.
---

# Git Asset Manager SOP

## 🎯 Objectives

Manage remote Git platform assets on GitHub and GitLab:
1. **Release Binaries**: Binaries, firmware (`.bin`, `.hex`), installer packages, or compressed artifacts.
2. **Issue / PR / MR Attachments**: Logs, reproduction screenshots, and diagnostic documents.

Rule: Prefer official CLI (`gh` / `glab`); fallback to REST APIs when CLI lacks direct feature or hits platform-specific errors.

---

## 📋 Execution Steps

### Step 1: Verification & Pre-flight (Facts)
1. **Authenticate & Target**:
   - For GitHub: run `gh auth status` and `gh repo view`.
   - For GitLab: run `glab auth status` and `glab repo view`. Note:
     - Target host (if self-hosted, ensure `GITLAB_HOST` or `--hostname <host>` is configured).
     - **Numeric Project ID** (e.g., `id: 12345`), mandatory for release asset linking URLs.
2. **Verify Local Asset**: Confirm file existence, exact path, and non-zero size.
3. **Confirm Target**: Verify target Tag, Release name, or Issue/MR IID.

---

### Step 2: Upload by Platform

#### 🐙 1. GitHub Platform

* **Create Release with Assets (Atomic)**:
  ```bash
  gh release create <tag_name> <file_paths...> --title "<title>" --notes "<notes>" [--draft] [--prerelease]
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
> ⚠️ **Critical Context & Bug Prevention**:
> 1. `glab release upload` default `/uploads` endpoint often fails with `500 Internal Server Error` on self-hosted instances for binaries (`.bin`, `.hex`).
> 2. `glab release upload --use-package-registry` fails with `400 {error: package_version is invalid}` if `<tag_name>` contains slashes (e.g., `release/v1.0`).
> 3. **CRITICAL**: In Step 2, `glab api` substitutes `:id` ONLY in the endpoint URL path, **NOT** inside `-f url="..."` values. You **MUST** use the actual numeric `<project_id>` obtained in Step 1.

1. **Upload Binary to Generic Package Registry**:
   * Sanitize version: Strip slashes (`/`) so `<sanitized_version>` matches `\A[a-zA-Z0-9\-_.]+\z` (e.g., `release/S1.00B04` → `S1.00B04`).
   ```bash
   glab api "projects/:id/packages/generic/<package_name>/<sanitized_version>/<file_name>" \
     --method PUT --input "<local_file_path>"
   ```
   *Expected response*: `{"message":"201 Created"}`.

2. **Link Package Asset to Release**:
   * URL-encode the tag if it contains slashes (e.g., `release/S1.00B04` → `release%2FS1.00B04`).
   * **Mandatory**: `direct_asset_path` MUST start with a leading slash `/` (e.g., `/<file_name>`).
   * **Mandatory**: replace `<project_id>` with the numeric project ID from Step 1 (do NOT write `:id`).
   ```bash
   glab api "projects/:id/releases/<encoded_tag>/assets/links" --method POST \
     -f name="<file_name>" \
     -f url="https://<gitlab_host>/api/v4/projects/<project_id>/packages/generic/<package_name>/<sanitized_version>/<file_name>" \
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
* Never write literal `:id` in payload parameters like `-f url=...`.

### Security & Integrity
* Never expose API tokens in console commands or logs.
* Never commit or upload secrets (`.env`, private keys, unsigned test configs).
* Always verify file presence and non-zero size before initiating upload.
