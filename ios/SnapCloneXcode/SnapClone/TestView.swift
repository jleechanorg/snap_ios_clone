//
// TestView.swift 
// SnapClone
//
// 🚀🚀🚀 CEREBRAS GENERATED IN 1868ms 🚀🚀🚀
// Minimal test to verify button state functionality

import SwiftUI

struct TestView: View {
    @State private var isAuthenticated = false
    
    var body: some View {
        VStack {
            Text("Current State:")
                .font(.headline)
            
            Text(isAuthenticated ? "✅ Authenticated" : "❌ Not Authenticated")
                .font(.title)
                .padding()
                .foregroundColor(isAuthenticated ? .green : .red)
            
            Button(action: {
                print("🔍 DEBUG: Button tapped! Before: \(isAuthenticated)")
                isAuthenticated.toggle()
                print("🔍 DEBUG: Button tapped! After: \(isAuthenticated)")
            }) {
                Text("Toggle Authentication")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            
            Text("Tap count test")
                .font(.caption)
                .padding()
        }
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}