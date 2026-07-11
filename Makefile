build.macos:
	 cd ./tauri/swift-library && \
	 rm -rf ./.build && \
	 swift build --build-system native -c release -Xswiftc -import-objc-header -Xswiftc Sources/swift-library/bridging-header.h && \
	 cd .. && \
	 bun tauri:build
