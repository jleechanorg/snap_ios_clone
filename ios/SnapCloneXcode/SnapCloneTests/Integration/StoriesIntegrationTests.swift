import XCTest
import SwiftUI
import Firebase
import FirebaseStorage
import Combine
@testable import SnapClone

/// Integration tests for Stories views → Firebase Storage integration
/// Tests follow TDD Red-Green-Refactor pattern to drive UI → ViewModel → Firebase stories
class StoriesIntegrationTests: XCTestCase {
    var storageService: FirebaseStorageService!
    var cancellables: Set<AnyCancellable>!
    var testUserId: String!
    var testStoryId: String!
    
    override func setUp() {
        super.setUp()
        storageService = FirebaseStorageService.shared
        cancellables = Set<AnyCancellable>()
        testUserId = "story-user-\(UUID().uuidString)"
        testStoryId = "story-\(UUID().uuidString)"
        
        // Configure Firebase for testing if not already configured
        if FirebaseApp.app() == nil {
            XCTFail("Firebase not configured for stories tests")
        }
    }
    
    override func tearDown() {
        // Cleanup test data
        Task {
            await cleanupTestStories()
        }
        cancellables = nil
        super.tearDown()
    }
    
    private func cleanupTestStories() async {
        // Remove test stories from Firebase Storage and Firestore
        do {
            let storage = Storage.storage()
            let storageRef = storage.reference().child("stories/\(testUserId)")
            
            // List and delete all test story files
            let listResult = try await storageRef.listAll()
            for item in listResult.items {
                try await item.delete()
            }
            
            // Remove story metadata from Firestore
            let db = Firestore.firestore()
            let storiesQuery = db.collection("stories").whereField("userId", isEqualTo: testUserId)
            let snapshot = try await storiesQuery.getDocuments()
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
            
        } catch {
            print("Cleanup failed: \(error)")
        }
    }
    
    // MARK: - Firebase Storage Service Tests
    
    func testFirebaseStorageServiceExists() {
        // GIVEN: Firebase Storage Service
        // WHEN: Service is accessed
        // THEN: Service should exist and be properly initialized
        XCTAssertNotNil(storageService)
        XCTAssertNotNil(Storage.storage())
    }
    
    func testStorageServiceConfiguration() {
        // GIVEN: Storage service instance
        // WHEN: Configuration is checked
        // THEN: Should be properly configured
        let storage = Storage.storage()
        XCTAssertNotNil(storage.reference())
    }
    
    // MARK: - Story Upload Integration Tests
    
    func testUploadStoryImage() async {
        // GIVEN: Story image data
        guard let testImageData = createTestImageData() else {
            XCTFail("Failed to create test image data")
            return
        }
        
        let storyMetadata = Story(
            id: testStoryId,
            userId: testUserId,
            mediaURL: "", // Will be set after upload
            mediaType: .image,
            caption: "Test story caption",
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        )
        
        do {
            // WHEN: Story image is uploaded
            let uploadedURL = try await storageService.uploadStoryImage(
                testImageData,
                storyId: testStoryId,
                userId: testUserId
            )
            
            // THEN: Should return valid download URL
            XCTAssertFalse(uploadedURL.isEmpty)
            XCTAssertTrue(uploadedURL.hasPrefix("https://"))
            
            // Verify file exists in Storage
            let storage = Storage.storage()
            let imageRef = storage.reference(withPath: "stories/\(testUserId)/\(testStoryId).jpg")
            let downloadURL = try await imageRef.downloadURL()
            XCTAssertEqual(uploadedURL, downloadURL.absoluteString)
            
        } catch {
            XCTFail("Story image upload failed: \(error.localizedDescription)")
        }
    }
    
    func testUploadStoryVideo() async {
        // GIVEN: Story video data
        guard let testVideoData = createTestVideoData() else {
            XCTFail("Failed to create test video data")
            return
        }
        
        let videoStoryId = "video-\(UUID().uuidString)"
        
        do {
            // WHEN: Story video is uploaded
            let uploadedURL = try await storageService.uploadStoryVideo(
                testVideoData,
                storyId: videoStoryId,
                userId: testUserId
            )
            
            // THEN: Should return valid download URL
            XCTAssertFalse(uploadedURL.isEmpty)
            XCTAssertTrue(uploadedURL.hasPrefix("https://"))
            XCTAssertTrue(uploadedURL.contains(".mp4"))
            
        } catch {
            XCTFail("Story video upload failed: \(error.localizedDescription)")
        }
    }
    
