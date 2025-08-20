// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SnapClone",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SnapClone",
            targets: ["SnapClone"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.20.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
        .package(url: "https://github.com/evgenyneu/keychain-swift.git", from: "20.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "SnapClone",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "KeychainSwift", package: "keychain-swift"),
                .product(name: "Kingfisher", package: "Kingfisher")
            ],
            path: "SnapCloneApp"
        )
    ]
)
