// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SnapClone",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SnapClone",
            targets: ["SnapClone"]
        ),
    ],
    dependencies: [
        // Firebase SDK
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "10.0.0"
        ),
        
        // Kingfisher for image loading and caching
        .package(
            url: "https://github.com/onevcat/Kingfisher.git",
            from: "7.0.0"
        ),
        
        // SwiftUI Navigation utilities
        .package(
            url: "https://github.com/pointfreeco/swiftui-navigation.git",
            from: "1.0.0"
        ),
        
        // Combine schedulers for testing
        .package(
            url: "https://github.com/pointfreeco/combine-schedulers.git",
            from: "1.0.0"
        )
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

/*
 Dependencies Explained:

 1. Firebase iOS SDK - Core backend services
    - FirebaseAuth: User authentication
    - FirebaseFirestore: Real-time database
    - FirebaseStorage: File/image storage
    - FirebaseMessaging: Push notifications
    - FirebaseAnalytics: App analytics
    - FirebaseCrashlytics: Crash reporting

 2. Kingfisher - Advanced image loading
    - Async image loading with caching
    - Image processing and filtering
    - Memory and disk cache management
    - Better performance than AsyncImage for complex apps

 3. SwiftUI Navigation - Enhanced navigation
    - Better navigation state management
    - Deep linking support
    - Programmatic navigation

 4. Combine Schedulers - Testing utilities
    - Test schedulers for async operations
    - Better unit testing for ViewModels
    - Time-based testing utilities

 To add these dependencies to your Xcode project:
 1. Open your Xcode project
 2. Select your project in the navigator
 3. Select your app target
 4. Go to Package Dependencies tab
 5. Click + and add each repository URL
 6. Choose the appropriate version requirements
 */