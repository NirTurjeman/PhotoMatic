# 📸 PhotoMatic — Smart Photo Compression for iOS

[![Platform](https://img.shields.io/badge/platform-iOS_15%2B-lightgrey.svg)](#-requirements)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](#-requirements)
[![UIKit](https://img.shields.io/badge/UIKit-✅-blue.svg)](#-features)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](#-license)

PhotoMatic lets you compress photos in a tap, optionally back up originals, and see how much storage you saved. Built with **UIKit** and a clean **MVVM** architecture.

---

## Table of Contents
- [✨ Features](#-features)
- [🧭 App Flow](#-app-flow)
- [🛠 Requirements](#-requirements)
- [🚀 Getting Started](#-getting-started)
- [🔐 Permissions (Info.plist)](#-permissions-infoplist)
- [⚙️ Configuration](#️-configuration)
- [🧪 Example: Using the Compression Manager](#-example-using-the-compression-manager)
- [🌍 Localization](#-localization)
- [📊 Storage Savings](#-storage-savings)
- [🧯 Troubleshooting](#-troubleshooting)
- [🗺️ Roadmap](#️-roadmap)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [📬 Contact](#-contact)

---

## ✨ Features
- Batch compression from the Photos library
- Adjustable quality (default 0.25, customizable)
- Optional backup/export of originals before compression
- Optional delete-after-compression toggle
- Live summary of total space saved (MB/GB) and per-item comparison
- Runtime language switching (English/Hebrew)
- UIKit-first UI, **MVVM** separation of concerns

---

## 🧭 App Flow
1) **Selected Photos** — pick items; grid + counter  
2) **Backup (optional)** — export/archive originals  
3) **Settings** — compression quality + toggles  
4) **Finish** — run compression and view savings

State is tracked in a single flow model (MVVM): selected IDs, quality, backup/delete toggles, and computed totals.

---

## 🛠 Requirements
- Xcode 15+
- iOS 15.0+
- Swift 5.9+
- Photos access (read/write)

---

## 🚀 Getting Started
1) Clone the repo  
   git clone https://github.com/your-org/PhotoMatic.git && cd PhotoMatic
2) Open the project in Xcode  
3) Set your Team & Bundle Identifier (Signing & Capabilities)  
4) Run on a real device for best performance

---

## 🔐 Permissions (Info.plist)
Add these keys (with your own wording if you prefer):
NSPhotoLibraryUsageDescription = "PhotoMatic needs access to your Photos library to select and compress images."
NSPhotoLibraryAddUsageDescription = "PhotoMatic needs permission to save compressed images or backups to your Photos library."

If exporting to Files with a document picker, no extra Info.plist keys are required.

---

## ⚙️ Configuration
Defaults are stored in UserDefaults (change to your needs):
- compressionQuality: Double (default 0.25)
- deleteAfterCompression: Bool (default false)
- wantsOriginalsArchive: Bool (default false)
- selectedLanguageCode: String ("en" or "he")

These are consumed by the ViewModels (MVVM) and surfaced in the Settings screen.

---

## 🧪 Example: Using the Compression Manager
Models (simplified):
- PhotoData: { image: UIImage?, imageSize: Int64, asset: PHAsset? }
- CompressedImage: { image: UIImage, imageSize: Int64, originalImage: PhotoData }
- CompressionResult: { compressed: [CompressedImage], totalOriginalBytes: Int64, totalCompressedBytes: Int64 }

Typical usage flow (high level):
- Map user selection (PHAssets / UIImages) into [PhotoData]
- Call CompressionManager.compressImages(selectedImages, quality, backupLocation?, originalsDeleted, completion)
- In completion, compute saved bytes = totalOriginalBytes - totalCompressedBytes
- Update the ViewModel, then refresh the Finish screen

Notes:
- If iCloud “Optimize iPhone Storage” is enabled, ensure full-res assets are fetched before compression.
- Use a DispatchGroup (or async/await) to aggregate per-item results.

---

## 🌍 Localization
- Localizable.strings for "en" and "he"
- A small runtime language switcher (e.g., LocaleManager) persists selectedLanguageCode in UserDefaults and notifies visible screens to refresh text
- Keep UI text in strings files only; ViewModels expose display strings for Views (MVVM)

---

## 📊 Storage Savings
We display:
- Per-item: original vs. compressed size
- Batch summary: total saved (MB/GB) and compression ratio

These numbers are computed from the CompressionResult and bound to the Finish screen via the ViewModel.

---

## 🧯 Troubleshooting
- No photos / no permission prompt → verify Info.plist keys and iOS Settings → Privacy → Photos
- “Limited Library Access” → guide users to allow “All Photos” for best results
- Slow compression → large or iCloud-only assets may take time to fetch; recommend Wi-Fi and power when compressing many items
- Disk space not updated immediately → iOS may reclaim space with delay; a reboot or idle time helps

---

## 🗺️ Roadmap
- Album picker and smart filters (size/date)
- Background processing with progress notifications
- Custom backup destinations (Files/iCloud Drive)
- Presets (social/archive/print)
- More languages

---

## 🤝 Contributing
1) Fork  
2) Create a feature branch (feat/your-topic)  
3) Commit with clear messages  
4) Open a PR with a short summary and screenshots if UI changed

Please follow existing style and add minimal tests where reasonable.

---

## 📄 License
MIT — see LICENSE file.

---

## 📬 Contact
Open a GitHub Issue for bugs/ideas. Made with ❤️ for tidy photo libraries.
