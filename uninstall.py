# -*- coding: utf-8 -*-
"""Nom Nom Galaxy 简体中文补丁 - 卸载器（还原英文）"""
import os, sys, shutil

GAME = r"D:\SteamLibrary\steamapps\common\NomNomGalaxy"
HERE = os.path.dirname(os.path.abspath(__file__))

def find_game():
    cfg = os.path.join(HERE, "game_path.txt")
    if os.path.exists(cfg):
        p = open(cfg, encoding="utf-8").read().strip()
        if p and os.path.exists(os.path.join(p, "data.pkdwin")): return p
    if os.path.exists(os.path.join(GAME, "data.pkdwin")): return GAME
    return None

def main():
    game = find_game()
    if not game:
        print("[错误] 找不到游戏目录"); return 1
    ok = True
    for f in ("data.pkdwin", "data.pkiwin"):
        src = os.path.join(game, f + ".bak_zh")
        if os.path.exists(src):
            shutil.copy2(src, os.path.join(game, f))
            print("已还原", f)
        else:
            print("[警告] 缺少备份", f + ".bak_zh"); ok = False
    # 语言改回英文
    base = os.path.join(os.environ.get("APPDATA", ""), "NomNomGalaxy")
    for root, dirs, files in os.walk(base):
        if "globals.dat" in files:
            p = os.path.join(root, "globals.dat")
            data = bytearray(open(p, "rb").read()); i = data.find(b"SPANISH")
            if i > 0:
                data[i:i+7] = b"ENGLISH"; open(p, "wb").write(bytes(data)); print("存档语言已还原为 English")
    print("\n卸载完成，游戏已回到英文原版。")
    print("（如果 Steam 更新过游戏，原版文件本来就被覆盖，无需卸载）")
    return 0

if __name__ == "__main__":
    sys.exit(main())
