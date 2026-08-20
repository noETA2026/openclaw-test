#!/bin/bash
# Bad Apple ASCII → Console Player (bash)
# Usage: ./badapple-play.sh <frames.txt> [fps]
#
# Frames file: SPLIT-separated ASCII art frames ($ = background)
# Streams to stdout (no Discord). Ctrl+C to stop.

FILE="${1:-bad-apple.txt}"
FPS="${2:-15}"

if [ ! -f "$FILE" ]; then
  echo "Usage: ./badapple-play.sh <frames.txt> [fps]" >&2
  exit 1
fi

DELAY=$(awk "BEGIN{printf \"%.3f\", 1/$FPS}")

# Count frames (SPLIT-separated, non-empty)
TOTAL=$(awk 'BEGIN{RS="SPLIT"} {sub(/[ \t\r\n]+$/,""); if (length($0) > 0) c++} END{print c+0}' "$FILE")
echo "Frames: $TOTAL  FPS: $FPS" >&2
echo "Press Ctrl+C to stop" >&2
sleep 1

# Stream each frame to stdout, separated by NUL to preserve multi-line frames
awk 'BEGIN{RS="SPLIT"} {sub(/[ \t\r\n]+$/,""); if (length($0) > 0) printf "%s\0", $0}' "$FILE" | \
while IFS= read -r -d '' frame; do
  # Replace $ with space
  art="${frame//\$/ }"

  clear
  printf '%s\n' "$art"
  sleep "$DELAY"
done
