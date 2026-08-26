# Android CI texture hotfix

Godot Android export requires ETC2/ASTC texture imports. On x86_64 Linux the host normally prefers S3TC/BPTC, so Android export can fail with a blank `configuration errors:` message when ETC2/ASTC import is not explicitly enabled.

This hotfix:

- enables `textures/vram_compression/import_etc2_astc=true`;
- explicitly keeps `textures/vram_compression/import_s3tc_bptc=true` for desktop exports;
- removes broad cache fallback so imported texture variants from an older project configuration are not restored;
- adds CI assertions for both texture settings before import/export.
