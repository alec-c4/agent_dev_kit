# Community packs — third-party or experimental skill bundles

Submit packs via pull request. Official stack packs live in `packs/<id>/` at the repo root.

## Submit a pack

1. Copy [`_template/manifest.yaml`](_template/manifest.yaml) to `packs/community/<your-pack-id>/manifest.yaml`
2. Add skills under `skills/<your-skill>/SKILL.md` in this repo
3. Run `./scripts/kit compile` and `./scripts/kit validate`
4. Open a PR — CI must pass

## Install a community pack

After merge:

```bash
./scripts/kit deploy-skills --pack=community/<id> --scope=project
```

(Requires manifest at `packs/community/<id>/manifest.json` after compile.)

Maintainers: list `maintainer` and `docs` URL in the manifest when publishing externally.
