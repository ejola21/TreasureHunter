# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Play Spot** (bundle ID: `com.mking.trasurehunter`) is a location-based treasure hunt iOS game with augmented reality features. Players create and play GPS-based missions with quiz challenges, collectible items, power-ups, and hazards. Supports "real mode" (actual GPS) and "virtual mode" (simulated locations). Localized in English and Korean.

## Build System

- **Xcode project**: `TreasureHunter.xcodeproj` — open in Xcode and build the "Play Spot" target
- **Language**: Objective-C (iOS 4+ era)
- **No CocoaPods/SPM** — all third-party libraries are vendored directly in `Classes/`
- **Prefix header**: `TreasureHunter_Prefix.pch` defines global macros (`APPDEL`, `BASEURL`, `RGB`, debug `NSLog`, game state enums)
- **XIB-based UI**: 28 Interface Builder files in `Resources/xib/`

## Architecture

### MVC + DAO Pattern

The app follows standard MVC with a dedicated DAO layer for SQLite persistence:

- **App Delegate** (`TreasureHunterAppDelegate`) acts as a singleton for global state: location manager, database initialization, configuration dictionaries. Accessed via the `APPDEL` macro.
- **Models**: `Mission` and `MissionItem` are the core domain objects. `MissionItem.h` defines all item type constants (quiz, radar, mines, collectibles, power-ups, etc.).
- **DAOs** (`Classes/Dao/`): `BaseDao` provides the DB connection; subclasses (`MissionDao`, `MissionItemDao`, `MissionInPlayDao`, `MissionItemInPlayDao`, `ItemQuizDao`, `ItemRnPInPlayDao`) handle CRUD for each entity against the embedded `treasure.sqlite` database.
- **Controllers**: `MissionPlay` is the main gameplay controller (~85KB, most complex class). `MissionBuilder` handles mission creation on a map. `MissionList` shows available missions.

### Key Subsystems

- **AR**: `ARViewController` and `ARGeoViewController` overlay coordinate-based markers on the camera view, with distance-based scaling.
- **HTTP**: `HTTPRequest` class handles async server communication for mission sync and user progress.
- **StoreKit**: In-app purchases integrated in `MyInfo` controller for virtual currency.
- **Audio**: Background music and sound effects via AudioToolbox.
- **Database**: FMDB library wraps SQLite3. The schema lives in `Resources/treasure.sqlite` (also copied in `doc/`).

### Game State Enums (from prefix header)

- Mission states: `DESIGNING`, `TESTED`, `SERVER_UPLOAD`, `FIRST_DESIGN`
- Play modes: `REAL_MODE`, `VIRTUAL_MODE`
- Item mandatory flag: `MANDATORY_N`, `MANDATORY_Y`

## Bundled Third-Party Libraries

All in `Classes/` subdirectories — no package manager:

| Library | Location | Purpose |
|---------|----------|---------|
| FMDB | `Classes/FMDB/` | SQLite wrapper |
| SBJson | `Classes/JSON/` | JSON parsing |
| SBTickerView | `Classes/flip/` | Flip counter animations |
| CMPopTipView | `Classes/CMPopTipView/` | Tooltip popups |
| SVProgressHUD | `Classes/` | Loading indicator |
| DLStarRatingControl | `Classes/` | Star rating widget |

## Linked Frameworks

MapKit, CoreLocation, StoreKit, AudioToolbox, MediaPlayer, QuartzCore, CoreGraphics, UIKit, Foundation.

## Legacy Version Control

The repo contains `.svn/` directories from a prior Subversion history. These are staged in git but are not part of the active source.
