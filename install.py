# -*- coding: utf-8 -*-
"""Nom Nom Galaxy 简体中文补丁 - 安装器"""
import os, sys, zlib, struct, shutil

GAME = r"D:\SteamLibrary\steamapps\common\NomNomGalaxy"
HERE = os.path.dirname(os.path.abspath(__file__))
PDATA = os.path.join(HERE, "patch_data")
TARGETS = [0, 8, 315, 833, 895]          # 被替换的档案条目
LANG_NEW = b"SPANISH"                     # 语言槽位（游戏内部名，界面上显示为简体中文）

def find_game():
    cfg = os.path.join(HERE, "game_path.txt")
    if os.path.exists(cfg):
        p = open(cfg, encoding="utf-8").read().strip()
        if p and os.path.exists(os.path.join(p, "data.pkdwin")): return p
    if os.path.exists(os.path.join(GAME, "data.pkdwin")): return GAME
    return None

def read_archive(base):
    with open(base + ".pkiwin", "rb") as f: pki = f.read()
    with open(base + ".pkdwin", "rb") as f: pkd = f.read()
    count = struct.unpack_from("<I", pki, 8)[0]
    entries = [struct.unpack_from("<IIII", pki, 12 + i*16) for i in range(count)]
    return pki, pkd, entries

def build(pki, pkd, entries, repl):
    parts = [pkd[:12]]; off = 12; new = []
    for i, (usize, csize, eoff, h) in enumerate(entries):
        if i in repl:
            payload = zlib.compress(repl[i], 9); usize = len(repl[i]); csize = len(payload)
        else:
            payload = pkd[eoff:eoff+csize]
        parts.append(payload); new.append((usize, csize, off, h)); off += csize
    npkd = b"".join(parts)
    npki = bytearray(pki[:12])
    for e in new: npki += struct.pack("<IIII", *e)
    npki += pki[12 + len(entries)*16:]
    return bytes(npkd), bytes(npki)

def set_language(base, token):
    """把存档里的语言字段改成 token（长度必须与原值相同）"""
    for root, dirs, files in os.walk(base):
        if "globals.dat" in files:
            p = os.path.join(root, "globals.dat")
            data = bytearray(open(p, "rb").read())
            for old in (b"ENGLISH", b"SPANISH"):
                i = data.find(old)
                if i > 0 and struct.unpack_from(">I", data, i-4)[0] == len(old):
                    if len(token) != len(old): continue
                    data[i:i+len(old)] = token
                    open(p, "wb").write(bytes(data))
                    return p
    return None

def main():
    game = find_game()
    if not game:
        print("[错误] 找不到游戏目录，请把游戏路径写进同目录的 game_path.txt"); return 1
    print("游戏目录:", game)
    bak_pkd = os.path.join(game, "data.pkdwin.bak_zh")
    src = os.path.join(game, "data.pkdwin.bak_zh") if os.path.exists(bak_pkd) else None
    # 优先从原始备份构建，保证可反复安装
    if src:
        print("使用原始备份 data.*.bak_zh 作为基础")
        with open(os.path.join(game, "data.pkiwin.bak_zh"), "rb") as f: pki = f.read()
        with open(bak_pkd, "rb") as f: pkd = f.read()
    else:
        print("未找到备份，将直接在当前文件上安装（并自动创建备份）")
        pki, pkd, _ = read_archive(os.path.join(game, "data"))
    count = struct.unpack_from("<I", pki, 8)[0]
    entries = [struct.unpack_from("<IIII", pki, 12 + i*16) for i in range(count)]
    repl = {}
    for i in TARGETS:
        fp = os.path.join(PDATA, "entry_%d.bin.z" % i)
        if os.path.exists(fp): repl[i] = zlib.decompress(open(fp, "rb").read())
        else:
            fp2 = os.path.join(PDATA, "entry_%d.bin" % i)
            if os.path.exists(fp2): repl[i] = open(fp2, "rb").read()
    if not repl:
        print("[错误] patch_data 缺少数据文件"); return 1
    npkd, npki = build(pki, pkd, entries, repl)
    # 备份原件（仅在还没有备份时）
    if not os.path.exists(bak_pkd):
        shutil.copy2(os.path.join(game, "data.pkdwin"), os.path.join(game, "data.pkdwin.bak_zh"))
        shutil.copy2(os.path.join(game, "data.pkiwin"), os.path.join(game, "data.pkiwin.bak_zh"))
        print("已创建原始文件备份: data.pkdwin.bak_zh / data.pkiwin.bak_zh")
    with open(os.path.join(game, "data.pkdwin"), "wb") as f: f.write(npkd)
    with open(os.path.join(game, "data.pkiwin"), "wb") as f: f.write(npki)
    print("已写入汉化数据: %.1f MB" % (len(npkd)/1048576))
    p = set_language(os.path.join(os.environ.get("APPDATA", ""), "NomNomGalaxy"), LANG_NEW)
    print("存档语言已设置:", p if p else "未找到 globals.dat（首次启动游戏后会自动生效）")
    print("\n安装完成！直接启动游戏即为简体中文。")
    return 0

if __name__ == "__main__":
    sys.exit(main())
