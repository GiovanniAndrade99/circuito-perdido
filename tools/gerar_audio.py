"""
Gerador de áudio (efeitos sonoros e trilhas chiptune) do Circuito Perdido.
Responsável: Carlos Eduardo Peraçolli

Todo o áudio é sintetizado aqui (ondas quadrada, triangular e ruído), no
estilo dos consoles 8-bit. Nenhum som de terceiros é utilizado.

Uso:  python tools/gerar_audio.py   (executar na raiz do projeto)
Saída: assets/audio/sfx/*.wav e assets/audio/music/*.wav (16-bit, mono)
"""
import math
import os
import random
import struct
import wave

RATE = 22050
BASE = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
random.seed(42)  # resultado determinístico


# ----------------------------------------------------------------------------
# Osciladores e envelopes
# ----------------------------------------------------------------------------
def osc(kind, phase, duty=0.5):
    p = phase % 1.0
    if kind == "square":
        return 1.0 if p < duty else -1.0
    if kind == "triangle":
        return 4.0 * p - 1.0 if p < 0.5 else 3.0 - 4.0 * p
    if kind == "saw":
        return 2.0 * p - 1.0
    if kind == "sine":
        return math.sin(2 * math.pi * p)
    return random.uniform(-1.0, 1.0)  # noise


def tone(f0, f1, dur, kind="square", vol=0.5, duty=0.5, attack=0.005, release=0.05, vibrato=0.0):
    """Gera um tom com varredura de frequência f0 -> f1 (exponencial)."""
    n = int(dur * RATE)
    out = []
    phase = 0.0
    noise_val, noise_counter = 0.0, 0
    for i in range(n):
        t = i / n
        f = f0 * (f1 / f0) ** t if f0 > 0 and f1 > 0 else f0
        if vibrato:
            f *= 1.0 + 0.01 * vibrato * math.sin(2 * math.pi * 6 * i / RATE)
        phase += f / RATE
        if kind == "noise":
            # ruído "amostrado" na frequência f para soar mais grave/agudo
            noise_counter += 1
            if noise_counter >= max(1, int(RATE / max(f, 1))):
                noise_counter = 0
                noise_val = random.uniform(-1, 1)
            s = noise_val
        else:
            s = osc(kind, phase, duty)
        env = 1.0
        ti = i / RATE
        if ti < attack:
            env = ti / attack
        rem = (n - i) / RATE
        if rem < release:
            env *= rem / release
        out.append(s * vol * env)
    return out


def decay(samples, power=1.5):
    n = len(samples)
    return [s * (1 - i / n) ** power for i, s in enumerate(samples)]


def concat(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    out = [0.0] * n
    for p in parts:
        for i, s in enumerate(p):
            out[i] += s
    return out


def silence(dur):
    return [0.0] * int(dur * RATE)


def save(path, samples, gain=0.9):
    peak = max(1e-6, max(abs(s) for s in samples))
    k = gain / peak if peak > gain else 1.0
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * k)) * 32767)) for s in samples))


