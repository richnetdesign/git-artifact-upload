# git-artifact-upload

Reusable GitHub Action for uploads across:

- GitHub Actions artifacts (`actions/upload-artifact@v4`)
- Gitea / Forgejo artifacts (`ChristopherHX/gitea-upload-artifact`)
- S3-compatible object storage (AWS S3, SeaweedFS, RustFS-compatible endpoints)

## Usage

Artifact upload (default behavior):

```yaml
- name: Upload artifact
  uses: richnetdesign/git-artifact-upload@v1
  with:
    name: my-artifact
    path: build/output/**
    retention-days: 7
```

S3-compatible upload only:

```yaml
- name: Upload to S3-compatible storage
  uses: richnetdesign/git-artifact-upload@v1
  with:
    upload-target: s3
    name: my-build
    path: |
      build/linux/x64/release/bundle/**
      build/app/outputs/flutter-apk/*.apk
    s3-bucket: ci-artifacts
    s3-prefix: bambu/${{ github.run_number }}/
    s3-endpoint-url: https://s3.example.internal
    s3-region: us-east-1
    s3-access-key-id: ${{ secrets.S3_ACCESS_KEY_ID }}
    s3-secret-access-key: ${{ secrets.S3_SECRET_ACCESS_KEY }}
    s3-force-path-style: true
```

Upload to both artifact store and S3-compatible storage:

```yaml
- name: Upload artifact + S3
  uses: richnetdesign/git-artifact-upload@v1
  with:
    upload-target: both
    name: windows-msix
    path: '**/*.msix'
    retention-days: 7
    s3-bucket: ci-artifacts
    s3-prefix: releases/${{ github.ref_name }}/
    s3-endpoint-url: https://seaweedfs.example.internal
    s3-access-key-id: ${{ secrets.S3_ACCESS_KEY_ID }}
    s3-secret-access-key: ${{ secrets.S3_SECRET_ACCESS_KEY }}
```

## Inputs

Common:

- `name` (required): artifact/logical upload name.
- `path` (required): file/glob path(s); newline-separated patterns supported.
- `upload-target` (optional, default `artifact`): `artifact`, `s3`, `both`.
- `if-no-files-found` (optional, default `warn`): `warn`, `error`, `ignore`.

Artifact-related:

- `retention-days` (optional, default `7`)
- `compression-level` (optional, default `6`, GitHub only)
- `overwrite` (optional, default `false`, GitHub only)
- `include-hidden-files` (optional, default `false`, GitHub only)

S3-related:

- `s3-bucket` (required when `upload-target` is `s3` or `both`)
- `s3-prefix` (optional)
- `s3-endpoint-url` (optional, required for non-AWS S3 services)
- `s3-region` (optional, default `us-east-1`)
- `s3-access-key-id` (optional)
- `s3-secret-access-key` (optional)
- `s3-session-token` (optional)
- `s3-force-path-style` (optional, default `true`)

## Notes

- For SeaweedFS / RustFS-compatible APIs, set `s3-endpoint-url` and keep `s3-force-path-style: true`.
- If `aws` CLI is missing on the runner, this action installs it via `python3 -m pip install --user awscli`.

## Release

1. Commit and push to `main`.
2. Create a tag like `v1.0.0`.
3. Move major tag `v1` to that commit.

Consumers should use `@v1` instead of `@main`.
