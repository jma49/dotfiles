# Custom kitty tab bar in the style of craftzdog's tmux status line, in Catppuccin
# Mocha: a rosewater user pill on the left, powerline tabs labelled with their
# directory (active tab yellow), and on the right Claude Code session status
# followed by a surface0 -> surface1 time and host gradient.
# Session status symbols:
#   ✻ needs you   ✗ failed   ✽ running   ✓ done (not yet seen)
# Data comes from the agent-status plugin (~/.claude/dotfiles-plugins/agent-status):
# its hooks write each session's state to STATE_DIR/<session_id>.json, and this
# file checks that directory every second.
# Sounds play here too, since only kitty knows which pane you are looking at:
#   needs you, failed: when you are not on that pane
#   done: when the turn ran longer than LONG_TURN seconds and you are not on that pane

import json
import os
import socket
import subprocess
import sys
import threading
import time

from kitty.boss import get_boss
from kitty.fast_data_types import add_timer, current_focused_os_window_id, remove_timer, wcswidth
from kitty.tab_bar import as_rgb

STATE_DIR = os.path.expanduser("~/.cache/claude-agents")
RESCAN_EVERY = 5  # seconds; reread even when the directory is unchanged, dropping exited sessions
LONG_TURN = 30  # seconds
SOUND_GAP = 2  # seconds; sessions finishing together play one sound
# herdr's own installer uses ~/.local/bin, Homebrew /opt/homebrew/bin; kitty's PATH
# (launched from the Dock) has neither, so look in both
HERDR = next(
    (p for p in (os.path.expanduser("~/.local/bin/herdr"), "/opt/homebrew/bin/herdr") if os.path.exists(p)),
    "herdr",
)

ORDER = ("blocked", "failed", "working", "done")
SYMBOLS = {"blocked": "✻", "failed": "✗", "working": "✽", "done": "✓"}
# Catppuccin Mocha
CRUST, SURFACE0, SURFACE1, SUBTEXT0, TEXT = 0x11111B, 0x313244, 0x45475A, 0xA6ADC8, 0xCDD6F4
ROSEWATER, YELLOW = 0xF5E0DC, 0xF9E2AF
RIGHT_ARROW, LEFT_ARROW = "\ue0b0", "\ue0b2"
USER = os.environ.get("USER", "")
HOST = socket.gethostname().split(".")[0]
COLORS = {"blocked": 0xF9E2AF, "failed": 0xF38BA8, "working": 0x89B4FA, "done": 0xA6E3A1}
SOUNDS = {
    "blocked": "/System/Library/Sounds/Funk.aiff",
    "failed": "/System/Library/Sounds/Basso.aiff",
    "done": "/System/Library/Sounds/Glass.aiff",
}

# Every load of this file (including config reloads) makes a new token; stale
# timers see the token changed and stop working
_TOKEN = object()


def _alive(pid):
    if not pid:
        return True  # no claude pid to check; wait for SessionEnd to delete the file
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except OSError:
        pass
    return True


def load_sessions():
    sessions = {}
    try:
        names = os.listdir(STATE_DIR)
    except OSError:
        return sessions
    for name in names:
        if not name.endswith(".json"):
            continue
        path = os.path.join(STATE_DIR, name)
        try:
            with open(path) as f:
                s = json.load(f)
        except (OSError, ValueError):
            continue
        if not _alive(s.get("pid")):
            try:
                os.remove(path)
            except OSError:
                pass
            continue
        sessions[name[: -len(".json")]] = s
    return sessions


def summarize(sessions, seen):
    """Done and failed sessions stop counting once you have looked at them (seen)."""
    counts = dict.fromkeys(ORDER, 0)
    for sid, s in sessions.items():
        state = s.get("state")
        if state not in counts:
            continue
        if state in ("done", "failed") and (sid, s.get("since")) in seen:
            continue
        counts[state] += 1
    return counts


def sound_for(s, watching):
    """Sound for a session that just entered a new state, or None for silence."""
    state = s.get("state")
    if watching or state not in SOUNDS:
        return None
    if state == "done" and s.get("since", 0) - s.get("started", 0) < LONG_TURN:
        return None
    return SOUNDS[state]


