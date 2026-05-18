import Foundation
import Network
import RakshakCore
import os

/// Local-only HTTP + WebSocket on 127.0.0.1 — authenticated via shared token file.
public final class LocalAPIServer: @unchecked Sendable {
    public static let defaultPort: UInt16 = 9847
    public static let wsPath = "/ws"
    public static let tokenHeader = DaemonAuthToken.headerName

    private let log = Logger(subsystem: "com.rakshak.ipc", category: "api")
    private var listener: NWListener?
    private var wsConnections: [NWConnection] = []
    private let queue = DispatchQueue(label: "com.rakshak.ipc.server")
    private var authToken: String = ""

    public var stateProvider: (() -> DaemonState)?
    public var onCommand: ((APICommand) -> Void)?

    public init() {}

    public func start(port: UInt16 = defaultPort) throws {
        authToken = try DaemonAuthToken.loadOrCreate()
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        params.requiredInterfaceType = .loopback
        guard let portEndpoint = NWEndpoint.Port(rawValue: port) else { throw IPCError.invalidPort }
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: portEndpoint)
        listener = try NWListener(using: params, on: portEndpoint)
        listener?.stateUpdateHandler = { [weak self] state in
            if case .failed(let err) = state {
                self?.log.error("Listener failed: \(err.localizedDescription)")
            }
        }
        listener?.newConnectionHandler = { [weak self] conn in
            self?.handle(conn)
        }
        listener?.start(queue: queue)
        log.info("Local API listening on 127.0.0.1:\(port)")
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        wsConnections.forEach { $0.cancel() }
        wsConnections.removeAll()
    }

    public func broadcast(event: String, payload: [String: Any]) {
        let msg: [String: Any] = ["event": event, "data": payload, "ts": ISO8601DateFormatter().string(from: Date())]
        guard let data = try? JSONSerialization.data(withJSONObject: msg) else { return }
        let frame = Self.wsFrame(data: data)
        wsConnections.forEach { conn in
            conn.send(content: frame, completion: .contentProcessed { _ in })
        }
    }

    private func handle(_ conn: NWConnection) {
        conn.start(queue: queue)
        receiveHTTP(conn, buffer: Data())
    }

    private func receiveHTTP(_ conn: NWConnection, buffer: Data) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if error != nil {
                conn.cancel()
                return
            }
            var buf = buffer
            if let data { buf.append(data) }
            guard let request = String(data: buf, encoding: .utf8), request.contains("\r\n\r\n") else {
                if isComplete {
                    conn.cancel()
                    return
                }
                self.receiveHTTP(conn, buffer: buf)
                return
            }
            let response = self.route(request: request, connection: conn)
            let isWS = response.contains("101 Switching")
            conn.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
                if isWS {
                    self.wsConnections.append(conn)
                    self.receiveWebSocketFrames(conn)
                } else {
                    conn.cancel()
                }
            })
        }
    }

    private func receiveWebSocketFrames(_ conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] _, _, isComplete, _ in
            guard let self else { return }
            if isComplete {
                self.wsConnections.removeAll { $0 === conn }
                conn.cancel()
                return
            }
            self.receiveWebSocketFrames(conn)
        }
    }

    private func route(request: String, connection: NWConnection) -> String {
        let lines = request.split(separator: "\r\n", maxSplits: 1)
        guard let first = lines.first else { return httpResponse(400, body: #"{"error":"bad request"}"#) }
        let parts = first.split(separator: " ")
        guard parts.count >= 2 else { return httpResponse(400, body: #"{"error":"bad request"}"#) }
        let method = String(parts[0])
        let path = String(parts[1])

        if method == "GET" && path == "/ws" {
            guard authorized(request: request) else {
                return httpResponse(401, body: #"{"error":"unauthorized"}"#)
            }
            return wsHandshake(request: request)
        }

        if !authorized(request: request) {
            return httpResponse(401, body: #"{"error":"unauthorized"}"#)
        }

        if method == "GET" && path == "/api/v1/state" {
            let state = stateProvider?() ?? DaemonState(status: .stopped, message: "", stats: .empty, updatedAt: .now)
            if let json = try? JSONEncoder().encode(state), let str = String(data: json, encoding: .utf8) {
                return httpResponse(200, body: str)
            }
        }

        if method == "POST" && path == "/api/v1/protection/enable" {
            onCommand?(.enableProtection)
            return httpResponse(200, body: #"{"ok":true}"#)
        }
        if method == "POST" && path == "/api/v1/protection/disable" {
            onCommand?(.disableProtection)
            return httpResponse(200, body: #"{"ok":true}"#)
        }
        if method == "POST" && path == "/api/v1/blocklist/rebuild" {
            onCommand?(.rebuildBlocklist)
            return httpResponse(200, body: #"{"ok":true}"#)
        }
        if method == "POST" && path == "/api/v1/devices/scan" {
            onCommand?(.scanDevices)
            return httpResponse(200, body: #"{"ok":true}"#)
        }

        return httpResponse(404, body: #"{"error":"not found"}"#)
    }

    private func authorized(request: String) -> Bool {
        for line in request.split(separator: "\r\n") {
            let lower = line.lowercased()
            if lower.hasPrefix("\(Self.tokenHeader.lowercased()):") {
                let token = line.split(separator: ":", maxSplits: 1).last?
                    .trimmingCharacters(in: .whitespaces) ?? ""
                return DaemonAuthToken.matches(provided: token, expected: authToken)
            }
        }
        return false
    }

    private func httpResponse(_ code: Int, body: String) -> String {
        let status: String
        switch code {
        case 200: status = "OK"
        case 401: status = "Unauthorized"
        case 404: status = "Not Found"
        default: status = "Bad Request"
        }
        return """
        HTTP/1.1 \(code) \(status)\r
        Content-Type: application/json\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r
        \(body)
        """
    }

    private func wsHandshake(request: String) -> String {
        guard let keyLine = request.split(separator: "\r\n").first(where: { $0.lowercased().hasPrefix("sec-websocket-key:") }) else {
            return httpResponse(400, body: "{}")
        }
        let key = keyLine.split(separator: ":", maxSplits: 1).last.map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
        let accept = Self.wsAccept(key: String(key))
        return """
        HTTP/1.1 101 Switching Protocols\r
        Upgrade: websocket\r
        Connection: Upgrade\r
        Sec-WebSocket-Accept: \(accept)\r
        \r

        """
    }

    private static func wsAccept(key: String) -> String {
        let magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        let hash = CryptoKit.Insecure.SHA1.hash(data: Data((key + magic).utf8))
        return Data(hash).base64EncodedString()
    }

    private static func wsFrame(data: Data) -> Data {
        var frame = Data([0x81])
        let len = data.count
        if len < 126 {
            frame.append(UInt8(len))
        } else {
            frame.append(126)
            frame.append(UInt8((len >> 8) & 0xFF))
            frame.append(UInt8(len & 0xFF))
        }
        frame.append(data)
        return frame
    }

    public enum APICommand: Sendable {
        case enableProtection, disableProtection, rebuildBlocklist, scanDevices
    }

    public enum IPCError: Error {
        case invalidPort
    }
}

import CryptoKit
