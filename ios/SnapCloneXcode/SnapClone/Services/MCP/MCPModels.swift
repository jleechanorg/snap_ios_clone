import Foundation

// MARK: - MCP Protocol Models

/// MCP Message base protocol
protocol MCPMessage: Codable {
    var jsonrpc: String { get }
    var id: String? { get }
}

/// MCP Request message
struct MCPRequest: MCPMessage {
    let jsonrpc: String = "2.0"
    let id: String?
    let method: String
    let params: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case jsonrpc, id, method, params
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        method = try container.decode(String.self, forKey: .method)
        
        // Handle params as Any
        if let paramsContainer = try? container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .params) {
            var paramsDict: [String: Any] = [:]
            for key in paramsContainer.allKeys {
                if let value = try? paramsContainer.decode(String.self, forKey: key) {
                    paramsDict[key.stringValue] = value
                } else if let value = try? paramsContainer.decode(Int.self, forKey: key) {
                    paramsDict[key.stringValue] = value
                } else if let value = try? paramsContainer.decode(Bool.self, forKey: key) {
                    paramsDict[key.stringValue] = value
                }
            }
            params = paramsDict.isEmpty ? nil : paramsDict
        } else {
            params = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(method, forKey: .method)
        
        if let params = params {
            var paramsContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .params)
            for (key, value) in params {
                let codingKey = DynamicCodingKey(stringValue: key)!
                if let stringValue = value as? String {
                    try paramsContainer.encode(stringValue, forKey: codingKey)
                } else if let intValue = value as? Int {
                    try paramsContainer.encode(intValue, forKey: codingKey)
                } else if let boolValue = value as? Bool {
                    try paramsContainer.encode(boolValue, forKey: codingKey)
                }
            }
        }
    }
}

/// MCP Response base protocol
protocol MCPResponse: Codable {
    var jsonrpc: String { get }
    var id: String? { get }
}

/// MCP Success Response
struct MCPSuccessResponse: MCPResponse {
    let jsonrpc: String = "2.0"
    let id: String?
    let result: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case jsonrpc, id, result
    }
    
    init(id: String?, result: [String: Any]) {
        self.id = id
        self.result = result
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        
        // Decode result as [String: Any]
        let resultContainer = try container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .result)
        var resultDict: [String: Any] = [:]
        for key in resultContainer.allKeys {
            if let value = try? resultContainer.decode(String.self, forKey: key) {
                resultDict[key.stringValue] = value
            } else if let value = try? resultContainer.decode(Int.self, forKey: key) {
                resultDict[key.stringValue] = value
            } else if let value = try? resultContainer.decode(Bool.self, forKey: key) {
                resultDict[key.stringValue] = value
            }
        }
        result = resultDict
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encodeIfPresent(id, forKey: .id)
        
        var resultContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .result)
        for (key, value) in result {
            let codingKey = DynamicCodingKey(stringValue: key)!
            if let stringValue = value as? String {
                try resultContainer.encode(stringValue, forKey: codingKey)
            } else if let intValue = value as? Int {
                try resultContainer.encode(intValue, forKey: codingKey)
            } else if let boolValue = value as? Bool {
                try resultContainer.encode(boolValue, forKey: codingKey)
            }
        }
    }
}

/// MCP Error Response
struct MCPErrorResponse: MCPResponse {
    let jsonrpc: String = "2.0"
    let id: String?
    let error: MCPError
}

/// MCP Error
struct MCPError: Codable {
    let code: Int
    let message: String
    let data: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case code, message, data
    }
    
    init(code: Int, message: String, data: [String: Any]? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Int.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)
        
        if let dataContainer = try? container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .data) {
            var dataDict: [String: Any] = [:]
            for key in dataContainer.allKeys {
                if let value = try? dataContainer.decode(String.self, forKey: key) {
                    dataDict[key.stringValue] = value
                }
            }
            data = dataDict.isEmpty ? nil : dataDict
        } else {
            data = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(message, forKey: .message)
        
        if let data = data {
            var dataContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .data)
            for (key, value) in data {
                let codingKey = DynamicCodingKey(stringValue: key)!
                if let stringValue = value as? String {
                    try dataContainer.encode(stringValue, forKey: codingKey)
                }
            }
        }
    }
}

// MARK: - MCP Capabilities

/// MCP Server Capabilities
struct MCPCapabilities {
    let tools: [MCPTool]
    let resources: [MCPResource]
    
    init() {
        self.tools = [
            MCPTool(
                name: "capture_photo",
                description: "Capture a photo using the device camera",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "quality": [
                            "type": "string",
                            "enum": ["low", "medium", "high"],
                            "description": "Photo quality setting"
                        ]
                    ]
                ]
            ),
            MCPTool(
                name: "send_snap",
                description: "Send a snap to friends",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "recipients": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": "List of recipient user IDs"
                        ],
                        "duration": [
                            "type": "number",
                            "description": "Snap duration in seconds (1-10)"
                        ]
                    ],
                    "required": ["recipients"]
                ]
            ),
            MCPTool(
                name: "get_friends",
                description: "Get list of user's friends",
                inputSchema: [
                    "type": "object",
                    "properties": [:]
                ]
            )
        ]
        
        self.resources = [
            MCPResource(
                uri: "snap://camera/status",
                name: "Camera Status",
                description: "Current camera availability and permissions"
            ),
            MCPResource(
                uri: "snap://user/profile",
                name: "User Profile",
                description: "Current user's profile information"
            ),
            MCPResource(
                uri: "snap://friends/list",
                name: "Friends List",
                description: "List of user's friends"
            )
        ]
    }
}

/// MCP Tool Definition
struct MCPTool: Codable {
    let name: String
    let description: String
    let inputSchema: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case name, description, inputSchema
    }
    
    init(name: String, description: String, inputSchema: [String: Any]) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        inputSchema = [:]  // Simplified for demo
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        // Simplified encoding for demo
    }
}

/// MCP Resource Definition
struct MCPResource: Codable {
    let uri: String
    let name: String
    let description: String
}

// MARK: - Dynamic Coding Key

struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}