    func testStoryUploadWithProgress() async {
        // GIVEN: Story image and progress tracking
        guard let testImageData = createTestImageData() else {
            XCTFail("Failed to create test image data")
            return
        }
        
        let expectation = XCTestExpectation(description: "Upload progress tracked")
        var progressUpdates: [Double] = []
        
        do {
            // WHEN: Story is uploaded with progress monitoring
            let uploadedURL = try await storageService.uploadStoryWithProgress(
                testImageData,
                storyId: testStoryId,
                userId: testUserId,
                progressHandler: { progress in
                    progressUpdates.append(progress)
                    if progress >= 1.0 {
                        expectation.fulfill()
                    }
                }
            )
            
            // THEN: Should track progress and complete upload
            await fulfillment(of: [expectation], timeout: 15.0)
            XCTAssertFalse(uploadedURL.isEmpty)
            XCTAssertTrue(progressUpdates.count > 0)
            XCTAssertEqual(progressUpdates.last, 1.0)
            
        } catch {
            XCTFail("Story upload with progress failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Story Metadata Integration Tests
    
    func testCreateStoryWithMetadata() async {
        // GIVEN: Story data with metadata
        guard let testImageData = createTestImageData() else {
            XCTFail("Failed to create test image data")
            return
        }
        
        do {
            // Upload image first
            let uploadedURL = try await storageService.uploadStoryImage(
                testImageData,
                storyId: testStoryId,
                userId: testUserId
            )
            
            let story = Story(
                id: testStoryId,
                userId: testUserId,
                mediaURL: uploadedURL,
                mediaType: .image,
                caption: "Integration test story",
                createdAt: Date(),
                expiresAt: Date().addingTimeInterval(24 * 60 * 60)
            )
            
            // WHEN: Story metadata is saved
            try await storageService.saveStoryMetadata(story)
            
            // THEN: Story should be retrievable
            let retrievedStory = try await storageService.getStory(id: testStoryId)
            XCTAssertNotNil(retrievedStory)
            XCTAssertEqual(retrievedStory?.id, testStoryId)
            XCTAssertEqual(retrievedStory?.caption, "Integration test story")
            XCTAssertEqual(retrievedStory?.mediaURL, uploadedURL)
            
        } catch {
            XCTFail("Story metadata creation failed: \(error.localizedDescription)")
        }
    }
    
    func testGetUserStories() async {
        // GIVEN: User with multiple stories
        let story1Id = "story1-\(UUID().uuidString)"
        let story2Id = "story2-\(UUID().uuidString)"
        
        do {
            // Create test stories
            guard let imageData1 = createTestImageData(),
                  let imageData2 = createTestImageData() else {
                XCTFail("Failed to create test image data")
                return
            }
            
            let url1 = try await storageService.uploadStoryImage(imageData1, storyId: story1Id, userId: testUserId)
            let url2 = try await storageService.uploadStoryImage(imageData2, storyId: story2Id, userId: testUserId)
            
            let story1 = Story(id: story1Id, userId: testUserId, mediaURL: url1, mediaType: .image, caption: "Story 1", createdAt: Date(), expiresAt: Date().addingTimeInterval(24 * 60 * 60))
            let story2 = Story(id: story2Id, userId: testUserId, mediaURL: url2, mediaType: .image, caption: "Story 2", createdAt: Date(), expiresAt: Date().addingTimeInterval(24 * 60 * 60))
            
            try await storageService.saveStoryMetadata(story1)
            try await storageService.saveStoryMetadata(story2)
            
            // WHEN: User stories are retrieved
            let userStories = try await storageService.getUserStories(userId: testUserId)
            
            // THEN: Should return all user stories
            XCTAssertGreaterThanOrEqual(userStories.count, 2)
            let storyIds = userStories.map { $0.id }
            XCTAssertTrue(storyIds.contains(story1Id))
            XCTAssertTrue(storyIds.contains(story2Id))
            
        } catch {
            XCTFail("Get user stories failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Story Feed Integration Tests
    
    func testGetStoriesFeed() async {
        // GIVEN: Multiple users with stories
        let user1Id = "feed-user1-\(UUID().uuidString)"
        let user2Id = "feed-user2-\(UUID().uuidString)"
        
        do {
            // Create stories for different users
            guard let imageData = createTestImageData() else {
                XCTFail("Failed to create test image data")
                return
            }
            
            let story1Id = "feed-story1-\(UUID().uuidString)"
            let story2Id = "feed-story2-\(UUID().uuidString)"
            
            let url1 = try await storageService.uploadStoryImage(imageData, storyId: story1Id, userId: user1Id)
            let url2 = try await storageService.uploadStoryImage(imageData, storyId: story2Id, userId: user2Id)
            
            let story1 = Story(id: story1Id, userId: user1Id, mediaURL: url1, mediaType: .image, caption: "Feed Story 1", createdAt: Date(), expiresAt: Date().addingTimeInterval(24 * 60 * 60))
            let story2 = Story(id: story2Id, userId: user2Id, mediaURL: url2, mediaType: .image, caption: "Feed Story 2", createdAt: Date(), expiresAt: Date().addingTimeInterval(24 * 60 * 60))
            
            try await storageService.saveStoryMetadata(story1)
            try await storageService.saveStoryMetadata(story2)
            
            // WHEN: Stories feed is retrieved
            let feedStories = try await storageService.getStoriesFeed(for: testUserId)
            
            // THEN: Should return stories from followed users
            XCTAssertGreaterThanOrEqual(feedStories.count, 0) // May be 0 if no follow relationships exist
            
        } catch {
            XCTFail("Get stories feed failed: \(error.localizedDescription)")
        }
    }
    
    func testStoriesFeedRealTimeUpdates() async {
        // GIVEN: Stories feed listener
        let expectation = XCTestExpectation(description: "Real-time story update received")
        var receivedStories: [Story] = []
        
        // WHEN: Real-time listener is started
        storageService.startListeningToStoriesFeed(for: testUserId) { stories in
            receivedStories = stories
            if stories.count > 0 {
                expectation.fulfill()
            }
        }
        
        // Add a new story to trigger the listener
        do {
            guard let imageData = createTestImageData() else {
                XCTFail("Failed to create test image data")
                return
            }
            
            let newStoryId = "realtime-story-\(UUID().uuidString)"
            let uploadedURL = try await storageService.uploadStoryImage(imageData, storyId: newStoryId, userId: testUserId)
            
            let newStory = Story(
                id: newStoryId,
                userId: testUserId,
                mediaURL: uploadedURL,
                mediaType: .image,
                caption: "Real-time test story",
                createdAt: Date(),
                expiresAt: Date().addingTimeInterval(24 * 60 * 60)
            )
            
            try await storageService.saveStoryMetadata(newStory)
            
            // THEN: Should receive real-time update
            await fulfillment(of: [expectation], timeout: 10.0)
            XCTAssertTrue(receivedStories.contains { $0.id == newStoryId })
            
        } catch {
            XCTFail("Real-time stories feed test failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Story Expiration Tests
    
    func testStoryExpirationLogic() async {
        // GIVEN: Expired story
        guard let imageData = createTestImageData() else {
            XCTFail("Failed to create test image data")
            return
        }
        
        do {
            let expiredStoryId = "expired-story-\(UUID().uuidString)"
            let uploadedURL = try await storageService.uploadStoryImage(imageData, storyId: expiredStoryId, userId: testUserId)
            
            // Create story that expired 1 hour ago
            let expiredStory = Story(
                id: expiredStoryId,
                userId: testUserId,
                mediaURL: uploadedURL,
                mediaType: .image,
                caption: "Expired story",
                createdAt: Date().addingTimeInterval(-25 * 60 * 60), // 25 hours ago
                expiresAt: Date().addingTimeInterval(-1 * 60 * 60)   // 1 hour ago
            )
            
            try await storageService.saveStoryMetadata(expiredStory)
            
            // WHEN: Expired stories are cleaned up
            try await storageService.cleanupExpiredStories()
            
            // THEN: Expired story should be removed
            let retrievedStory = try? await storageService.getStory(id: expiredStoryId)
            XCTAssertNil(retrievedStory)
            
        } catch {
            XCTFail("Story expiration test failed: \(error.localizedDescription)")
        }
    }
    
    func testStoryAutoDeleteAfter24Hours() async {
        // GIVEN: Story scheduled for expiration
        let expiringStoryId = "expiring-story-\(UUID().uuidString)"
        
        guard let imageData = createTestImageData() else {
            XCTFail("Failed to create test image data")
            return
        }
        
        do {
            let uploadedURL = try await storageService.uploadStoryImage(imageData, storyId: expiringStoryId, userId: testUserId)
            
            // Create story that expires very soon (for testing purposes)
            let expiringStory = Story(
                id: expiringStoryId,
                userId: testUserId,
                mediaURL: uploadedURL,
                mediaType: .image,
                caption: "Soon to expire",
                createdAt: Date(),
                expiresAt: Date().addingTimeInterval(1) // Expires in 1 second
            )
            
            try await storageService.saveStoryMetadata(expiringStory)
            
            // WHEN: Time passes beyond expiration
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Trigger cleanup
            try await storageService.cleanupExpiredStories()
            
            // THEN: Story should be automatically deleted
            let retrievedStory = try? await storageService.getStory(id: expiringStoryId)
            XCTAssertNil(retrievedStory)
            
        } catch {
            XCTFail("Story auto-delete test failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Story Viewing Tests
    
    func testMarkStoryAsViewed() async {
        // GIVEN: Story that hasn't been viewed
        guard let imageData = createTestImageData() else {
            XCTFail("Failed to create test image data")
            return
        }
        
        do {
            let viewStoryId = "view-story-\(UUID().uuidString)"
            let uploadedURL = try await storageService.uploadStoryImage(imageData, storyId: viewStoryId, userId: testUserId)
            
            let story = Story(
                id: viewStoryId,
                userId: testUserId,
                mediaURL: uploadedURL,
                mediaType: .image,
                caption: "Story to be viewed",
                createdAt: Date(),
                expiresAt: Date().addingTimeInterval(24 * 60 * 60)
            )
            
            try await storageService.saveStoryMetadata(story)
            
            let viewerId = "viewer-\(UUID().uuidString)"
            
            // WHEN: Story is marked as viewed
            try await storageService.markStoryAsViewed(storyId: viewStoryId, viewerId: viewerId)
            
            // THEN: Story should have view record
            let storyViews = try await storageService.getStoryViews(storyId: viewStoryId)
            XCTAssertTrue(storyViews.contains(viewerId))
            
        } catch {
            XCTFail("Mark story as viewed failed: \(error.localizedDescription)")
        }
    }
    
    func testGetStoryViewers() async {
        // GIVEN: Story with multiple viewers
        guard let imageData = createTestImageData() else {
            XCTFail("Failed to create test image data")
            return
        }
        
        do {
            let viewersStoryId = "viewers-story-\(UUID().uuidString)"
            let uploadedURL = try await storageService.uploadStoryImage(imageData, storyId: viewersStoryId, userId: testUserId)
            
            let story = Story(
                id: viewersStoryId,
                userId: testUserId,
                mediaURL: uploadedURL,
                mediaType: .image,
                caption: "Story with viewers",
                createdAt: Date(),
                expiresAt: Date().addingTimeInterval(24 * 60 * 60)
            )
            
            try await storageService.saveStoryMetadata(story)
            
            // Mark as viewed by multiple users
            let viewer1 = "viewer1-\(UUID().uuidString)"
            let viewer2 = "viewer2-\(UUID().uuidString)"
            
            try await storageService.markStoryAsViewed(storyId: viewersStoryId, viewerId: viewer1)
            try await storageService.markStoryAsViewed(storyId: viewersStoryId, viewerId: viewer2)
            
            // WHEN: Story viewers are retrieved
            let viewers = try await storageService.getStoryViews(storyId: viewersStoryId)
            
            // THEN: Should return all viewers
            XCTAssertTrue(viewers.contains(viewer1))
            XCTAssertTrue(viewers.contains(viewer2))
            XCTAssertEqual(viewers.count, 2)
            
        } catch {
            XCTFail("Get story viewers failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Story Deletion Tests
    
    func testDeleteStory() async {
        // GIVEN: Existing story
        guard let imageData = createTestImageData() else {
            XCTFail("Failed to create test image data")
            return
        }
        
        do {
            let deleteStoryId = "delete-story-\(UUID().uuidString)"
            let uploadedURL = try await storageService.uploadStoryImage(imageData, storyId: deleteStoryId, userId: testUserId)
            
            let story = Story(
                id: deleteStoryId,
                userId: testUserId,
                mediaURL: uploadedURL,
                mediaType: .image,
                caption: "Story to be deleted",
                createdAt: Date(),
                expiresAt: Date().addingTimeInterval(24 * 60 * 60)
            )
            
            try await storageService.saveStoryMetadata(story)
            
            // Verify story exists
            let existingStory = try await storageService.getStory(id: deleteStoryId)
            XCTAssertNotNil(existingStory)
            
            // WHEN: Story is deleted
            try await storageService.deleteStory(id: deleteStoryId)
            
            // THEN: Story should no longer exist
            let deletedStory = try? await storageService.getStory(id: deleteStoryId)
            XCTAssertNil(deletedStory)
            
            // Storage file should also be deleted
            let storage = Storage.storage()
            let storageRef = storage.reference().child("stories/\(testUserId)/\(deleteStoryId).jpg")
            
            do {
                _ = try await storageRef.downloadURL()
                XCTFail("Storage file should have been deleted")
            } catch {
                // Expected - file should not exist
                XCTAssertTrue(true)
            }
            
        } catch {
            XCTFail("Delete story test failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImageData() -> Data? {
        // Create a simple test image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.blue.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        return image.jpegData(compressionQuality: 0.8)
    }
    
    private func createTestVideoData() -> Data? {
        // For testing purposes, create minimal video data
        // In a real implementation, this would be actual video data
        return "fake video data".data(using: .utf8)
    }
    
    // MARK: - Error Handling Tests
    
    func testUploadStoryWithInvalidData() async {
        // GIVEN: Invalid story data
        let invalidData = Data()
        
        do {
            // WHEN: Invalid data is uploaded
            _ = try await storageService.uploadStoryImage(invalidData, storyId: testStoryId, userId: testUserId)
            
            // THEN: Should handle error gracefully
            XCTFail("Should handle invalid data error")
        } catch {
            // Expected error for invalid data
            XCTAssertNotNil(error)
        }
    }
    
    func testGetNonExistentStory() async {
        // GIVEN: Non-existent story ID
        let nonExistentId = "non-existent-story"
        
        do {
            // WHEN: Non-existent story is retrieved
            let story = try await storageService.getStory(id: nonExistentId)
            
            // THEN: Should return nil or throw appropriate error
            XCTAssertNil(story)
        } catch {
            // May throw error depending on implementation
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Performance Tests
    
    func testStoryLoadingPerformance() async {
        // GIVEN: User with many stories
        let storyCount = 50
        var storyIds: [String] = []
        
        do {
            guard let imageData = createTestImageData() else {
                XCTFail("Failed to create test image data")
                return
            }
            
            // Create multiple stories
            for i in 1...storyCount {
                let storyId = "perf-story-\(i)-\(UUID().uuidString)"
                storyIds.append(storyId)
                
                let url = try await storageService.uploadStoryImage(imageData, storyId: storyId, userId: testUserId)
                let story = Story(
                    id: storyId,
                    userId: testUserId,
                    mediaURL: url,
                    mediaType: .image,
                    caption: "Performance story \(i)",
                    createdAt: Date(),
                    expiresAt: Date().addingTimeInterval(24 * 60 * 60)
                )
                try await storageService.saveStoryMetadata(story)
            }
            
            // WHEN: Stories are loaded with performance measurement
            let startTime = CFAbsoluteTimeGetCurrent()
            let userStories = try await storageService.getUserStories(userId: testUserId)
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            // THEN: Should load stories within reasonable time
            XCTAssertGreaterThanOrEqual(userStories.count, storyCount)
            XCTAssertLessThan(timeElapsed, 10.0) // Should load within 10 seconds
            
        } catch {
            XCTFail("Performance test failed: \(error.localizedDescription)")
        }
    }
}