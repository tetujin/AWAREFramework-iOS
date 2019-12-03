all:
	pod deintegrate
	pod update
	pod install

test:
	set -o pipefail && xcodebuild clean build-for-testing -enableCodeCoverage YES -workspace AWAREFramework.xcworkspace -scheme AWAREFramework-Example CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO ONLY_ACTIVE_ARCH=NO -sdk iphonesimulator13.2 | xcpretty

