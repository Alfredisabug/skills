---
name: gitlab-api-manager
description: Manage GitLab resources (Issues, MRs, Pipelines, Releases, Generic Packages, Projects). Prioritize official glab CLI, fallback to REST API v4.
---

# GitLab API Manager SOP

## 🎯 Objectives

Execute operations against GitLab resources across GitLab.com and self-hosted instances.
**Rule**: Prioritize official `glab` CLI; fallback to REST API v4 (`glab api` or `curl`) when CLI commands lack options or hit server-side constraints.

---

## 📋 Execution Steps

### Step 1: Authentication & Context Verification
1. **Verify CLI Authentication**:
   ```bash
   glab auth status
   ```
2. **Retrieve Context (Facts)**:
   ```bash
   glab repo view
   git remote -v
   ```
   Note the Project ID (e.g. `:id` or integer ID) and canonical path.

---

### Step 2: Resource Operations

#### 1. Issues
* **List**: `glab issue list --state <opened|closed|all> --per-page 20`
* **View**: `glab issue view <issue_id> --comments`
* **Create**: `glab issue create --title "<title>" --description "<description>" --label "<label>"`
* **Add Note**: `glab issue note <issue_id> --message "<message>"`
* **Close/Reopen**: `glab issue close <issue_id>` / `glab issue reopen <issue_id>`

#### 2. Merge Requests (MR)
* **List**: `glab mr list --state <opened|closed|merged|all>`
* **Diff/View**: `glab mr diff <mr_id>` / `glab mr view <mr_id>`
* **Create**: `glab mr create --title "<title>" --description "<description>" --target-branch <target> --source-branch <source>`
* **Approve / Merge**: `glab mr approve <mr_id>` / `glab mr merge <mr_id> --auto-merge`

#### 3. CI/CD Pipelines
* **Status / List**: `glab ci status` / `glab ci list --per-page 10`
* **View Job Trace**: `glab ci trace <job_id>`
* **Retry**: `glab ci retry <pipeline_or_job_id>`

#### 4. Releases & Assets
* **List / View**: `glab release list` / `glab release view <tag_name>`
* **Create Release**: `glab release create <tag_name> [<files>...] --name "<name>" --notes "<notes>"`
* **Upload Assets**:
  * Standard: `glab release upload <tag_name> <file>`
  * **Reliable 2-Step Protocol (for binary assets, self-hosted instances, or tags containing slashes)**:
    1. Upload binary to Generic Package Registry (sanitize `<version>` to remove `/`):
       ```bash
       glab api "projects/:id/packages/generic/<package_name>/<sanitized_version>/<file_name>" \
         --method PUT --input "<local_file_path>"
       ```
    2. Link package asset to release (`direct_asset_path` MUST start with `/`):
       ```bash
       glab api "projects/:id/releases/<encoded_tag>/assets/links" --method POST \
         -f name="<file_name>" \
         -f url="https://<gitlab_host>/api/v4/projects/:id/packages/generic/<package_name>/<sanitized_version>/<file_name>" \
         -f direct_asset_path="/<file_name>" \
         -f link_type="package"
       ```
    *Refer to [`git-asset-manager`](../git-asset-manager/SKILL.md) for full asset specifications.*

#### 5. REST API v4 Fallback
* Endpoint root: `/api/v4/` (or `glab api "projects/:id/..."`).
* Path placeholders: `:id`, `:fullpath`, `:branch` auto-resolved by `glab api`.
* URL Encoding: Path components containing `/` (e.g. tag `release/v1.0`) MUST be encoded as `%2F` (e.g. `release%2Fv1.0`).

---

### Step 3: Confirmation & Presentation
1. **Destructive Operations**: Prompt for confirmation before deleting branches/releases or merging MRs.
2. **Structured Output**: Present API output as clean Markdown tables with IID, title, author, status, and direct URLs.

---

## ⚠️ Anti-Confusion & Platform Constraints

GitLab CLI (`glab`) differs significantly from GitHub CLI (`gh`). NEVER mix syntax:
* ❌ NO `--title` in `glab release create` → use `--name` or `-n`.
* ❌ NO `--body` in `glab issue/mr create` → use `--description` or `-d`.
* ❌ NO `--base` / `--head` in MR creation → use `--target-branch` / `--source-branch`.
* ❌ NO `glab issue comment` → use `glab issue note --message "<msg>"`.
* ❌ NO `--clobber` in `glab` (flag does not exist).
* ❌ NO `--limit` → use `--per-page` or `-p`.
* ❌ NO `--state open` → use `--state opened`.
* ❌ NO `glab pr` or `glab run` → use `glab mr` and `glab ci`.
* ❌ NO slashes in generic package version strings (`\A[a-zA-Z0-9\-_.]+\z`).
* ❌ Release asset `direct_asset_path` MUST have a leading slash `/`.
