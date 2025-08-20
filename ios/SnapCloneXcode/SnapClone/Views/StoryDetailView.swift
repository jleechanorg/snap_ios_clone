//
//  StoryDetailView.swift
//  SnapClone
//
//  Created by Claude Code on 2025-08-19.
//  Purpose: Full-screen story viewing with ephemeral behavior
//  Requirements: iOS 16+, Firebase integration
//

import SwiftUI

struct StoryDetailView: View {
    let story: Story
    @Environment(\.dismiss) private var dismiss
    @State private var viewProgress: Double = 0
    @State private var timer: Timer?
    @State private var showCaption = true
    
    private let viewDuration: Double = 10.0 // 10 seconds
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Story Image/Video
            AsyncImage(url: URL(string: story.mediaURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
                    .tint(.white)
            }
            
            // Progress Bar
            VStack {
                HStack {
                    ProgressView(value: viewProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    Button("×") {
                        dismiss()
                    }
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.leading, 10)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
            }
            
            // Story Header
            VStack {
                HStack {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(story.username.prefix(1).uppercased()))
                                .font(.headline)
                                .foregroundColor(.black)
                        )
                    
                    VStack(alignment: .leading) {
                        Text(story.username)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(story.timeAgo)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 60)
                
                Spacer()
            }
            
            // Caption
            if let caption = story.caption, showCaption {
                VStack {
                    Spacer()
                    
                    HStack {
                        Text(caption)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            
            // Tap Gestures
            HStack {
                // Left side - go back
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Previous story logic
                        dismiss()
                    }
                
                // Right side - go forward
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Next story logic
                        dismiss()
                    }
            }
        }
        .onAppear {
            startStoryTimer()
        }
        .onDisappear {
            stopStoryTimer()
        }
    }
    
    private func startStoryTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                viewProgress += 0.1 / viewDuration
            }
            
            if viewProgress >= 1.0 {
                dismiss()
            }
        }
    }
    
    private func stopStoryTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    StoryDetailView(story: Story.mockStories.first!)
}