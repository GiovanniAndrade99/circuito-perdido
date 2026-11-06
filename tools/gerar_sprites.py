"""
Gerador de sprites (pixel art) do jogo Circuito Perdido.
Responsável: Carlos Eduardo Peraçolli

Toda a arte do jogo é produzida por este script (sem assets de terceiros):
cada quadro é desenhado em 16x16 (ou 48x48 no chefe) a partir de "ASCII art"
e primitivas, e depois ampliado 2x (vizinho mais próximo) para manter o
visual pixelado. As folhas (sprite sheets) são tiras horizontais de quadros.

Uso:  python tools/gerar_sprites.py   (executar na raiz do projeto)
Saída: assets/sprites/*.png
"""
import math
import os
import struct
import zlib

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
SCALE = 2

# Paleta "Sweetie 16" (GrafxKid) — cada caractere da ASCII art vira uma cor.
PALETTE = {
    ".": None,
    "k": (26, 28, 44),     # contorno
    "p": (93, 39, 93),
    "r": (177, 62, 83),
    "o": (239, 125, 87),
    "y": (255, 205, 117),
    "L": (167, 240, 112),
    "G": (56, 183, 100),
    "t": (37, 113, 121),
    "b": (41, 54, 111),
    "B": (59, 93, 201),
    "c": (65, 166, 246),
    "C": (115, 239, 247),
    "w": (244, 244, 244),
    "l": (148, 176, 194),
    "s": (86, 108, 134),
    "g": (51, 60, 87),
}


# ----------------------------------------------------------------------------
# Infraestrutura: canvas RGBA simples + escritor de PNG (somente stdlib)
# ----------------------------------------------------------------------------
class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[(0, 0, 0, 0) for _ in range(w)] for _ in range(h)]

    def set(self, x, y, color, alpha=255):
        if color is None:
            return
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = (color[0], color[1], color[2], alpha)

    def rect(self, x, y, w, h, color, alpha=255):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.set(xx, yy, color, alpha)

    def circle(self, cx, cy, r, color, alpha=255):
        for yy in range(int(cy - r - 1), int(cy + r + 2)):
            for xx in range(int(cx - r - 1), int(cx + r + 2)):
                if (xx + 0.5 - cx) ** 2 + (yy + 0.5 - cy) ** 2 <= r * r:
                    self.set(xx, yy, color, alpha)

    def ascii(self, lines, ox=0, oy=0):
        for y, row in enumerate(lines):
            for x, ch in enumerate(row):
                self.set(ox + x, oy + y, PALETTE[ch])

    def blit(self, other, ox, oy):
        for y in range(other.h):
            for x in range(other.w):
                p = other.px[y][x]
                if p[3] > 0 and 0 <= ox + x < self.w and 0 <= oy + y < self.h:
                    self.px[oy + y][ox + x] = p

    def scaled(self, s):
        c = Canvas(self.w * s, self.h * s)
        for y in range(c.h):
            for x in range(c.w):
                c.px[y][x] = self.px[y // s][x // s]
        return c

    def save(self, path):
        raw = bytearray()
        for row in self.px:
            raw.append(0)
            for p in row:
                raw.extend(p)

        def chunk(tag, data):
            body = tag + data
            return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

        png = b"\x89PNG\r\n\x1a\n"
        png += chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0))
        png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        png += chunk(b"IEND", b"")
        with open(path, "wb") as f:
            f.write(png)


def frame_from_ascii(lines, size=16):
    assert len(lines) == size, f"esperado {size} linhas, veio {len(lines)}"
    for i, row in enumerate(lines):
        assert len(row) == size, f"linha {i} com {len(row)} colunas: '{row}'"
    c = Canvas(size, size)
    c.ascii(lines)
    return c


