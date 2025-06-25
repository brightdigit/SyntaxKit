#!/bin/sh
xcodebuild docbuild -scheme SimulatorServices -derivedDataPath DerivedData -destination 'platform=macOS'
$(xcrun --find docc) process-archive transform-for-static-hosting DerivedData/Build/Products/Debug/SimulatorServices.doccarchive --output-path Output