#!/usr/bin/env bash
#
# Render committed draw.io XML sources for the Sphinx build.
#
# Diagram sources are committed as uncompressed draw.io XML; the rendered
# images are build artefacts and are not committed.
#
# Both SVG and PDF are produced from each source. Referencing a figure
# without an extension lets Sphinx pick the format each builder supports:
# SVG for HTML, PDF for LaTeX.
#
#     .. image:: /build/generated/secure-bootflow.drawio.*
#
# The script is idempotent and incremental: a diagram is only re-rendered
# when its source is newer than the output.
#
# Usage:
#   scripts/drawio-to-svg.sh [options]
#
#   --src DIR       directory holding *.drawio.xml sources (default: diagrams)
#   --out DIR       directory to write rendered images into (default: build/generated)
#   --formats LIST  space-separated output formats (default: "svg pdf")
#   --force         re-render even if the output is up to date
#   --check         render nothing; exit non-zero if anything is stale or
#                   missing. Intended for CI.
#   --embed         embed the diagram source in the SVG, keeping it editable
#                   in draw.io at the cost of file size
#   -h, --help      this text
#
# Requires the draw.io desktop CLI ("drawio") and, when no X display is
# available, xvfb-run.

set -euo pipefail

SRC_DIR="diagrams"
OUT_DIR="build/generated"
FORMATS="svg pdf"
FORCE=0
CHECK=0
EMBED=0

PROG="$(basename "$0")"

die()  { printf '%s: error: %s\n' "$PROG" "$*" >&2; exit 1; }
warn() { printf '%s: warning: %s\n' "$PROG" "$*" >&2; }
info() { printf '%s: %s\n' "$PROG" "$*"; }

usage() { sed -n '2,/^set -euo/p' "$0" | sed 's/^#\{1,2\} \{0,1\}//; $d'; exit 0; }

while [ $# -gt 0 ]; do
    case "$1" in
        --src)     SRC_DIR="${2:?--src needs a directory}"; shift 2 ;;
        --out)     OUT_DIR="${2:?--out needs a directory}"; shift 2 ;;
        --formats) FORMATS="${2:?--formats needs a list}"; shift 2 ;;
        --force)   FORCE=1; shift ;;
        --check)   CHECK=1; shift ;;
        --embed)   EMBED=1; shift ;;
        -h|--help) usage ;;
        *) die "unknown argument '$1' (try --help)" ;;
    esac
done

[ -d "$SRC_DIR" ] || die "source directory '$SRC_DIR' does not exist"

for fmt in $FORMATS; do
    case "$fmt" in
        svg|pdf|png) ;;
        *) die "unsupported format '$fmt' (svg, pdf, png)" ;;
    esac
done

# ---------------------------------------------------------------------------
# Collect sources
# ---------------------------------------------------------------------------

sources=()
while IFS= read -r -d '' f; do
    sources+=("$f")
done < <(find "$SRC_DIR" -type f \( -name '*.drawio.xml' -o -name '*.drawio' \) -print0 | sort -z)

if [ ${#sources[@]} -eq 0 ]; then
    info "no diagram sources under '$SRC_DIR', nothing to do"
    exit 0
fi

# Outputs keep the ".drawio" part of the name, so that pdfs or svgs
# added by hand in the images/ directory are not automatically cleaned
# by the Makefile and ignored by the repo. e.g.:
# diagrams/foo.drawio.xml -> images/foo.drawio.svg, images/foo.drawio.pdf
stem_for() {
    local base
    base="$(basename "$1")"
    base="${base%.xml}"
    printf '%s' "$base"
}

# ---------------------------------------------------------------------------
# Work out what is stale. A source is stale if any of its outputs is
# missing, empty, or older than the source.
# ---------------------------------------------------------------------------

stale=()
missing=()
for src in "${sources[@]}"; do
    stem="$(stem_for "$src")"
    for fmt in $FORMATS; do
        out="$OUT_DIR/$stem.$fmt"
        if [ "$FORCE" -eq 1 ] || [ ! -s "$out" ] || [ "$src" -nt "$out" ]; then
            stale+=("$src")
            missing+=("$out")
            break
        fi
    done
done

if [ "$CHECK" -eq 1 ]; then
    if [ ${#stale[@]} -eq 0 ]; then
        info "all ${#sources[@]} diagram(s) up to date"
        exit 0
    fi
    printf '%s: stale or missing:\n' "$PROG" >&2
    printf '  %s\n' "${missing[@]}" >&2
    exit 1
fi

if [ ${#stale[@]} -eq 0 ]; then
    info "all ${#sources[@]} diagram(s) up to date"
    exit 0
fi

# ---------------------------------------------------------------------------
# Locate the renderer
# ---------------------------------------------------------------------------

DRAWIO="${DRAWIO:-drawio}"
command -v "$DRAWIO" >/dev/null 2>&1 || die \
"'$DRAWIO' not found on PATH.

Install the draw.io desktop CLI, or set DRAWIO to its location:

  Debian/Ubuntu:  download the .deb from
                  https://github.com/jgraph/drawio-desktop/releases
  Arch:           pacman -S drawio-desktop
  macOS:          brew install --cask drawio

The rendered images are build artefacts, so a checkout without draw.io can
still read the committed XML sources directly."

# Electron needs a display. Fall back to a virtual one when headless.
if [ -n "${DISPLAY:-}" ]; then
    WRAP=()
elif command -v xvfb-run >/dev/null 2>&1; then
    WRAP=(xvfb-run -a)
else
    die "no DISPLAY set and xvfb-run not found; install xvfb for headless rendering"
fi

# Electron refuses to start as root without --no-sandbox, and wants a
# writable HOME for its own config.
export HOME="${HOME:-/tmp}"
export ELECTRON_DISABLE_SECURITY_WARNINGS=1

mkdir -p "$OUT_DIR"

# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------

failed=0
count=0

for src in "${stale[@]}"; do
    stem="$(stem_for "$src")"

    # drawio exports one page per invocation; warn rather than silently
    # dropping the rest.
    pages="$(grep -c '<diagram[ >]' "$src" || true)"
    if [ "${pages:-1}" -gt 1 ]; then
        warn "'$src' has $pages pages; only the first is exported"
    fi

    for fmt in $FORMATS; do
        out="$OUT_DIR/$stem.$fmt"

        args=(--export --format "$fmt" --border 10 --no-sandbox)
        case "$fmt" in
            svg)
                args+=(--svg-theme light)
                [ "$EMBED" -eq 1 ] && args+=(--embed-diagram)
                ;;
            pdf)
                # Without --crop the diagram is padded out to a full page.
                args+=(--crop)
                ;;
            png)
                args+=(--scale 2)
                ;;
        esac

        info "rendering $src -> $out"

        if ! "${WRAP[@]}" "$DRAWIO" "${args[@]}" --output "$out" "$src" >/dev/null 2>&1; then
            warn "draw.io failed on '$src' ($fmt)"
            failed=1
            continue
        fi

        # drawio has been known to exit 0 without producing anything.
        if [ ! -s "$out" ]; then
            warn "draw.io produced no output for '$src' ($fmt)"
            failed=1
            continue
        fi

        count=$((count + 1))
    done
done

[ "$failed" -eq 0 ] || die "one or more diagrams failed to render"

info "rendered $count file(s) into '$OUT_DIR'"