def save_sheet(name, frames):
    """Junta quadros em uma tira horizontal, amplia e salva."""
    fw, fh = frames[0].w, frames[0].h
    sheet = Canvas(fw * len(frames), fh)
    for i, f in enumerate(frames):
        sheet.blit(f, i * fw, 0)
    sheet.scaled(SCALE).save(os.path.join(OUT_DIR, name + ".png"))
    print(f"  {name}.png  ({len(frames)} quadros de {fw * SCALE}x{fh * SCALE})")


EMPTY = "................"


def shift_up(lines):
    return lines[1:] + [EMPTY]


def replace_row(lines, idx, row):
    out = list(lines)
    out[idx] = row
    return out


# ----------------------------------------------------------------------------
# VOLT (jogador) — olhando para a direita
# ----------------------------------------------------------------------------
PLAYER_HEAD = [
    "................",
    "........kk......",
    "........kCk.....",
    ".........k......",
    "....kkkkkkkkk...",
    "...kwlllllllsk..",
    "...klkkkkkkksk..",
    "...klkbCCbCCkk..",
    "...klkkkkkkksk..",
    "...ksssssssssk..",
    "....kkkkkkkkk...",
]
PLAYER_BODY = [
    "....kgsoCsgk....",
    "...kkgssssgkk...",
    "....kkkkkkkk....",
]
LEGS_STAND = ["....kgk..kgk....", "....kkk..kkk...."]
LEGS_SPREAD = ["...kgk....kgk...", "...kkk....kkk..."]
LEGS_TOGETHER = [".....kgkkgk.....", ".....kkkkkk....."]
LEGS_TUCK = ["....kgkkgk......", "................"]


def player(legs, antenna_on=True, eyes="open", up=False):
    lines = PLAYER_HEAD + PLAYER_BODY + legs
    if not antenna_on:
        lines = replace_row(lines, 2, "........kck.....")
    if eyes == "blink":
        lines = replace_row(lines, 7, "...klkbbbbbbkk..")
    elif eyes == "hurt":
        lines = replace_row(lines, 7, "...klkrbrrbrkk..")
    if up:
        lines = shift_up(lines)
    return frame_from_ascii(lines)


def build_player():
    frames = [
        # idle 0-3
        player(LEGS_STAND),
        player(LEGS_STAND, antenna_on=False),
        player(LEGS_STAND),
        player(LEGS_STAND, eyes="blink"),
        # run 4-9
        player(LEGS_SPREAD),
        player(LEGS_STAND),
        player(LEGS_TOGETHER, up=True),
        player(LEGS_STAND, antenna_on=False),
        player(LEGS_SPREAD, antenna_on=False),
        player(LEGS_TOGETHER, up=True),
        # jump 10, fall 11, hurt 12
        player(LEGS_TUCK, up=True),
        player(LEGS_SPREAD, antenna_on=False),
        player(LEGS_SPREAD, eyes="hurt"),
    ]
    save_sheet("player", frames)


# ----------------------------------------------------------------------------
# Inimigos
# ----------------------------------------------------------------------------
PATROL_TOP = [
    "................",
    "................",
    "................",
    ".....kkkkkk.....",
    "....koooooyk....",
    "...kooooooook...",
    "...kokkkkkkok...",
    "...kokkrryrok...",
    "...kokkkkkkok...",
    "...kooooooook...",
    "...krrrrrrrrk...",
    "...kkkkkkkkkk...",
    "....kgggggggk...",
]
PATROL_WHEELS_A = ["...kgsk..kgsk...", "...kslk..kslk...", "....kk....kk...."]
PATROL_WHEELS_B = ["...kslk..kslk...", "...kgsk..kgsk...", "....kk....kk...."]


def build_patrol():
    eye_alt = "...kokkyrrrok..."
    frames = [
        frame_from_ascii(PATROL_TOP + PATROL_WHEELS_A),
        frame_from_ascii(PATROL_TOP + PATROL_WHEELS_B),
        frame_from_ascii(replace_row(PATROL_TOP, 7, eye_alt) + PATROL_WHEELS_A),
        frame_from_ascii(replace_row(PATROL_TOP, 7, eye_alt) + PATROL_WHEELS_B),
    ]
    save_sheet("patrol", frames)


