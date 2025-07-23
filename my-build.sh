# Debug build (current)
./build.sh --restore --build /p:GenerateGodotBindings=true /p:EnableTrimAnalyzer=false /p:EnableAotAnalyzer=false /p:TreatWarningsAsErrors=false /p:RunAnalyzersDuringBuild=false /p:RunCodeAnalysis=false /p:GenerateDocumentationFile=false

# Release build - optimized, no debug symbols
#./build.sh --restore --build --configuration Release /p:GenerateGodotBindings=true /p:EnableTrimAnalyzer=false /p:EnableAotAnalyzer=false /p:TreatWarningsAsErrors=false /p:RunAnalyzersDuringBuild=false /p:RunCodeAnalysis=false /p:GenerateDocumentationFile=false

# Release build with stricter analysis (recommended for final releases)
# ./build.sh --restore --build --configuration Release /p:GenerateGodotBindings=true /p:EnableTrimAnalyzer=true /p:EnableAotAnalyzer=true

# ============================================================================
# WORKING iOS/macOS NATIVE FRAMEWORK GENERATION
# ============================================================================

# CONFIRMED WORKING: macOS NativeAOT 
# First, ensure bindings are built:
# ./build.sh --restore --build --configuration Release /p:GenerateGodotBindings=true /p:EnableTrimAnalyzer=false /p:EnableAotAnalyzer=false /p:TreatWarningsAsErrors=false /p:RunAnalyzersDuringBuild=false /p:RunCodeAnalysis=false /p:GenerateDocumentationFile=false

# macOS ARM64 NativeAOT (WORKING - produces Summator.dylib)
# dotnet publish samples/Summator/Extension -c Release -r osx-arm64 -o samples/Summator/Game/lib/osx-arm64 --self-contained true

# macOS x64 NativeAOT (Intel)
# dotnet publish samples/Summator/Extension -c Release -r osx-x64 -o samples/Summator/Game/lib/osx-x64 --self-contained true

# ============================================================================
# ANDROID NATIVE AOT BUILDS
# ============================================================================

# Android ARM64 (modern devices)
# dotnet publish samples/Summator/Extension -c Release -r linux-bionic-arm64 -o samples/Summator/Game/lib/android/arm64 --self-contained true

# Android ARMv7a (older devices - 32-bit ARM)
# dotnet publish samples/Summator/Extension -c Release -r linux-bionic-arm -o samples/Summator/Game/lib/android/armv7 --self-contained true

# ============================================================================
# iOS DEPLOYMENT OPTIONS (.NET 9 limitations)
# ============================================================================

# OPTION 1: iOS Managed DLLs (RECOMMENDED for .NET 9 + Godot)
# This approach works with current Godot iOS export and .NET 9
# ./build.sh --restore --build --configuration Release /p:GenerateGodotBindings=true /p:EnableTrimAnalyzer=false /p:EnableAotAnalyzer=false /p:TreatWarningsAsErrors=false /p:RunAnalyzersDuringBuild=false /p:RunCodeAnalysis=false /p:GenerateDocumentationFile=false
# mkdir -p samples/Summator/Game/lib/ios-arm64
# cp artifacts/bin/Summator/Release/net9.0/Summator.dll samples/Summator/Game/lib/ios-arm64/
# cp artifacts/bin/Summator/Release/net9.0/Godot.Bindings.dll samples/Summator/Game/lib/ios-arm64/

# OPTION 2: iOS NativeAOT (BLOCKED in .NET 9.0.1)
# Issue: Microsoft.NETCore.App.Runtime.Mono.ios-arm64 version 9.0.1 not available
# The Mono runtime packages for iOS are currently at 9.0.3, but .NET SDK expects 9.0.1
# This may be resolved in future .NET updates

# OPTION 3: Manual iOS AOT (Advanced)
# Use Mono AOT compiler directly with the available 9.0.3 runtime
# This requires custom tooling and is beyond standard dotnet publish

# RECOMMENDATION: Use managed DLLs for iOS until .NET tooling improves