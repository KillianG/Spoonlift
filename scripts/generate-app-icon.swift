#!/usr/bin/env swift
// SPDX-License-Identifier: MIT
//
// Rasterises docs/logo.svg into every PNG size macOS expects for an AppIcon.
// Run from the project root:
//     swift scripts/generate-app-icon.swift

import AppKit

let cwd = FileManager.default.currentDirectoryPath
let svgPath = "\(cwd)/docs/logo.svg"
let outDir = "\(cwd)/Spoonlift/Assets.xcassets/AppIcon.appiconset"

guard FileManager.default.fileExists(atPath: svgPath) else {
    FileHandle.standardError.write(Data("✗ docs/logo.svg not found. Run from the project root.\n".utf8))
    exit(1)
}
guard let image = NSImage(contentsOfFile: svgPath) else {
    FileHandle.standardError.write(Data("✗ Failed to load SVG (NSImage returned nil).\n".utf8))
    exit(1)
}

let targets: [(name: String, pixels: Int)] = [
    ("icon_16x16",       16),
    ("icon_16x16@2x",    32),
    ("icon_32x32",       32),
    ("icon_32x32@2x",    64),
    ("icon_128x128",    128),
    ("icon_128x128@2x", 256),
    ("icon_256x256",    256),
    ("icon_256x256@2x", 512),
    ("icon_512x512",    512),
    ("icon_512x512@2x", 1024)
]

for target in targets {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: target.pixels,
        pixelsHigh: target.pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    ) else {
        print("✗ Could not allocate bitmap for \(target.name)")
        continue
    }
    rep.size = NSSize(width: target.pixels, height: target.pixels)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(
        in: NSRect(x: 0, y: 0, width: target.pixels, height: target.pixels),
        from: .zero,
        operation: .copy,
        fraction: 1.0
    )
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        print("✗ PNG encoding failed for \(target.name)")
        continue
    }

    let outURL = URL(fileURLWithPath: "\(outDir)/\(target.name).png")
    do {
        try data.write(to: outURL)
        print("✓ \(target.name).png (\(target.pixels)×\(target.pixels))")
    } catch {
        print("✗ \(target.name): \(error.localizedDescription)")
    }
}