TURRET = [
    "................",
    "................",
    "................",
    "................",
    "................",
    "......kkkk......",
    ".....kssssk.....",
    "....ksllllskkkk.",
    "....kslrrlsggggk",
    "....kslrrlskkkk.",
    "....ksllllsk....",
    "...kkkkkkkkkk...",
    "...kgggggggggk..",
    "..kssssssssssk..",
    "..kgggggggggggk.",
    "..kkkkkkkkkkkkk.",
]


def build_turret():
    charging = replace_row(replace_row(TURRET, 8, "....kslyylsggggk"), 9, "....kslyylskkkk.")
    firing = replace_row(charging, 8, "....kslyylsggggo")
    firing = replace_row(firing, 7, "....ksllllskkkky")
    firing = replace_row(firing, 9, "....kslyylskkkky")
    save_sheet("turret", [frame_from_ascii(TURRET), frame_from_ascii(charging), frame_from_ascii(firing)])


def build_kamikaze():
    def bomb(prop, body, eye):
        lines = [
            prop,
            ".......kk.......",
            "......kssk......",
            ".....kkkkkk.....",
            "....k" + body * 6 + "k....",
            "...k" + body * 8 + "k...",
            "..k" + body * 3 + "kkkk" + body * 3 + "k..",
            "..k" + body * 2 + "k" + eye * 4 + "k" + body * 2 + "k..",
            "..k" + body * 2 + "k" + eye * 4 + "k" + body * 2 + "k..",
            "..k" + body * 3 + "kkkk" + body * 3 + "k..",
            "...k" + body * 8 + "k...",
            "....k" + body * 6 + "k....",
            ".....kkkkkk.....",
            "......kyyk......",
            ".......oo.......",
            "................",
        ]
        return frame_from_ascii(lines)

    wide = "...kkkkkkkkkk..."
    thin = "......kkkk......"
    frames = [bomb(wide, "r", "y"), bomb(thin, "r", "y"), bomb(wide, "o", "w"), bomb(thin, "o", "w")]
    save_sheet("kamikaze", frames)


def build_boss():
    """Chefe SENTINELA — 48x48 desenhado com primitivas."""
    K, G, S, L, R, O, Y, C, W, P = (PALETTE[c] for c in "kgslroyCwp")

    def base(eye_color, thruster, tint=None, stunned=False):
        c = Canvas(48, 48)
        body = tint or S
        # propulsores
        c.rect(12, 38, 6, 6, K)
        c.rect(30, 38, 6, 6, K)
        c.rect(13, 39, 4, 4, G)
        c.rect(31, 39, 4, 4, G)
        if thruster:
            c.rect(13, 43, 4, 3, O)
            c.rect(31, 43, 4, 3, O)
            c.rect(14, 46, 2, 2, Y)
            c.rect(32, 46, 2, 2, Y)
        # braços / canhões
        c.rect(1, 18, 9, 14, K)
        c.rect(2, 19, 7, 12, G)
        c.rect(38, 18, 9, 14, K)
        c.rect(39, 19, 7, 12, G)
        c.rect(3, 30, 5, 4, K)
        c.rect(40, 30, 5, 4, K)
        # corpo
        c.circle(24, 24, 17, K)
        c.circle(24, 24, 15.5, body)
        c.circle(22, 20, 10, L if not tint else tint)
        c.circle(24, 24, 11, body)
        # placa frontal
        c.rect(10, 31, 28, 4, K)
        c.rect(11, 32, 26, 2, G)
        for i in range(4):
            c.rect(13 + i * 6, 32, 3, 2, Y if i % 2 == 0 else K)
        # olho
        c.circle(24, 22, 8, K)
        c.circle(24, 22, 6.5, G)
        if stunned:
            for d in range(-4, 5):
                c.set(24 + d, 22 + d, eye_color)
                c.set(24 + d, 22 - d, eye_color)
                c.set(25 + d, 22 + d, eye_color)
                c.set(25 + d, 22 - d, eye_color)
        else:
            c.circle(24, 22, 4.5, eye_color)
            c.circle(25.5, 20.5, 1.5, W)
        # antena
        c.rect(23, 2, 2, 6, K)
        c.rect(22, 0, 4, 3, R if not stunned else Y)
        return c

    frames = [
        base(R, True),
        base(R, False),
        base(Y, True, tint=PALETTE["r"]),
        base(PALETTE["y"], False, stunned=True),
    ]
    # faíscas no quadro atordoado
    for (x, y) in [(6, 8), (40, 10), (8, 40), (42, 38), (30, 4)]:
        frames[3].set(x, y, Y)
        frames[3].set(x + 1, y, W)
        frames[3].set(x, y + 1, W)
    save_sheet("boss", frames)


