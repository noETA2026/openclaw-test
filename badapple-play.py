#!/usr/bin/env python3
# Bad Apple ASCII → Console Player (Python)
# Usage: python3 badapple-play.py <frames.txt> [fps]
#
# Frames file: SPLIT-separated ASCII art frames ($ = background)
# Streams to stdout (no Discord). Ctrl+C to stop.

import sys
import time
import os

def main():
    file = sys.argv[1] if len(sys.argv) > 1 else "bad-apple.txt"
    fps = float(sys.argv[2]) if len(sys.argv) > 2 else 15.0

    if not os.path.isfile(file):
        print(f"Usage: python3 badapple-play.py <frames.txt> [fps]", file=sys.stderr)
        sys.exit(1)

    with open(file, "r", encoding="utf-8") as f:
        raw = f.read()

    frames = [f.strip() for f in raw.split("SPLIT") if f.strip()]
    delay = 1.0 / fps

    print(f"Frames: {len(frames)}  FPS: {fps}", file=sys.stderr)
    print("Press Ctrl+C to stop", file=sys.stderr)
    time.sleep(1)

    prev = None
    for frame in frames:
        if frame == prev:
            continue
        prev = frame

        art = frame.replace("$", " ")
        # Clear screen
        os.system("clear" if os.name != "nt" else "cls")
        print(art)
        time.sleep(delay)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nStopped.")
