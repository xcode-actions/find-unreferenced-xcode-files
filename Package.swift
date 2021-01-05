// swift-tools-version:5.3
import PackageDescription


let package = Package(
	name: "find-unreferenced-xcode-files",
	platforms: [
		.macOS(.v10_15)
	],
	products: [
		.executable(name: "find-unreferenced-xcode-files", targets: ["find-unreferenced-xcode-files"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.3.1"),
		.package(url: "https://github.com/Frizlab/stream-reader.git", from: "3.0.0"),
		.package(url: "https://github.com/xcode-actions/XcodeTools.git", from: "0.2.1")
	],
	targets: [
		.target(name: "find-unreferenced-xcode-files", dependencies: [
			.product(name: "ArgumentParser", package: "swift-argument-parser"),
			.product(name: "StreamReader", package: "stream-reader"),
			.product(name: "XcodeProjKit", package: "XcodeTools")
		])
	]
)
