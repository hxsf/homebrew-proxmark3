# Client/firmware split validation

Validated on 2026-09-21, macOS 27 arm64, Homebrew 7.0.4-39-gf00137e.
Proxmark source: `v4.23346`, SHA256
`5d727313d912d8d758365d3528fbf8af7463e5deec23a9bef79f1fab4fd0c66d`.
Upstream Makefiles, platform definitions and flashing scripts are not patched.
The recorded builds ran in a local development fork (`hxsf/proxmark`); the
commands below use the target upstream tap name for maintainers.

## Clients

The CLI and GUI formulae were built from source through Homebrew, using
`--skip-link` to preserve the machine's existing Proxmark installation.
The GUI used QtBase, QtImageFormats and QtSvg 6.11.2; the full `qt` formula was
not installed. Tests are run on the unlinked kegs with `brew test --force`.

The formula tests cover executable startup, the GUI presence/absence flag,
an installed Lua script calculating CRC-16/ARC, dictionaries, host tools and
platform-independent smartcard resources. The GUI additionally decodes WebP
and SVG NDEF images with Qt's offscreen platform. Strict linkage checks cover
both installed clients. Lua, Jansson and Whereami use the upstream vendored
implementations to avoid host-dependent opportunistic linkage.

```sh
brew install --build-from-source --skip-link rfidresearchgroup/proxmark3/proxmark-client rfidresearchgroup/proxmark3/proxmark-client-gui
brew test --force rfidresearchgroup/proxmark3/proxmark-client rfidresearchgroup/proxmark3/proxmark-client-gui
brew linkage --test --strict rfidresearchgroup/proxmark3/proxmark-client rfidresearchgroup/proxmark3/proxmark-client-gui
```

## Firmware

The firmware dependency is the upstream
`rfidresearchgroup/proxmark3/arm-none-eabi-gcc` package, version `13.3-2024.7`
(Arm GNU Toolchain 13.3.Rel1, GCC 13.3.1). It includes its matching binutils and
C library headers. The formulae do not download or stage separate newlib headers
and use only upstream's `CROSS` variable to select the declared toolchain.

The machine already had that SDK installed by the old `hxsf/proxmark` formula.
Both architectures' archive URLs and SHA256 values were checked against the
upstream RRG formula and match. This existing toolchain was preserved.
Homebrew source installations of the firmware formulae used
`--ignore-dependencies --skip-link` to avoid replacing the same-name compiler
solely to change its tap attribution. Thus actual formula build/install/test
logic was exercised, but clean-machine dependency installation was not.

Upstream `recovery/all` and `recovery/install`, followed by the formula tests,
produced these results:

| Firmware | recovery.bin bytes | Build and installation |
| --- | ---: | --- |
| Generic | 439869 | Passed |
| RDV4 | 494897 | Passed |
| PM5 | 356916 | Passed |
| Ultimate | 404979 | Passed |
| Custom, default RDV4 | 494897 | Passed |

These installation checks confirmed `bootrom.elf`, `fullimage.elf` and
`recovery.bin` under each platform-specific directory. Tests check
ELF32/little-endian/ARM headers and nonempty recovery images within the 512 KiB
limit. The installation receipts record no runtime formula dependencies. The
compiler is build-only.

The custom formula's rejection paths were also checked: multiple platforms,
small without Generic, PM5-only extras on another platform, multiple standalone
modes, and a mode combined with `--without-standalone`.

## Deferred and unverified cases

The upstream documented 256 KiB example was tested without changes using Arm's
13.3.Rel1 toolchain:

```sh
make -j4 recovery/all PLATFORM=PM3GENERIC PLATFORM_SIZE=256 STANDALONE= SKIP_HITAG=1 SKIP_FELICA=1
```

It fails the upstream size check: `355777 > 262144`. Upstream documents that the
example may need additional trimming as firmware grows. No additional `small`
preset or upstream feature changes were adopted.

An iCopy-X build was also investigated, but it requires a dedicated upstream
client configuration and is not included in the final package set.

No physical device was flashed. Qt image tests were offscreen, not a native
Cocoa interaction audit. Intel, older macOS versions, HEAD builds, complete
custom-option combinations and GitHub Actions/release publication were not run.
