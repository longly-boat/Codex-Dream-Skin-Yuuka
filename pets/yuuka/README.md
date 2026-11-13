# 优香桌宠 · v1.0.0

[English](README.en.md) · [返回主题仓库](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka) · [添加到自己的桌宠库](https://chatgpt.com/s/sharepet_6af711e160f88191a4508c5d0af094b2) · [下载完整素材包](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/releases/tag/yuuka-pet-v1.0.0)

配合优香 / 蔚蓝档案主题使用的独立桌宠。这里公开当前使用版本的完整图集、可编辑 PNG、动作布局、待机改进提示词、预览和构建工具。桌宠素材版本与主题安装器版本分别管理。

![优香待机动作](previews/idle.gif)
![全部常规动作预览](previews/all-states.gif)
![视线方向预览](previews/look-loop.gif)

新版待机依次表现：自然站立 → 半抬手 → 轻触衣领并歪头 → 闭眼眨眼 → 放下手 → 回到自然姿态。动作保持内敛，配合呼吸和发梢跟随。预览中的背景色与播放速度仅用于展示，实际图集为透明背景，播放时机和速度由应用控制。

## 使用

1. 打开上方的**桌宠分享页**，按页面提示添加到自己的桌宠库并启用。需要账号和应用支持桌宠功能；无需安装主题引擎。
2. 希望自行导入或改图时，下载本目录或 Release 的 `Yuuka-Pet-v1.0.0.zip`。使用 `spritesheet.webp`，它是完整 v2 图集，不是 GIF 预览。
3. 在有 Pets 功能的 Codex / ChatGPT 中，也可以附上该图集，请助手校验后创建一个属于自己的桌宠。不要把本目录覆盖进应用安装目录，`manifest.json` 也不是可直接替换的账号配置。

主题的 Windows Setup 不会自动导入桌宠，也不会替你更换账号中已选的宠物。无需为这个素材包重新安装主题。

## 文件与动作布局

- `spritesheet.webp`：可导入的透明图集，1536×2288，8 列 × 11 行，单格 192×208。
- `source/spritesheet.png`：与 WebP 逐像素一致的完整可编辑源图。
- `manifest.json`：名称、版本、动作行号和 16 个视线方向的映射，无私人账号记录。
- `prompts/`：保存下来的待机改进与两次细化提示词；并非全套动作最初的生成记录。
- `previews/`：从最终图集重新渲染的 GIF、全部动作联系表及六帧待机静态图。
- `build.py`、`requirements.txt`：独立的校验、无损编码与预览工具。
- `validation.json`、`SHA256SUMS.txt`：本次平台结构校验结果和公开文件摘要。

| 行号（从 0 开始） | 状态 | 帧数 |
| --- | --- | ---: |
| 0 | idle：待机 | 6 |
| 1 | running-right：向右移动 | 8 |
| 2 | running-left：向左移动 | 8 |
| 3 | waving：打招呼 | 4 |
| 4 | jumping：跳跃 | 5 |
| 5 | failed：失败反馈 | 8 |
| 6 | waiting：等待输入或批准 | 6 |
| 7 | running：处理任务 | 6 |
| 8 | review：检查结果 | 6 |
| 9–10 | look：16 个视线方向 | 16 |

合计 73 个有效格，其余 15 格透明。视线从正上方 0° 开始，按屏幕坐标顺时针每 22.5° 一格；90° 向右、180° 向下、270° 向左。旧本地播放器使用的七帧待机实验不在此包中。

![六帧待机动作](previews/idle-frames.png)

[查看全部动作联系表](previews/contact-sheet.png) · [待机—跳跃—待机预览](previews/idle-jump-idle.gif)

## 修改与重建

使用 Python 3.10–3.13（本机与 CI 验证版本为 3.13），依赖固定为 Pillow 11.2.1；建议先建立虚拟环境。以下在桌宠包目录执行：克隆仓库后先进入 `pets/yuuka`，下载 ZIP 则直接进入解压目录。

```sh
python -m pip install --only-binary=:all: -r requirements.txt
python build.py --check
python build.py --output /path/to/new-output-directory
```

Windows 可将输出路径写成 `D:\YuukaPetBuild`；输出目录必须尚不存在，工具不会覆盖旧文件。
修改 `source/spritesheet.png` 后，使用 `--output` 重新编码完整 WebP、生成布局清单与预览。工具不访问账号、网络或应用配置。发布后的源 PNG 可以无损重建相同像素；不同 Pillow / libwebp 版本可能得到不同文件字节。AI 提示词不能保证再次生成相同图像。

`--check` 检查公开包摘要、有效格、透明空格和 PNG/WebP 像素一致性；它不替代平台上传校验或动作质量检查。改图后请再次使用平台的桌宠校验，并检查所有相关动画。此包是现有桌宠的公开整理，未重新绘制其余动作，也不将结构通过表述为所有动作的全新认证。

## 致谢、许可与反馈

**特别感谢 [超天酱主题仓库及其维护者、贡献者](https://github.com/EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose)**，以及更早的 Dream Skin 贡献者，为配套主题提供代码与设计基础。详见 [项目致谢](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/blob/main/CREDITS.md)。桌宠同人图为本项目的独立补充，不归称为上游作者绘制。

构建脚本和文档采用 [MIT](LICENSE)；角色同人素材及第三方权利的范围见 [NOTICE.md](NOTICE.md)，软件许可证不授予角色或游戏标识权利。

本项目是**纯 vibe coding 产物**，如遇 bug 或动画瑕疵，先向你说声抱歉。欢迎在 [Issues](https://github.com/longly-boat/Codex-Dream-Skin-Yuuka/issues) 反馈应用版本、素材版本及复现方式。
