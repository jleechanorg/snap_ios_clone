//
//  CapturedImageView.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Captured photo preview and sharing interface
//  Requirements: iOS 16+, CameraViewModel integration
//

import SwiftUI

struct CapturedImageView: View {
    let image: UIImage
    @ObservedObject var cameraViewModel: CameraViewModel
    @State private var showingFriendsSheet = false
    @State private var caption = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Captured Image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
                
                Spacer()
                
                // Caption Input
                HStack {
                    TextField("Add a caption...", text: $caption)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Action Buttons
                HStack(spacing: 30) {
                    // Retake Button
                    Button("Retake") {
                        cameraViewModel.retakePhoto()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    // Save to Library Button
                    Button("Save") {
                        cameraViewModel.savePhotoToLibrary(image)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    // Send Button
                    Button("Send") {
                        showingFriendsSheet = true
                    }
                    .padding()
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .fontWeight(.bold)
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showingFriendsSheet) {
            FriendsPickerView(
                image: image,
                caption: caption,
                cameraViewModel: cameraViewModel
            )
        }
    }
}

struct FriendsPickerView: View {
    let image: UIImage
    let caption: String
    let cameraViewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFriends: Set<String> = []
    @State private var mockFriends = [
        MockFriend(id: "1", name: "John Doe", username: "@johndoe"),
        MockFriend(id: "2", name: "Jane Smith", username: "@janesmith"),
        MockFriend(id: "3", name: "Mike Johnson", username: "@mikej"),
        MockFriend(id: "4", name: "Sarah Wilson", username: "@sarahw"),
        MockFriend(id: "5", name: "Alex Brown", username: "@alexb")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(mockFriends) { friend in
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(friend.name.prefix(1)))
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(friend.name)
                                .font(.headline)
                            Text(friend.username)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedFriends.contains(friend.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.yellow)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedFriends.contains(friend.id) {
                            selectedFriends.remove(friend.id)
                        } else {
                            selectedFriends.insert(friend.id)
                        }
                    }
                }
            }
            .navigationTitle("Send To")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Send") {
                    sendToSelectedFriends()
                }
                .disabled(selectedFriends.isEmpty)
            )
        }
    }
    
    private func sendToSelectedFriends() {
        for friendId in selectedFriends {
            Task {
                await cameraViewModel.sharePhoto(image, to: friendId, caption: caption.isEmpty ? nil : caption)
            }
        }
        dismiss()
    }
}

struct MockFriend: Identifiable {
    let id: String
    let name: String
    let username: String
}

#Preview {
    CapturedImageView(
        image: UIImage(systemName: "photo")!,
        cameraViewModel: CameraViewModel()
    )
}