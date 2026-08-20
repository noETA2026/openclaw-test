#!/usr/bin/env python3
"""
使い方:
    python player.py badapple.txt
    python player.py badapple.txt --fps 15
    python player.py badapple.txt --loop
"""
import argparse
import os
import sys
import time

CLEAR = "\x1b[H\x1b[2J\x1b[3J"


def load_frames(path):
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        lines = f.read().splitlines()

    fps_override = None
    if lines and lines[0].startswith("#FPS="):
        try:
            fps_override = float(lines[0].split("=", 1)[1])
        except ValueError:
            pass
        lines = lines[1:]

    frames = []
    current = []
    for line in lines:
        if "SPLIT" in line:
            if current:
                frames.append("\n".join(current))
                current = []
        else:
            current.append(line)
    if current:
        frames.append("\n".join(current))

    return frames, fps_override


def enable_ansi_on_windows():
    if os.name == "nt":
        try:
            import ctypes
            kernel32 = ctypes.windll.kernel32
            handle = kernel32.GetStdHandle(-11)
            mode = ctypes.c_uint32()
            kernel32.GetConsoleMode(handle, ctypes.byref(mode))
            kernel32.SetConsoleMode(handle, mode.value | 0x0004)
        except Exception:
            pass


def play(frames, fps, loop):
    delay = 1.0 / fps if fps > 0 else 0
    out = sys.stdout
    try:
        while True:
            for frame in frames:
                out.write(CLEAR)
                out.write(frame)
                out.write("\n")
                out.flush()
                time.sleep(delay)
            if not loop:
                break
    except KeyboardInterrupt:
        print("\n再生を中断しました。")


def main():
    parser = argparse.ArgumentParser(description="ASCIIアートフレームをターミナルで再生します")
    parser.add_argument("file", help="フレームが入ったテキストファイル")
    parser.add_argument("--fps", type=float, default=None, help="再生フレームレート（未指定ならファイル内の設定 or 15を使用）")
    parser.add_argument("--loop", action="store_true", help="ループ再生する")
    args = parser.parse_args()

    if not os.path.exists(args.file):
        print(f"エラー: {args.file} が見つかりません。", file=sys.stderr)
        sys.exit(1)

    enable_ansi_on_windows()

    frames, fps_in_file = load_frames(args.file)
    if not frames:
        print("エラー: フレームが1つも読み込めませんでした。'SPLIT' を含む区切り行があるか確認してください。", file=sys.stderr)
        sys.exit(1)

    fps = args.fps or fps_in_file or 15
    print(f"{len(frames)} フレームを {fps} FPS で再生します。(Ctrl+Cで停止)")
    time.sleep(1)
    play(frames, fps, args.loop)


if __name__ == "__main__":
    main()
