#!/bin/bash

echo "Building Android ARMv7a..."
rm -rf Game/lib/android/armv7
dotnet publish Extension/Summator.csproj -c Release -r linux-bionic-arm -o Game/lib/android/armv7 --self-contained
rm -f Game/lib/android/armv7/libSummator.so.dbg Game/lib/android/armv7/libSummator.xml

echo ""
echo "Building Android ARM64..."
rm -rf Game/lib/android/arm64
dotnet publish Extension/Summator.csproj -c Release -r linux-bionic-arm64 -o Game/lib/android/arm64 --self-contained
rm -f Game/lib/android/arm64/libSummator.so.dbg Game/lib/android/arm64/libSummator.xml

echo ""
echo "Android builds completed!"
echo "ARMv7a libraries:"
ls -la Game/lib/android/armv7/libSummator.so
echo ""
echo "ARM64 libraries:"
ls -la Game/lib/android/arm64/libSummator.so
