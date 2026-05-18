import Foundation
import RakshakCore

/// Local HTTP client — 127.0.0.1 only, no cloud.
actor DaemonAPIClient {
    private let base = URL(string: "http://127.0.0.1:9847")!

    private func authHeaders() -> [String: String] {
        guard let token = DaemonAuthToken.load() else { return [:] }
        return [DaemonAuthToken.headerName: token]
    }

    func fetchState() async -> DaemonState? {
        guard let url = URL(string: "/api/v1/state", relativeTo: base) else { return nil }
        var req = URLRequest(url: url)
        req.timeoutInterval = 3
        for (k, v) in authHeaders() { req.setValue(v, forHTTPHeaderField: k) }
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try? JSONDecoder().decode(DaemonState.self, from: data)
    }

    func post(_ path: String) async {
        guard let url = URL(string: path, relativeTo: base) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 10
        for (k, v) in authHeaders() { req.setValue(v, forHTTPHeaderField: k) }
        _ = try? await URLSession.shared.data(for: req)
    }
}
