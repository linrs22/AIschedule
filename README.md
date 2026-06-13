# AIschedule

AIschedule 是一款 macOS 日程助手，可以把自然语言或截图中的内容解析为日历事件和提醒事项。

## 功能

- 使用 DeepSeek 解析自然语言日程
- 使用 macOS 本地 OCR 识别截图文字
- 添加前可检查并修改解析结果
- 一键写入 macOS 日历或提醒事项
- API Key 仅保存在本机 macOS 钥匙串中

## 系统要求

- macOS 15.0 或更高版本
- Apple Silicon 或 Intel Mac
- 用户自己的 [DeepSeek API Key](https://platform.deepseek.com/)

本项目的源码和 Release 安装包均不包含作者的 API Key。每位用户需要使用自己的 DeepSeek API Key。

## 下载与安装

1. 打开项目的 [Releases 页面](https://github.com/linrs22/AIschedule/releases)。
2. 进入最新版本，在 `Assets` 中下载 `AIschedule-版本号-macOS.zip`。
3. 双击 ZIP 文件解压，得到 `AIschedule.app`。
4. 将 `AIschedule.app` 拖入“应用程序”文件夹。
5. 首次运行时，右键点击 App，选择“打开”，然后在系统提示中再次点击“打开”。

当前 Release 使用 ad-hoc 签名，没有经过 Apple 公证。如果 macOS 阻止打开：

1. 打开“系统设置”。
2. 进入“隐私与安全性”。
3. 在安全提示中找到 AIschedule，点击“仍要打开”。

请只从本项目的 GitHub Releases 页面下载安装包。

## 配置 API Key

1. 前往 [DeepSeek 开放平台](https://platform.deepseek.com/) 注册或登录。
2. 创建一个 API Key。
3. 打开 AIschedule，点击右上角的“设置”。
4. 在 `DeepSeek API Key` 输入框中填写自己的 Key，然后点击“保存”。

API Key 不会写入项目文件或安装包，只会保存在当前 Mac 的系统钥匙串中。调用 DeepSeek API 可能产生费用，请参考 DeepSeek 平台的最新计费规则。

## 使用方法

### 从文字创建日程

1. 在左侧输入自然语言，例如：

   ```text
   明天下午 3 点和产品团队开会，预计 1 小时
   ```

2. 点击“解析”。
3. 在右侧检查标题、时间、地点和备注。
4. 点击“添加到日历”或“添加到提醒事项”。
5. 首次添加时，根据 macOS 提示授予日历或提醒事项权限。

### 从截图创建日程

1. 将包含日程信息的图片拖入 App，或点击“粘贴图片”。
2. 点击“解析”，App 会先在本机完成 OCR，再调用 DeepSeek 整理内容。
3. 检查解析结果后，将事项添加到日历或提醒事项。

建议在写入系统前检查 AI 推断出的日期和时间，尤其是“明天”“下周三”“下午”等相对或模糊表达。

## 常见问题

### 提示没有 API Key

打开右上角“设置”，填写并保存自己的 DeepSeek API Key。

### API 调用失败

检查网络连接、API Key 是否有效，以及 DeepSeek 账户是否有可用额度。

### 无法添加到日历或提醒事项

前往“系统设置” > “隐私与安全性” > “日历”或“提醒事项”，允许 AIschedule 访问。

### 无法打开 App

按照“下载与安装”部分的步骤右键打开，或在“系统设置” > “隐私与安全性”中选择“仍要打开”。

---

## English

AIschedule is a macOS app that turns natural-language text or screenshots into calendar events and reminders.

### Requirements

- macOS 15.0 or later
- Apple Silicon or Intel Mac
- A personal [DeepSeek API key](https://platform.deepseek.com/)

Download the latest ZIP from [GitHub Releases](https://github.com/linrs22/AIschedule/releases), extract `AIschedule.app`, and move it to Applications. The app does not include an API key; enter your own key in Settings. The key is stored only in the macOS Keychain.

## Build from Source

Open `SunMoonSchedule.xcodeproj` in Xcode 16 or later, or run:

```sh
xcodebuild \
  -project SunMoonSchedule.xcodeproj \
  -scheme SunMoonSchedule \
  -configuration Release \
  -derivedDataPath DerivedData \
  build
```

## Create a Release Package

```sh
./scripts/package-release.sh
```

The ZIP file will be written to `dist/`.
