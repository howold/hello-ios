# HelloApp — 最小 iOS App（云端编译 + 本地签名）

一个只显示几行文字的 iOS App，用来验证 **"自建 App → 编译 → 签名 → 装到真机"** 整条链路。

- 零 Xcode 工程：没有 `.xcodeproj`、没有 storyboard，单个 `main.swift` 用 `swiftc` 直接编译
- 云端编译：GitHub Actions 的 `macos-14` runner 自带 Xcode，无需 Mac
- 产物未签名：签名在本地用 `zsign` + 你自己的证书完成

## 目录结构

```
hello-ios/
├── App/
│   ├── main.swift            # 全部代码（UIKit，纯代码布局）
│   └── Info.plist            # Bundle ID = com.demo.helloios
├── build.sh                  # 编译 + 打包，CI 调用
└── .github/workflows/
    └── build-ipa.yml         # 云端构建流程
```

## 一、推到 GitHub 触发构建

```bash
cd hello-ios
git init
git add .
git commit -m "minimal ios app"
git branch -M main
git remote add origin https://github.com/<你的账号>/hello-ios.git
git push -u origin main
```

推送后到仓库的 **Actions** 页面，`Build HelloApp IPA` 会自动运行，约 2–3 分钟。
也可以在 Actions 页手动点 **Run workflow**。

## 二、下载产物

构建成功后，在该次运行的 **Artifacts** 区域下载 `HelloApp-ipa`（一个 zip，解开得到 `HelloApp.ipa`）。

命令行方式（需安装 [GitHub CLI](https://cli.github.com/)）：

```bash
gh run download --name HelloApp-ipa
```

## 三、本地验包

用本仓库上级目录的体检脚本确认结构正确：

```powershell
python ..\tools\preflight.py .\HelloApp.ipa
```

预期输出要点：

```json
"bundle_id": "com.demo.helloios",
"cryptid": 0,
"encrypted": false,
"has_scinfo": false,
"signable": true
```

## 四、签名并安装

签名需要 **证书 p12 + 描述文件**（企业证书或 Apple 开发者证书）。

```powershell
..\tools\sign-and-install.ps1 `
  -Ipa .\HelloApp.ipa `
  -P12 C:\path\your.p12 `
  -Password 你的密码 `
  -Profile C:\path\your.mobileprovision
```

脚本会依次执行：体检 → zsign 重签（`-z 9` 保证体积正常）→ `pymobiledevice3` 安装 → 抓日志验证。

安装后首次打开可能需要信任证书：

> 设置 → 通用 → VPN与设备管理 → 信任对应开发者

## 五、没有证书时怎么办

- **企业证书**：Apple Developer Enterprise Program，$299/年，需 D-U-N-S，审核 1–4 周
- **免费 Apple ID**：可签发 7 天有效的开发证书，限 3 个 App ID、100 台设备/年，只能验证不能上量
  - Windows 上可用 iLoader / Sideloadly 完成 Apple ID 认证与证书申请
  - 注意：免费证书**不支持推送**（`aps-environment`），本 App 没有推送需求，不受影响

## 常见问题

**构建报 `swiftc: error: no such module 'UIKit'`**
确认 runner 是 `macos-*`（Linux runner 没有 iOS SDK），且步骤里没有覆盖 `SDKROOT`。

**安装报 `0xE8008014 invalid signature`**
说明用了 ad-hoc 签名（无证书链）。必须是 Apple 签发的证书 + 对应描述文件。

**安装成功但打开黑屏**
检查 `Info.plist` 里是否残留 `UIApplicationSceneManifest`；本项目使用传统生命周期，
该键必须不存在。

**安装报 `0xE8008016` 或描述文件不匹配**
描述文件里的 App ID 必须与 `com.demo.helloios` 一致；企业证书用 In-House 描述文件，
开发证书需把目标设备 UDID 加入描述文件。
