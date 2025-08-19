import Foundation
import Network
import os.log

/// iOS Model Context Protocol (MCP) Server
/// Provides MCP capabilities to external clients, enabling AI integration with the Snap Clone app
class MCPServer: ObservableObject {
    
    // MARK: - Properties
    private let listener: NWListener
    private let logger = Logger(subsystem: "com.snapclone.mcp", category: "server")
    private var connections: Set<MCPConnection> = []
    private let queue = DispatchQueue(label: "mcp.server.queue")
    
    @Published var isRunning: Bool = false
    @Published var connectedClients: Int = 0
    
    // MCP Server Configuration
    private let port: UInt16
    private let capabilities = MCPCapabilities()
    
    // MARK: - Initialization
    init(port: UInt16 = 8090) {
        self.port = port
        
        // Create TCP listener
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            parameters.acceptLocalOnly = true
            
            self.listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: port))
        } catch {
            fatalError("Failed to create MCP listener: \(error)")
        }
        
        setupListener()
    }
    
    // MARK: - Server Control
    func start() {
        guard !isRunning else { return }
        
        listener.start(queue: queue)
        
        DispatchQueue.main.async {
            self.isRunning = true
        }
        
        logger.info("MCP Server started on port \(self.port)")
    }
    
    func stop() {
        guard isRunning else { return }
        
        listener.cancel()
        
        // Close all connections
        connections.forEach { $0.close() }
        connections.removeAll()
        
        DispatchQueue.main.async {
            self.isRunning = false
            self.connectedClients = 0
        }
        
        logger.info("MCP Server stopped")
    }
    
    // MARK: - Private Methods
    private func setupListener() {
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }
        
        listener.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.logger.info("MCP Listener ready")
            case .failed(let error):
                self?.logger.error("MCP Listener failed: \(error.localizedDescription)")
            case .cancelled:
                self?.logger.info("MCP Listener cancelled")
            default:
                break
            }
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        let mcpConnection = MCPConnection(connection: connection, server: self)
        connections.insert(mcpConnection)
        
        DispatchQueue.main.async {
            self.connectedClients = self.connections.count
        }
        
        logger.info("New MCP client connected. Total clients: \(connections.count)")
    }
    
    func removeConnection(_ mcpConnection: MCPConnection) {
        connections.remove(mcpConnection)
        
        DispatchQueue.main.async {
            self.connectedClients = self.connections.count
        }
        
        logger.info("MCP client disconnected. Total clients: \(connections.count)")
    }
}

// MARK: - MCP Connection Handler
class MCPConnection: NSObject, Hashable {
    
    private let connection: NWConnection
    private weak var server: MCPServer?
    private let logger = Logger(subsystem: "com.snapclone.mcp", category: "connection")
    private let messageHandler = MCPMessageHandler()
    
    init(connection: NWConnection, server: MCPServer) {
        self.connection = connection
        self.server = server
        super.init()
        
        startConnection()
    }
    
    private func startConnection() {
        connection.start(queue: DispatchQueue(label: "mcp.connection"))
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.logger.info("MCP connection ready")
                self?.receiveMessage()
            case .failed(let error):
                self?.logger.error("MCP connection failed: \(error.localizedDescription)")
                self?.cleanup()
            case .cancelled:
                self?.logger.info("MCP connection cancelled")
                self?.cleanup()
            default:
                break
            }
        }
    }
    
    private func receiveMessage() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            
            if let error = error {
                self?.logger.error("Receive error: \(error.localizedDescription)")
                self?.cleanup()
                return
            }
            
            if let data = data, !data.isEmpty {
                self?.handleReceivedData(data)
            }
            
            if isComplete {
                self?.cleanup()
            } else {
                self?.receiveMessage()
            }
        }
    }
    
    private func handleReceivedData(_ data: Data) {
        do {
            if let message = try messageHandler.parseMessage(data) {
                let response = try messageHandler.processMessage(message)
                sendResponse(response)
            }
        } catch {
            logger.error("Message handling error: \(error.localizedDescription)")
            
            // Send error response
            let errorResponse = MCPErrorResponse(
                id: nil,
                error: MCPError(code: -1, message: error.localizedDescription)
            )
            sendResponse(errorResponse)
        }
    }
    
    private func sendResponse(_ response: MCPResponse) {
        do {
            let responseData = try messageHandler.encodeResponse(response)
            connection.send(content: responseData, completion: .contentProcessed { [weak self] error in
                if let error = error {
                    self?.logger.error("Send error: \(error.localizedDescription)")
                }
            })
        } catch {
            logger.error("Response encoding error: \(error.localizedDescription)")
        }
    }
    
    func close() {
        connection.cancel()
    }
    
    private func cleanup() {
        server?.removeConnection(self)
    }
    
    // MARK: - Hashable
    static func == (lhs: MCPConnection, rhs: MCPConnection) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}