def note_freq(name):
    """'A4' -> 440 Hz; aceita sustenido: 'C#5'."""
    names = {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4, "F#": -3,
             "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2}
    pitch, octave = name[:-1], int(name[-1])
    semis = names[pitch] + (octave - 4) * 12
    return 440.0 * 2 ** (semis / 12)


# ----------------------------------------------------------------------------
# Efeitos sonoros
# ----------------------------------------------------------------------------
def build_sfx():
    d = os.path.join(BASE, "sfx")
    sfx = {
        "jump": tone(260, 620, 0.14, "square", 0.45, duty=0.25),
        "land": decay(tone(180, 60, 0.07, "noise", 0.4)),
        "shoot": tone(1200, 380, 0.11, "square", 0.35, duty=0.125),
        "hit": decay(mix(tone(300, 80, 0.12, "noise", 0.5), tone(220, 90, 0.12, "square", 0.3))),
        "hurt": concat(tone(520, 200, 0.18, "square", 0.45, duty=0.5)),
        "death": concat(tone(600, 90, 0.55, "square", 0.45, vibrato=4), decay(tone(400, 60, 0.4, "noise", 0.4))),
        "enemy_death": decay(mix(tone(800, 60, 0.3, "noise", 0.55), tone(300, 50, 0.3, "square", 0.25))),
        "explosion": decay(tone(500, 40, 0.75, "noise", 0.7), 1.2),
        "cell": concat(tone(988, 988, 0.05, "square", 0.3, duty=0.25), tone(1319, 1319, 0.09, "square", 0.3, duty=0.25)),
        "heart": concat(*[tone(note_freq(n), note_freq(n), 0.07, "triangle", 0.5) for n in ("C5", "E5", "G5", "C6")]),
        "core": concat(*[tone(note_freq(n), note_freq(n), 0.09, "square", 0.3, duty=0.25)
                         for n in ("C5", "E5", "G5", "C6", "E6", "G6")], tone(1568, 1568, 0.3, "triangle", 0.5)),
        "checkpoint": concat(*[tone(note_freq(n), note_freq(n), 0.08, "square", 0.3, duty=0.5) for n in ("G4", "C5", "E5")]),
        "portal": tone(200, 1600, 0.6, "triangle", 0.5, vibrato=8),
        "locked": concat(tone(180, 180, 0.08, "square", 0.35), silence(0.04), tone(140, 140, 0.12, "square", 0.35)),
        "ui_click": tone(880, 1200, 0.05, "square", 0.3, duty=0.25),
        "ui_hover": tone(600, 600, 0.025, "square", 0.18, duty=0.25),
        "shield": tone(2400, 1800, 0.06, "triangle", 0.4),
        "press": decay(mix(tone(120, 40, 0.25, "noise", 0.6), tone(90, 40, 0.25, "square", 0.3))),
        "boss_charge": tone(150, 900, 0.6, "saw", 0.35),
        "boss_shoot": tone(700, 200, 0.15, "saw", 0.3),
        "victory": concat(*[tone(note_freq(n), note_freq(n), dur, "square", 0.35, duty=0.5)
                            for n, dur in (("C5", 0.12), ("E5", 0.12), ("G5", 0.12), ("C6", 0.3),
                                           ("A5", 0.12), ("B5", 0.12), ("C6", 0.5))]),
        "game_over": concat(*[tone(note_freq(n), note_freq(n), dur, "triangle", 0.5)
                              for n, dur in (("G4", 0.25), ("E4", 0.25), ("C4", 0.25), ("G3", 0.6))]),
    }
    for name, samples in sfx.items():
        save(os.path.join(d, name + ".wav"), samples, gain=0.8)
    print(f"  {len(sfx)} efeitos sonoros")


# ----------------------------------------------------------------------------
# Mini "tracker" para as trilhas
# ----------------------------------------------------------------------------
CHORDS = {
    "Am": ("A", "C", "E"), "F": ("F", "A", "C"), "C": ("C", "E", "G"), "G": ("G", "B", "D"),
    "E": ("E", "G#", "B"), "Dm": ("D", "F", "A"), "Bb": ("A#", "D", "F"), "Em": ("E", "G", "B"),
    "D": ("D", "F#", "A"), "Gm": ("G", "A#", "D"), "A": ("A", "C#", "E"),
}


def render_track(bpm, chords, melody, lead_kind="square", lead_duty=0.25, arp=True,
                 drum_pattern="k...s...k.k.s...", bass_pattern="x.x.x.x.x.x.x.x.", lead_vol=0.22):
    """
    chords: lista de acordes, 1 por compasso (16 semicolcheias).
    melody: string de notas separadas por espaço, 1 token por semicolcheia:
            'E5' = nota, '-' = sustenta, '.' = pausa.
    """
    step = 60.0 / bpm / 4  # duração de uma semicolcheia
    steps_total = len(chords) * 16
    n_total = int(steps_total * step * RATE)
    out = [0.0] * n_total

    def add(samples, start_step):
        start = int(start_step * step * RATE)
        for i, s in enumerate(samples):
            if start + i < n_total:
                out[start + i] += s

    # baixo + arpejo
    for bar, ch in enumerate(chords):
        root = CHORDS[ch][0]
        for i in range(16):
            s = bar * 16 + i
            if bass_pattern[i] == "x":
                octave_note = root + ("2" if i % 4 == 0 else "3")
                add(tone(note_freq(octave_note), note_freq(octave_note), step * 1.8, "triangle", 0.45, release=0.03), s)
            if arp:
                tone_name = CHORDS[ch][i % 3] + "5"
                add(tone(note_freq(tone_name), note_freq(tone_name), step * 0.9, "square", 0.06, duty=0.125,
                         release=0.02), s)
            dch = drum_pattern[i]
            if dch == "k":
                add(decay(tone(160, 45, 0.12, "sine", 0.6)), s)
            elif dch == "s":
                add(decay(tone(4000, 2000, 0.1, "noise", 0.22)), s)
            elif dch == "h":
                add(decay(tone(9000, 9000, 0.03, "noise", 0.08)), s)

    # melodia
    tokens = melody.split()
    i = 0
    while i < len(tokens) and i < steps_total:
        tok = tokens[i]
        if tok not in ("-", "."):
            length = 1
            while i + length < len(tokens) and tokens[i + length] == "-":
                length += 1
            f = note_freq(tok)
            add(tone(f, f, step * length * 0.95, lead_kind, lead_vol, duty=lead_duty, vibrato=1.5, release=0.04), i)
            i += length
        else:
            i += 1
    return out


def build_music():
    d = os.path.join(BASE, "music")

    # Menu: calmo, misterioso
    menu = render_track(
        96, ["Am", "F", "C", "G", "Am", "F", "G", "E"],
        "A4 - - - C5 - E5 - D5 - - - C5 - B4 - "
        "A4 - - - - - . . F4 - A4 - C5 - - - "
        "E5 - - - D5 - C5 - G4 - - - - - . . "
        "B4 - C5 - D5 - - - G4 - - - B4 - D5 - "
        "A4 - - - C5 - E5 - A5 - - - G5 - E5 - "
        "F5 - - - E5 - C5 - A4 - - - - - . . "
        "D5 - - - B4 - G4 - D5 - E5 - F5 - D5 - "
        "E5 - - - - - - - G#4 - - - B4 - - - ",
        lead_kind="triangle", drum_pattern="k.......s.......", bass_pattern="x.......x.......", lead_vol=0.35)

    # Fases 1-2: animado
    level = render_track(
        132, ["Am", "F", "C", "G", "Am", "F", "G", "G", "F", "G", "Em", "Am", "F", "G", "E", "E"],
        "A4 . C5 . E5 - D5 C5 - . A4 . C5 - D5 . "
        "F5 - - . E5 . C5 . A4 - - . C5 . F5 . "
        "E5 . G5 . E5 - C5 - G4 . C5 . E5 - G5 . "
        "D5 - - . B4 . G4 . B4 . D5 . G5 - - . "
        "A4 . C5 . E5 - D5 C5 - . A4 . C5 - D5 . "
        "F5 - - . A5 . G5 . F5 - E5 . C5 - - . "
        "D5 - . D5 E5 . F5 . G5 - - . F5 . E5 . "
        "D5 - - - B4 - - - G4 - - - . . . . "
        "C5 . F5 . A5 - G5 F5 - . C5 . F5 - A5 . "
        "B4 . D5 . G5 - F5 D5 - . B4 . D5 - G5 . "
        "E5 . G5 . B5 - A5 G5 - . E5 . G5 - B5 . "
        "C6 - - . B5 . A5 . E5 - - . A5 - - . "
        "A5 . G5 . F5 . E5 . F5 - - . C5 - - . "
        "D5 . E5 . F5 . G5 . A5 - - . B5 - - . "
        "G#5 - - - - - E5 - - - B4 - - - E5 - "
        "G#5 - - - B5 - - - E5 - - - . . . . ",
        drum_pattern="k.h.s.h.k.k.s.h.", bass_pattern="x.x.x.x.x.x.x.x.")

    # Fase 3 (Reator): tenso
    reactor = render_track(
        118, ["Dm", "Bb", "Gm", "A", "Dm", "Bb", "Gm", "A"],
        "D5 - - . F5 - - . A5 - G5 - F5 - E5 - "
        "F5 - - - D5 - - - A#4 - - - . . . . "
        "G4 - A#4 - D5 - - . C5 - A#4 - A4 - G4 - "
        "A4 - - - C#5 - - - E5 - - - . . . . "
        "D5 - - . F5 - - . A5 - A#5 - A5 - G5 - "
        "F5 - - - A#5 - - - D6 - - - C6 - A#5 - "
        "A#5 - A5 - G5 - - . A5 - G5 - F5 - E5 - "
        "C#5 - - - - - - - A4 - - - - - . . ",
        lead_duty=0.5, drum_pattern="k...s.h.k.k.s.h.", bass_pattern="x.xxx.xxx.xxx.xx", lead_vol=0.18)

    # Chefe: rápido e agressivo
    boss = render_track(
        156, ["Em", "Em", "C", "D", "Em", "Em", "C", "D"],
        "E5 . E5 . G5 . E5 . B5 - A5 - G5 - F#5 - "
        "E5 . E5 . G5 . B5 . E6 - - - D6 - B5 - "
        "C6 - - . G5 . E5 . C6 - B5 - A5 - G5 - "
        "D6 - - . A5 . F#5 . D6 - C6 - B5 - A5 - "
        "E5 . E5 . G5 . E5 . B5 - A5 - G5 - F#5 - "
        "E5 . G5 . B5 . E6 . G6 - - - F#6 - E6 - "
        "C6 . C6 . E6 . C6 . G5 - A5 - B5 - C6 - "
        "D6 - - - F#6 - - - D6 - - - . . . . ",
        lead_duty=0.5, drum_pattern="k.hsk.hsk.hsk.ss", bass_pattern="xxxxxxxxxxxxxxxx", lead_vol=0.2)

    for name, samples in (("menu", menu), ("level", level), ("reactor", reactor), ("boss", boss)):
        save(os.path.join(d, name + ".wav"), samples, gain=0.7)
        print(f"  trilha {name}.wav ({len(samples) / RATE:.1f} s)")


if __name__ == "__main__":
    print("Gerando áudio em", os.path.abspath(BASE))
    build_sfx()
    build_music()
    print("Pronto.")
