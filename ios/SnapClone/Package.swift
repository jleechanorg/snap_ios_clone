// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SnapCloneDemo",
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.1.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "7.0.0"),
        .package(url: "https://github.com/pointfreeco/swiftui-navigation", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "SnapClone",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "SwiftUINavigation", package: "swiftui-navigation"),
                .product(name: "CombineSchedulers", package: "combine-schedulers")
            ],
            path: "SnapClone"
        ),
        .testTarget(
            name: "SnapCloneTests",
            dependencies: [
                "SnapClone",
                .product(name: "CombineSchedulers", package: "combine-schedulers")
            ],
            path: "SnapCloneTests"
        )
    ]
)
