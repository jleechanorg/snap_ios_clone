import SwiftUI

/// MCP Server Settings and Control View
struct MCPServerView: View {
    
    @StateObject private var mcpServer = MCPServer()
    @State private var showingAdvancedSettings = false
    @State private var customPort: String = "8090"
    
    var body: some View {
        NavigationView {
            List {
                // Server Status Section
                Section(header: Text("Server Status")) {
                    HStack {
                        Circle()
                            .fill(mcpServer.isRunning ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text(mcpServer.isRunning ? "Running" : "Stopped")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button(mcpServer.isRunning ? "Stop" : "Start") {
                            if mcpServer.isRunning {
                                mcpServer.stop()
                            } else {
                                mcpServer.start()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(mcpServer.isRunning ? .red : .green)
                    }
                    
                    if mcpServer.isRunning {
                        HStack {
                            Text("Connected Clients")
                            Spacer()
                            Text("\(mcpServer.connectedClients)")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Server Port")
                            Spacer()
                            Text("8090")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                // Capabilities Section
                Section(header: Text("Available Tools")) {
                    CapabilityRow(
                        icon: "camera.fill",
                        title: "Capture Photo",
                        description: "Take photos using device camera"
                    )
                    
                    CapabilityRow(
                        icon: "paperplane.fill",
                        title: "Send Snap",
                        description: "Send snaps to friends"
                    )
                    
                    CapabilityRow(
                        icon: "person.2.fill",
                        title: "Get Friends",
                        description: "Retrieve friends list"
                    )
                }
                
                Section(header: Text("Available Resources")) {
                    ResourceRow(
                        title: "Camera Status",
                        uri: "snap://camera/status",
                        description: "Camera availability and permissions"
                    )
                    
                    ResourceRow(
                        title: "User Profile",
                        uri: "snap://user/profile",
                        description: "Current user information"
                    )
                    
                    ResourceRow(
                        title: "Friends List",
                        uri: "snap://friends/list",
                        description: "Complete friends data"
                    )
                }
                
                // Connection Info Section
                Section(header: Text("Connection Information")) {
                    InfoRow(title: "Protocol", value: "MCP (Model Context Protocol)")
                    InfoRow(title: "Version", value: "2024-11-05")
                    InfoRow(title: "Transport", value: "TCP")
                    InfoRow(title: "Format", value: "JSON-RPC 2.0")
                }
                
                // Advanced Settings
                Section(header: Text("Advanced")) {
                    Button("Advanced Settings") {
                        showingAdvancedSettings.toggle()
                    }
                    .foregroundColor(.blue)
                }
                
                // Usage Instructions
                Section(header: Text("Usage")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To connect MCP clients:")
                            .fontWeight(.semibold)
                        
                        Text("1. Start the server above")
                        Text("2. Connect clients to localhost:8090")
                        Text("3. Use tools and resources via MCP protocol")
                        
                        Text("\nExample client connection:")
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        
                        Text("mcp-client tcp://localhost:8090")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("MCP Server")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAdvancedSettings) {
            AdvancedMCPSettingsView(customPort: $customPort)
        }
    }
}

// MARK: - Supporting Views

struct CapabilityRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct ResourceRow: View {
    let title: String
    let uri: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .fontWeight(.medium)
            
            Text(uri)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.blue)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct AdvancedMCPSettingsView: View {
    @Binding var customPort: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Configuration")) {
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("8090", text: $customPort)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }
                
                Section(header: Text("Security")) {
                    Toggle("Local Only", isOn: .constant(true))
                        .disabled(true)
                    
                    HStack {
                        Text("Allowed Hosts")
                        Spacer()
                        Text("localhost, 127.0.0.1")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Protocol Options")) {
                    Toggle("Enable Keep-Alive", isOn: .constant(true))
                        .disabled(true)
                    
                    HStack {
                        Text("Max Connections")
                        Spacer()
                        Text("10")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Advanced Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MCPServerView()
}