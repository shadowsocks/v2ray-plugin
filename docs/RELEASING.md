# Releasing

This project publishes cross-compiled archives as GitHub Release assets. The
Taskfile builds and packages the binaries. Create the version tag locally;
`task publish` pushes the current branch and tag, then creates the GitHub
Release.

## Prerequisites

- Go 1.26.0 or later, as required by `go.mod`.
- Task 3.54.0 or later ([installation instructions](https://taskfile.dev/docs/installation)).
- Git and either `sha1sum` or `shasum`.
- GitHub CLI authenticated to the repository, for `task publish`.
- UPX is optional. If it is installed, Task uses `upx -9` on Linux and Windows
  targets, including Linux ARM and MIPS. It leaves macOS, FreeBSD, and Linux
  MIPS64 binaries unpacked. UPX does not support current macOS executables or
  FreeBSD/amd64 ([macOS](https://github.com/upx/upx/discussions/931),
  [FreeBSD](https://github.com/upx/upx/discussions/919)).

Run all commands from the repository root.

## Prepare and build

1. Finish and commit the release changes on the release branch. Make sure the
   working tree is clean.
2. Run the project tests:

   ```sh
   go test ./...
   ```

3. Choose a version such as `v1.4.0` (replace `vX.Y.Z` below with that
   version), then create an annotated tag on the release commit:

   ```sh
   VERSION=vX.Y.Z
   git tag -a "$VERSION" -m "$VERSION"
   ```

   The release task gets its version from `git describe --tags`. Build after
   tagging the release commit so the version embedded in the binaries and
   archive names is exactly the tag. If the commit is not tagged, the version
   includes the distance from the nearest tag and the commit hash.
   Confirm that Git selects the intended tag:

   ```sh
   git describe --tags --exact-match
   ```

4. Build the release:

   ```sh
   task release
   ```

   The task clears and recreates `bin/`, then creates 12 `.tar.gz` archives and
   a `SHA1SUMS` manifest there. It leaves temporary binaries in the repository
   root. The archives cover Linux, macOS, Windows, and FreeBSD on amd64 and 386
   (except macOS 386), plus Linux ARM, ARM64, MIPS, and MIPS64 variants. The
   ARMv5, ARMv6, and ARMv7 binaries share one archive; MIPS variants are also
   grouped into archives.

5. Review the generated files and make sure every archive uses the intended
   version:

   ```sh
   ls -lh bin/v2ray-plugin-*.tar.gz
   ```

   The task stops if a build, compression of a supported target, packaging, or
   checksum command fails. If UPX is installed but you do not want to use it,
   override the Task variable:

   ```sh
   task release UPX=true
   ```

## Publish on GitHub

After reviewing the generated archives, run `task publish` from the tagged
release commit. It requires a clean working tree, an authenticated GitHub CLI,
and the complete set of release assets in `bin/`. It pushes the current branch
and tag to `origin`, then creates the GitHub Release with generated release
notes and uploads the archives and checksum manifest:

```sh
task publish
```

The task uses `--verify-tag`; it fails if the tag is not present on GitHub.