# ----------------------------------------------------------------------------
# Itens e objetos (quadros 16x16)
# ----------------------------------------------------------------------------
def build_items():
    K, Y, C, c_, W = PALETTE["k"], PALETTE["y"], PALETTE["C"], PALETTE["c"], PALETTE["w"]
    S, g = PALETTE["s"], PALETTE["g"]
    frames = []

    # 0-3: célula de energia girando (bateria)
    for w in (8, 6, 2, 6):
        f = Canvas(16, 16)
        x = 8 - w // 2
        f.rect(x - 1, 2, w + 2, 13, K)
        f.rect(x, 3, w, 11, c_)
        if w > 2:
            f.rect(x, 3, max(1, w // 3), 11, C)
            f.rect(x, 8, w, 2, Y)
        f.rect(7, 1, 2, 2, K)
        frames.append(f)

    heart = [
        "................",
        "................",
        "...kkk...kkk....",
        "..krrRk.kRwwk...",
        ".krrrrrkrrrwrk..",
        ".krrrrrrrrrrrk..",
        ".krrrrrrrrrrrk..",
        "..krrrrrrrrrk...",
        "...krrrrrrrk....",
        "....krrrrrk.....",
        ".....krrrk......",
        "......krk.......",
        ".......k........",
        "................",
        "................",
        "................",
    ]
    heart = [row.replace("R", "o") for row in heart]
    # 4: coração cheio, 5: coração vazio (HUD)
    frames.append(frame_from_ascii(heart))
    frames.append(frame_from_ascii([row.replace("r", "g").replace("o", "s").replace("w", "s") for row in heart]))

    # 6-9: núcleo de energia pulsando
    for i, rad in enumerate((5.0, 5.5, 6.0, 5.5)):
        f = Canvas(16, 16)
        f.circle(8, 8, rad + 1.2, K)
        f.circle(8, 8, rad, PALETTE["G"] if i % 2 == 0 else PALETTE["L"])
        f.circle(8, 8, rad - 2, PALETTE["L"] if i % 2 == 0 else PALETTE["w"])
        f.circle(6.5, 6.5, 1.3, W)
        frames.append(f)

    def terminal(screen, blink):
        f = Canvas(16, 16)
        f.rect(6, 9, 4, 7, K)
        f.rect(7, 9, 2, 7, S)
        f.rect(2, 1, 12, 9, K)
        f.rect(3, 2, 10, 7, g)
        f.rect(4, 3, 8, 5, screen)
        if blink:
            f.rect(5, 4, 2, 1, W)
            f.rect(5, 6, 5, 1, W)
        f.rect(3, 15, 10, 1, K)
        return f

    # 10: checkpoint desligado, 11-12: ligado (pisca)
    frames.append(terminal(PALETTE["r"], False))
    frames.append(terminal(PALETTE["G"], True))
    frames.append(terminal(PALETTE["L"], False))

    # 13: placa de dica (?)
    f = terminal(PALETTE["b"], False)
    q = ["kkk", "..k", ".kk", "...", ".k."]
    for y, row in enumerate(q):
        for x, ch in enumerate(row):
            if ch == "k":
                f.set(7 + x - 1, 3 + y, PALETTE["C"])
    frames.append(f)

    # 14: lâmpada de teto
    f = Canvas(16, 16)
    f.rect(7, 0, 2, 4, K)
    f.rect(3, 4, 10, 4, K)
    f.rect(4, 5, 8, 2, S)
    f.rect(5, 8, 6, 3, Y)
    f.rect(6, 11, 4, 1, PALETTE["w"])
    frames.append(f)

    # 15: tiro do jogador, 16: tiro inimigo
    for core, glow in ((PALETTE["w"], PALETTE["C"]), (PALETTE["y"], PALETTE["o"])):
        f = Canvas(16, 16)
        f.circle(8, 8, 4.5, glow)
        f.circle(8, 8, 2.5, core)
        frames.append(f)

    save_sheet("items", frames)


def build_portal():
    """Portal de saída 32x48: quadro 0 trancado, 1-4 aberto girando."""
    K, G, S, R, C, c_, W, B, b = (PALETTE[x] for x in "kgsrCcwBb")
    frames = []

    def frame_base():
        f = Canvas(32, 48)
        f.rect(1, 2, 30, 46, K)
        f.rect(3, 4, 26, 44, G)
        f.rect(6, 7, 20, 41, K)
        f.rect(1, 0, 30, 4, K)
        f.rect(3, 1, 26, 2, S)
        return f

    f = frame_base()
    f.rect(7, 8, 18, 40, PALETTE["p"])
    for x in (9, 14, 19, 24):
        f.rect(x - 1, 8, 2, 40, R)
    f.rect(12, 20, 8, 8, K)
    f.rect(14, 22, 4, 4, R)
    frames.append(f)
    for i in range(4):
        f = frame_base()
        f.rect(7, 8, 18, 40, b)
        for j in range(6):
            yy = 8 + ((j * 7 + i * 3) % 40)
            f.rect(8, yy, 16, 2, B)
        for j in range(5):
            yy = 8 + ((j * 9 + i * 5 + 4) % 40)
            f.rect(10 + (j * 3 + i) % 8, yy, 4, 1, C)
        f.rect(11, 12, 10, 32, c_, alpha=120)
        f.rect(14, 16, 4, 24, W, alpha=110)
        frames.append(f)
    save_sheet("portal", frames)


# ----------------------------------------------------------------------------
# Tiles e objetos do cenário (16x16)
# ----------------------------------------------------------------------------
def build_tiles():
    K, G, S, L = PALETTE["k"], PALETTE["g"], PALETTE["s"], PALETTE["l"]
    Y, W, O, g = PALETTE["y"], PALETTE["w"], PALETTE["o"], PALETTE["b"]
    frames = []

    # 0: chão (topo) — placa de aço com faixa de alerta
    f = Canvas(16, 16)
    f.rect(0, 0, 16, 16, G)
    f.rect(0, 0, 16, 2, L)
    f.rect(0, 2, 16, 3, K)
    for x in range(0, 16, 4):
        f.rect(x, 2, 2, 3, Y)
    f.rect(0, 5, 16, 1, S)
    f.set(2, 9, S)
    f.set(13, 9, S)
    f.set(2, 13, S)
    f.set(13, 13, S)
    f.rect(0, 15, 16, 1, K)
    frames.append(f)

    # 1: chão (interior)
    f = Canvas(16, 16)
    f.rect(0, 0, 16, 16, G)
    f.rect(0, 0, 16, 1, K)
    f.rect(0, 0, 1, 16, K)
    f.rect(1, 1, 15, 1, S)
    f.set(3, 4, S)
    f.set(12, 4, S)
    f.set(3, 12, S)
    f.set(12, 12, S)
    f.rect(6, 7, 4, 2, g)
    frames.append(f)

    # 2: plataforma atravessável (topo fino)
    f = Canvas(16, 16)
    f.rect(0, 0, 16, 6, K)
    f.rect(0, 1, 16, 2, L)
    f.rect(0, 3, 16, 2, S)
    f.rect(2, 6, 2, 4, K)
    f.rect(12, 6, 2, 4, K)
    frames.append(f)

    # 3: caixa
    f = Canvas(16, 16)
    f.rect(0, 0, 16, 16, K)
    f.rect(1, 1, 14, 14, O)
    f.rect(2, 2, 12, 12, PALETTE["r"])
    f.rect(1, 1, 14, 1, Y)
    for d in range(12):
        f.set(2 + d, 2 + d, O)
        f.set(13 - d, 2 + d, O)
    frames.append(f)

    # 4: espinhos
    f = Canvas(16, 16)
    for i in range(4):
        x0 = i * 4
        for h in range(7):
            w = max(1, (7 - h) // 2)
            f.rect(x0 + 2 - w // 2 - (1 if w > 1 else 0), 15 - h - 2, w + (1 if w > 1 else 0), 1, L if h > 4 else S)
        f.rect(x0, 13, 4, 1, K)
        f.set(x0 + 1, 7, W)
    f.rect(0, 14, 16, 2, K)
    frames.append(f)

    # 5-8: esteira (setas animadas para a direita)
    for i in range(4):
        f = Canvas(16, 16)
        f.rect(0, 0, 16, 16, K)
        f.rect(0, 1, 16, 5, S)
        for x in range(-4, 16, 6):
            xx = x + i * 2 - (i // 3) * 6
            for d in range(3):  # seta ">" de 3 pixels
                f.set(xx + d, 2 + d, Y)
                if d < 2:
                    f.set(xx + d, 4 - d, Y)
        f.rect(0, 6, 16, 10, G)
        for x in (3, 8, 13):
            f.circle(x, 11, 2.5, S)
            f.set(x, 11, K)
        frames.append(f)

    # 9: cabeça da prensa
    f = Canvas(16, 16)
    f.rect(0, 0, 16, 16, K)
    f.rect(1, 1, 14, 11, S)
    f.rect(1, 1, 14, 2, L)
    f.rect(0, 12, 16, 4, K)
    for x in range(0, 16, 4):
        f.rect(x, 13, 2, 2, Y)
    frames.append(f)

    # 10: haste da prensa
    f = Canvas(16, 16)
    f.rect(5, 0, 6, 16, K)
    f.rect(6, 0, 4, 16, L)
    f.rect(7, 0, 1, 16, W)
    frames.append(f)

    # 11: plataforma móvel
    f = Canvas(16, 16)
    f.rect(0, 0, 16, 8, K)
    f.rect(0, 1, 16, 2, PALETTE["C"])
    f.rect(0, 3, 16, 4, PALETTE["c"])
    f.rect(6, 4, 4, 2, Y)
    frames.append(f)

    # 12: parede de fundo (decoração, sem colisão)
    f = Canvas(16, 16)
    f.rect(0, 0, 16, 16, PALETTE["b"])
    f.rect(0, 0, 16, 1, K)
    f.rect(0, 0, 1, 16, K)
    frames.append(f)

    save_sheet("tiles", frames)


def build_icon():
    lines = PLAYER_HEAD + PLAYER_BODY + LEGS_STAND
    icon = Canvas(16, 16)
    icon.rect(0, 0, 16, 16, PALETTE["b"])
    icon.ascii(lines)
    icon.scaled(8).save(os.path.join(OUT_DIR, "..", "..", "icon.png"))
    print("  icon.png (128x128)")


if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    print("Gerando sprites em", os.path.abspath(OUT_DIR))
    build_player()
    build_patrol()
    build_turret()
    build_kamikaze()
    build_boss()
    build_items()
    build_portal()
    build_tiles()
    build_icon()
    print("Pronto.")
