# 美味银河 简体中文汉化补丁 (Nom Nom Galaxy Chinese Patch)

> 为 Steam 版 **PixelJunk™ Nom Nom Galaxy**（中文译名《美味银河》，AppID **226100**）制作的**全量简体中文汉化补丁**。

[![Game](https://img.shields.io/badge/Steam-AppID%20226100-1b2838)](https://store.steampowered.com/app/226100/)
[![Patch](https://img.shields.io/badge/补丁版本-v1.0-brightgreen)]()
[![Platform](https://img.shields.io/badge/平台-Windows-blue)]()

---

## 简介

《美味银河》是一款横版动作经营游戏：你在银河各处采集食材、熬制汤品、经营汤品公司，还要和竞争对手抢生意。

游戏本体自带多语言框架，但 **PC 版只有 435 条文本带官方中文**，而且**中文专用字体资源缺失**——就算强行切到中文，也会整屏一个字都不显示。

本补丁做了三件事：

| 内容 | 说明 |
|---|---|
| **全量文本汉化** | 游戏共 2164 条文本，补丁翻译了**全部 2154 条**（含菜单、教程、挑战、联机、成就、汤品名、剧情对话等），保留原有的 435 条官方中文 |
| **字形补充** | 自带位图字体只覆盖其中 828 个汉字，补丁从 **Noto Sans SC** 重新渲染并补入 **975 个缺失汉字**（字形总数 2704 → 3679），字重、灰度、边缘观感与原字体对齐 |
| **字体与语言入口修复** | 把可用的字体槽位换成游戏自带的 **Noto Sans CJK**；绕过官方语言白名单，让中文可以正常启用（菜单里显示为「简体中文」） |

---

## 安装

### 一键安装（推荐）

1. 下载本仓库（`Code → Download ZIP`）或 Releases 里的压缩包
2. 解压到任意目录
3. 双击 **`安装汉化.bat`**
4. 启动游戏，就是简体中文了

> 脚本会自动把原文件备份为 `data.pkdwin.bak_zh` / `data.pkiwin.bak_zh`。

### 手动安装

```bash
python install.py
```

如果游戏不在默认目录，在补丁目录下新建 `game_path.txt`，里面写一行游戏安装路径即可：

```
D:\SteamLibrary\steamapps\common\NomNomGalaxy
```

### 环境要求

- Windows + Python 3（脚本用到 `zlib`/`struct`，均为标准库）
- 游戏本体：Steam 版 PixelJunk™ Nom Nom Galaxy（AppID 226100）

---

## 卸载

双击 **`卸载还原.bat`**，会从备份还原为英文原版，并把语言设置改回 English。

---

## 常见问题

**Q：Steam 提示更新，或者我点了「验证游戏文件完整性」，汉化没了？**
A：正常现象——这两个操作都会用原版覆盖 `data.pkdwin`。备份还在，重新双击 `安装汉化.bat` 即可再次汉化（可反复安装）。

**Q：语言菜单里那项为什么写着「简体中文」，但游戏里叫 Español？**
A：游戏官方的语言白名单把中文关掉了，补丁借用「西班牙语」槽位承载中文。菜单项已经改名为「简体中文」，正常用不会有影响。

**Q：我不小心切到别的语言了，怎么切回来？**
A：选项 → Language，选「简体中文」那一项（内部是 Español）。

**Q：发现错译 / 漏译 / 显示成方块？**
A：欢迎提 [Issue](https://github.com/MrDestinyCJ/nomnom_chinese/issues)，最好带上截图和出现的位置（哪个菜单、哪个界面）。


**Q：Windows 提示「此文件可能对您的计算机有害」，是不是有毒？**
A：不是。这是 Windows 对**未签名脚本**（`.bat` / `.cmd` / `.ps1`）的通用警告——任何从网上下载的脚本都会弹，
与文件实际内容无关。本补丁的代码全部是纯文本，只有两个 Python 脚本，只做两件事：
读写游戏目录下的 `data.pkdwin`、改一下游戏存档里的语言字段。

四种解决办法，任选其一：

1. 弹窗里点「更多信息」→「仍要运行」
2. 解压前先解锁：右键压缩包 → 属性 → 勾选底部「解除锁定」→ 确定，再解压
3. 解压后批量解锁（推荐）：在补丁目录按住 Shift + 右键 →「在此处打开 PowerShell 窗口」，执行
   ```powershell
   Get-ChildItem -Recurse | Unblock-File
   ```
4. 不想用 .bat：在补丁目录打开命令行，直接执行 `python install.py`

不放心可以先核对文件哈希，压缩包内附带 `校验值.txt`（含所有文件的 SHA-256）。

**Q：会不会影响成就 / 联机 / 存档？**
A：不会。补丁只替换文本与字体资源，不修改可执行文件和存档结构（仅把语言设置指向中文槽位）。

---

## 技术细节

想了解补丁是怎么做出来的（档案格式、文本表结构、位图字体格式、字形补全原理），见 [docs/技术说明.md](docs/技术说明.md)。

简要流程：

```
data.pkdwin / data.pkiwin   ← Double Eleven 引擎的资源档案（zlib + 16 字节索引项）
  └─ #315  gametext.utxt    ← UTF-16LE 的 TSV 本地化表（2164 行 × 16 列）
  └─ #833/#839  *.fnt       ← AngelCode BMF 位图字体（FOT-Kurokane / Noto Sans CJK SC）
  └─ #894/#895  *.dds       ← 2048×2048 8bit 字形图集
```

补丁替换其中 5 个条目并重排档案索引，因此可以做到 **2.5MB 的补丁体量**。

---

## 目录结构

```
├─ 安装汉化.bat            一键安装
├─ 卸载还原.bat            一键卸载
├─ install.py              安装脚本
├─ uninstall.py            卸载脚本
├─ patch_data/             汉化数据（文本表 / 字体 / 图集）
├─ translation_source.json 全部 2154 条译文（纯文本，便于校对与二次开发）
├─ 说明.txt                补丁说明
└─ docs/
   ├─ 技术说明.md          逆向分析与制作原理
   └─ CHANGELOG.md         更新日志
```

---

## 声明

- 本补丁为**非官方民间汉化**，仅供学习交流使用，**请勿用于任何商业用途**。
- 游戏本体及其美术、字体资源版权归 **Q-Games Ltd. / Double Eleven** 所有。
- 提取出的字体为游戏自带资源（Noto Sans CJK / FOT-Kurokane），仅在本补丁内按原用途使用。
- 新增字形由系统字体 **Noto Sans SC** 渲染，遵循 SIL Open Font License 1.1。
- 补丁脚本部分以 MIT 协议开源，详见 [LICENSE](LICENSE)。
- 如果你喜欢这款游戏，**请购买正版支持开发者**。

---

## 致谢

- Q-Games / Double Eleven —— 做出了这么可爱的游戏
- 原 435 条官方中文（来自主机版）—— 本补丁予以保留并沿用其术语
- 所有帮忙测试与反馈的玩家

**祝熬汤愉快！🍲**