def _play(path):
    def run():
        try:
            subprocess.run(
                ["/usr/bin/afplay", path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
        except OSError:
            pass

    threading.Thread(target=run, daemon=True).start()


def _focused_window_id():
    # current_focused_os_window_id() is 0 while kitty is not in the foreground
    if not current_focused_os_window_id():
        return None
    w = get_boss().active_window
    return w.id if w else None


def _herdr_focused_pane():
    """herdr pane in focus, when the focused kitty window is a herdr client.

    Sessions inside herdr have no kitty window id, so herdr has to say which
    pane you are looking at.
    """
    w = get_boss().active_window
    try:
        procs = w.child.foreground_processes if w else []
    except Exception:
        return None
    if not any(os.path.basename((p.get("cmdline") or [""])[0]) == "herdr" for p in procs):
        return None
    try:
        out = subprocess.run(
            [HERDR, "agent", "list"], capture_output=True, text=True, timeout=0.5
        ).stdout
        agents = json.loads(out)["result"]["agents"]
    except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired):
        return None
    return next((a.get("pane_id") for a in agents if a.get("focused")), None)


def _state():
    # State hangs off sys so it survives config reloads
    st = getattr(sys, "_claude_agents_tab_v3", None)
    if st is None:
        st = {
            "sessions": {}, "seen": set(), "last": {}, "counts": None, "drawn": None,
            "dir_mtime": None, "scanned_at": 0.0, "sound_at": 0.0, "primed": False,
            "token": None, "timer": None,
        }
        sys._claude_agents_tab_v3 = st
    return st


def _on_timer(_timer_id):
    st = _state()
    if st["token"] is not _TOKEN:
        return
    now = time.monotonic()
    try:
        mtime = os.stat(STATE_DIR).st_mtime
    except OSError:
        mtime = None
    if mtime != st["dir_mtime"] or now - st["scanned_at"] >= RESCAN_EVERY:
        st["dir_mtime"], st["scanned_at"] = mtime, now
        st["sessions"] = load_sessions()

    focused = _focused_window_id()
    last, seen = st["last"], st["seen"]
    herdr_pane = ...  # looked up at most once per tick, only when a herdr session needs it
    for sid, s in st["sessions"].items():
        key = (s.get("state"), s.get("since"))
        watching = focused is not None and s.get("window") == focused
        if focused is not None and s.get("pane") and (
            last.get(sid) != key or key[0] in ("done", "failed")
        ):
            if herdr_pane is ...:
                herdr_pane = _herdr_focused_pane()
            watching = s.get("pane") == herdr_pane
        if last.get(sid) != key:
            last[sid] = key
            # States present when kitty starts are not new changes; stay silent
            sound = sound_for(s, watching) if st["primed"] else None
            if sound and now - st["sound_at"] >= SOUND_GAP:
                st["sound_at"] = now
                _play(sound)
        if watching and key[0] in ("done", "failed"):
            seen.add((sid, key[1]))
    for sid in set(last) - set(st["sessions"]):
        del last[sid]
    seen.intersection_update((sid, s.get("since")) for sid, s in st["sessions"].items())

    st["primed"] = True
    st["counts"] = summarize(st["sessions"], seen)
    if st["counts"] != st["drawn"] or time.strftime("%H:%M") != st.get("drawn_minute"):
        for tm in get_boss().all_tab_managers:
            tm.mark_tab_bar_dirty()


def _ensure_started():
    st = _state()
    if st["token"] is _TOKEN:
        return
    st["token"] = _TOKEN
    if st["timer"] is not None:
        try:
            remove_timer(st["timer"])
        except Exception:
            pass
    # The old version polled `claude agents` on a background thread; stop it on reload
    old = getattr(sys, "_claude_agents_tab_v2", None)
    if old is not None:
        old["token"] = None
        if old.get("timer") is not None:
            try:
                remove_timer(old["timer"])
            except Exception:
                pass
        del sys._claude_agents_tab_v2
    st["timer"] = add_timer(_on_timer, 1.0, True)


def _rgb(color):
    try:
        return int(color)
    except TypeError:  # Color in older kitty versions does not support int()
        from kitty.utils import color_as_int

        return color_as_int(color)


def _label(title):
    """Short tab label: herdr's "host: workspace" -> workspace, a path -> its basename."""
    if ": " in title:
        title = title.split(": ", 1)[1]
    if "/" in title and " " not in title:
        title = title.rstrip("/").rsplit("/", 1)[-1] or "/"
    return title


def _tab_bg(tab):
    return YELLOW if tab.is_active else SURFACE0


def _segment(screen, text, fg, bg, bold=False):
    screen.cursor.fg, screen.cursor.bg = as_rgb(fg), as_rgb(bg)
    screen.cursor.bold = bold
    screen.draw(text)
    screen.cursor.bold = False


def _draw_right(draw_data, screen):
    """Claude session status, then the time and host gradient, flush right."""
    st = _state()
    counts = st["counts"]
    st["drawn"] = counts
    st["drawn_minute"] = time.strftime("%H:%M")
    bar_bg = _rgb(draw_data.default_bg)
    status = [(f"{SYMBOLS[k]}{counts[k]}", COLORS[k]) for k in ORDER if counts and counts[k]]
    gradient = [(f" {st['drawn_minute']} ", SUBTEXT0, SURFACE0), (f" {HOST} ", TEXT, SURFACE1)]
    width = sum(wcswidth(text) + 1 for text, _ in status)
    width += sum(wcswidth(text) + 1 for text, _, _ in gradient)
    x = screen.columns - width
    if x <= screen.cursor.x + 1:  # skip when too many tabs leave no room
        return
    screen.cursor.x = x
    for text, color in status:
        _segment(screen, text + " ", color, bar_bg)
    prev_bg = bar_bg
    for text, fg, bg in gradient:
        _segment(screen, LEFT_ARROW, bg, prev_bg)
        _segment(screen, text, fg, bg, bold=bg == SURFACE1)
        prev_bg = bg


def draw_tab(draw_data, screen, tab, before, max_title_length, index, is_last, extra_data):
    _ensure_started()
    bar_bg = _rgb(draw_data.default_bg)
    bg = _tab_bg(tab)
    if index == 1:
        _segment(screen, f" \uf179 {USER} ", CRUST, ROSEWATER, bold=True)
        _segment(screen, RIGHT_ARROW, ROSEWATER, bg)
    label = _label(tab.title)
    room = max(max_title_length - 4, 1)
    if wcswidth(label) > room:
        label = label[: room - 1] + "…"
    fg = CRUST if tab.is_active else SUBTEXT0
    _segment(screen, f" {index} {label} ", fg, bg, bold=tab.is_active)
    next_tab = getattr(extra_data, "next_tab", None)
    _segment(screen, RIGHT_ARROW, bg, _tab_bg(next_tab) if next_tab and not is_last else bar_bg)
    end = screen.cursor.x
    if is_last and not getattr(extra_data, "for_layout", False):
        _draw_right(draw_data, screen)
    return end
