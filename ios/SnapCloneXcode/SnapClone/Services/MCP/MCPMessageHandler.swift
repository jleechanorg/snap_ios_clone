import Foundation
import os.log

/// Handles MCP message parsing and processing
class MCPMessageHandler {
    
    private let logger = Logger(subsystem: "com.snapclone.mcp", category: "handler")
    private let capabilities = MCPCapabilities()
    
    // MARK: - Message Parsing
    
    func parseMessage(_ data: Data) throws -> MCPRequest? {
        // Handle line-delimited JSON (common in MCP)
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        let lines = jsonString.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard let firstLine = lines.first else {
            return nil
        }
        
        guard let lineData = firstLine.data(using: .utf8) else {
            throw MCPError(code: -32700, message: "Parse error: Invalid UTF-8")
        }
        
        do {
            let request = try JSONDecoder().decode(MCPRequest.self, from: lineData)
            logger.info("Received MCP request: \(request.method)")
            return request
        } catch {
            throw MCPError(code: -32700, message: "Parse error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Message Processing
    
    func processMessage(_ request: MCPRequest) throws -> MCPResponse {
        logger.info("Processing MCP method: \(request.method)")
        
        switch request.method {
        case "initialize":
            return try handleInitialize(request)
        case "tools/list":
            return try handleToolsList(request)
        case "tools/call":
            return try handleToolsCall(request)
        case "resources/list":
            return try handleResourcesList(request)
        case "resources/read":
            return try handleResourcesRead(request)
        default:
            throw MCPError(code: -32601, message: "Method not found: \(request.method)")
        }
    }
    
    // MARK: - Response Encoding
    
    func encodeResponse(_ response: MCPResponse) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        let jsonData = try encoder.encode(response)
        
        // Add newline for line-delimited JSON
        var responseData = jsonData
        responseData.append("\n".data(using: .utf8)!)
        
        return responseData
    }
    
    // MARK: - Handler Methods
    
    private func handleInitialize(_ request: MCPRequest) throws -> MCPResponse {
        let result: [String: Any] = [
            "protocolVersion": "2024-11-05",
            "capabilities": [
                "tools": ["listChanged": true],
                "resources": ["listChanged": true, "subscribe": false]
            ],
            "serverInfo": [
                "name": "snap-clone-ios",
                "version": "1.0.0",
                "description": "iOS Snapchat Clone MCP Server"
            ]
        ]
        
        return MCPSuccessResponse(id: request.id, result: result)
    }
    
    private func handleToolsList(_ request: MCPRequest) throws -> MCPResponse {
        let tools = capabilities.tools.map { tool in
            [
                "name": tool.name,
                "description": tool.description,
                "inputSchema": tool.inputSchema
            ]
        }
        
        let result: [String: Any] = [
            "tools": tools
        ]
        
        return MCPSuccessResponse(id: request.id, result: result)
    }
    
    private func handleToolsCall(_ request: MCPRequest) throws -> MCPResponse {
        guard let params = request.params,
              let toolName = params["name"] as? String else {
            throw MCPError(code: -32602, message: "Invalid params: missing tool name")
        }
        
        let arguments = params["arguments"] as? [String: Any] ?? [:]
        
        let result = try executeToolCall(toolName: toolName, arguments: arguments)
        
        return MCPSuccessResponse(id: request.id, result: ["content": [result]])
    }
    
    private func handleResourcesList(_ request: MCPRequest) throws -> MCPResponse {
        let resources = capabilities.resources.map { resource in
            [
                "uri": resource.uri,
                "name": resource.name,
                "description": resource.description
            ]
        }
        
        let result: [String: Any] = [
            "resources": resources
        ]
        
        return MCPSuccessResponse(id: request.id, result: result)
    }
    
    private func handleResourcesRead(_ request: MCPRequest) throws -> MCPResponse {
        guard let params = request.params,
              let uri = params["uri"] as? String else {
            throw MCPError(code: -32602, message: "Invalid params: missing URI")
        }
        
        let content = try readResource(uri: uri)
        
        let result: [String: Any] = [
            "contents": [content]
        ]
        
        return MCPSuccessResponse(id: request.id, result: result)
    }
    
    // MARK: - Tool Execution
    
    private func executeToolCall(toolName: String, arguments: [String: Any]) throws -> [String: Any] {
        switch toolName {
        case "capture_photo":
            return try executeCapturePhoto(arguments: arguments)
        case "send_snap":
            return try executeSendSnap(arguments: arguments)
        case "get_friends":
            return try executeGetFriends(arguments: arguments)
        default:
            throw MCPError(code: -32601, message: "Unknown tool: \(toolName)")
        }
    }
    
    private func executeCapturePhoto(arguments: [String: Any]) throws -> [String: Any] {
        let quality = arguments["quality"] as? String ?? "medium"
        
        // In a real implementation, this would trigger the camera
        logger.info("Capturing photo with quality: \(quality)")
        
        return [
            "type": "text",
            "text": "Photo captured successfully with \(quality) quality. Photo saved to device gallery."
        ]
    }
    
    private func executeSendSnap(arguments: [String: Any]) throws -> [String: Any] {
        guard let recipients = arguments["recipients"] as? [String] else {
            throw MCPError(code: -32602, message: "Invalid arguments: recipients required")
        }
        
        let duration = arguments["duration"] as? Int ?? 5
        
        // In a real implementation, this would send the snap
        logger.info("Sending snap to \(recipients.count) recipients for \(duration) seconds")
        
        return [
            "type": "text",
            "text": "Snap sent successfully to \(recipients.count) recipients with \(duration) second duration."
        ]
    }
    
    private func executeGetFriends(arguments: [String: Any]) throws -> [String: Any] {
        // In a real implementation, this would fetch from the friends service
        let friends = [
            ["id": "user1", "username": "john_doe", "displayName": "John Doe"],
            ["id": "user2", "username": "jane_smith", "displayName": "Jane Smith"],
            ["id": "user3", "username": "mike_wilson", "displayName": "Mike Wilson"]
        ]
        
        logger.info("Retrieved \(friends.count) friends")
        
        return [
            "type": "text",
            "text": "Found \(friends.count) friends:\n" + friends.map { friend in
                "- \(friend["displayName"] ?? "Unknown") (@\(friend["username"] ?? "unknown"))"
            }.joined(separator: "\n")
        ]
    }
    
    // MARK: - Resource Reading
    
    private func readResource(uri: String) throws -> [String: Any] {
        switch uri {
        case "snap://camera/status":
            return readCameraStatus()
        case "snap://user/profile":
            return readUserProfile()
        case "snap://friends/list":
            return readFriendsList()
        default:
            throw MCPError(code: -32602, message: "Unknown resource URI: \(uri)")
        }
    }
    
    private func readCameraStatus() -> [String: Any] {
        return [
            "uri": "snap://camera/status",
            "mimeType": "application/json",
            "text": """
            {
                "available": true,
                "permission": "granted",
                "front_camera": true,
                "back_camera": true,
                "flash_available": true
            }
            """
        ]
    }
    
    private func readUserProfile() -> [String: Any] {
        return [
            "uri": "snap://user/profile",
            "mimeType": "application/json",
            "text": """
            {
                "id": "current_user",
                "username": "snapuser123",
                "displayName": "Snap User",
                "email": "user@example.com",
                "snapScore": 1250,
                "verified": false
            }
            """
        ]
    }
    
    private func readFriendsList() -> [String: Any] {
        return [
            "uri": "snap://friends/list",
            "mimeType": "application/json",
            "text": """
            {
                "friends": [
                    {
                        "id": "user1",
                        "username": "john_doe",
                        "displayName": "John Doe",
                        "snapScore": 850,
                        "lastSeen": "2024-08-19T20:30:00Z"
                    },
                    {
                        "id": "user2",
                        "username": "jane_smith",
                        "displayName": "Jane Smith",
                        "snapScore": 1500,
                        "lastSeen": "2024-08-19T19:45:00Z"
                    },
                    {
                        "id": "user3",
                        "username": "mike_wilson",
                        "displayName": "Mike Wilson",
                        "snapScore": 620,
                        "lastSeen": "2024-08-19T18:20:00Z"
                    }
                ],
                "total": 3
            }
            """
        ]
    }
}