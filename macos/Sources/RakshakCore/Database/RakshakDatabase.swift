import Foundation
import SQLite

public final class RakshakDatabase: @unchecked Sendable {
    public static let shared: RakshakDatabase = {
        do {
            return try RakshakDatabase()
        } catch {
            fatalError("Rakshak database failed to open: \(error.localizedDescription)")
        }
    }()

    private let db: Connection

    private let devices = Table("devices")
    private let colId = Expression<String>("id")
    private let colName = Expression<String>("name")
    private let colIP = Expression<String>("ip_address")
    private let colMAC = Expression<String>("mac_address")
    private let colVendor = Expression<String>("vendor")
    private let colTrusted = Expression<Bool>("is_trusted")
    private let colBlocked = Expression<Bool>("is_blocked")
    private let colLastSeen = Expression<Date>("last_seen")
    private let colFirstSeen = Expression<Date>("first_seen")
    private let colType = Expression<String>("device_type")

    private let threats = Table("threat_events")
    private let tId = Expression<String>("id")
    private let tTime = Expression<Date>("timestamp")
    private let tDomain = Expression<String>("domain")
    private let tClientIP = Expression<String>("client_ip")
    private let tClientName = Expression<String>("client_name")
    private let tCategory = Expression<String>("category")
    private let tBlocked = Expression<Bool>("was_blocked")

    private let alerts = Table("alerts")
    private let aId = Expression<String>("id")
    private let aTitle = Expression<String>("title")
    private let aMessage = Expression<String>("message")
    private let aSeverity = Expression<String>("severity")
    private let aTime = Expression<Date>("timestamp")
    private let aRead = Expression<Bool>("is_read")
    private let aAction = Expression<String?>("action_label")

    private let queryLogs = Table("dns_query_logs")
    private let qId = Expression<Int64>("id")
    private let qTime = Expression<Date>("timestamp")
    private let qDomain = Expression<String>("domain")
    private let qClient = Expression<String>("client_ip")
    private let qAction = Expression<String>("action")

    public init(path: String? = nil) throws {
        let dbPath = path ?? Self.defaultPath()
        let dir = URL(fileURLWithPath: dbPath).deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: dir.path)
        let connection = try Connection(dbPath)
        try connection.execute("PRAGMA journal_mode=WAL")
        try connection.execute("PRAGMA synchronous=NORMAL")
        db = connection
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: dbPath)
        try migrate()
    }

    public static func defaultPath() -> String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Rakshak/rakshak.db").path
    }

    private func migrate() throws {
        try db.run(devices.create(ifNotExists: true) { t in
            t.column(colId, primaryKey: true)
            t.column(colName)
            t.column(colIP)
            t.column(colMAC, unique: true)
            t.column(colVendor, defaultValue: "")
            t.column(colTrusted, defaultValue: false)
            t.column(colBlocked, defaultValue: false)
            t.column(colLastSeen)
            t.column(colFirstSeen)
            t.column(colType, defaultValue: "unknown")
        })
        try db.run(threats.create(ifNotExists: true) { t in
            t.column(tId, primaryKey: true)
            t.column(tTime)
            t.column(tDomain)
            t.column(tClientIP)
            t.column(tClientName, defaultValue: "")
            t.column(tCategory)
            t.column(tBlocked, defaultValue: true)
        })
        try db.run(alerts.create(ifNotExists: true) { t in
            t.column(aId, primaryKey: true)
            t.column(aTitle)
            t.column(aMessage)
            t.column(aSeverity)
            t.column(aTime)
            t.column(aRead, defaultValue: false)
            t.column(aAction)
        })
        try db.run(queryLogs.create(ifNotExists: true) { t in
            t.column(qId, primaryKey: .autoincrement)
            t.column(qTime)
            t.column(qDomain)
            t.column(qClient)
            t.column(qAction)
        })
        try db.run("CREATE INDEX IF NOT EXISTS idx_threats_time ON threat_events(timestamp DESC)")
        try db.run("CREATE INDEX IF NOT EXISTS idx_devices_ip ON devices(ip_address)")
    }

    // MARK: - Devices

    public func upsertDevice(_ device: NetworkDevice) throws {
        let id = device.id.uuidString
        let existing = try db.pluck(devices.filter(colMAC == device.macAddress))
        if existing != nil {
            try db.run(devices.filter(colMAC == device.macAddress).update(
                colName <- device.name,
                colIP <- device.ipAddress,
                colLastSeen <- device.lastSeen,
                colVendor <- device.vendor,
                colType <- device.deviceType.rawValue
            ))
        } else {
            try db.run(devices.insert(
                colId <- id,
                colName <- device.name,
                colIP <- device.ipAddress,
                colMAC <- device.macAddress,
                colVendor <- device.vendor,
                colTrusted <- device.isTrusted,
                colBlocked <- device.isBlocked,
                colLastSeen <- device.lastSeen,
                colFirstSeen <- device.firstSeen,
                colType <- device.deviceType.rawValue
            ))
        }
    }

    public func fetchDevices() throws -> [NetworkDevice] {
        try db.prepare(devices.order(colLastSeen.desc)).map { row in
            NetworkDevice(
                id: UUID(uuidString: row[colId]) ?? UUID(),
                name: row[colName],
                ipAddress: row[colIP],
                macAddress: row[colMAC],
                vendor: row[colVendor],
                isTrusted: row[colTrusted],
                isBlocked: row[colBlocked],
                lastSeen: row[colLastSeen],
                firstSeen: row[colFirstSeen],
                deviceType: DeviceType(rawValue: row[colType]) ?? .unknown
            )
        }
    }

    // MARK: - Threats

    public func insertThreat(_ event: ThreatEvent) throws {
        try db.run(threats.insert(
            tId <- event.id.uuidString,
            tTime <- event.timestamp,
            tDomain <- event.domain,
            tClientIP <- event.clientIP,
            tClientName <- event.clientName,
            tCategory <- event.category.rawValue,
            tBlocked <- event.wasBlocked
        ))
    }

    public func fetchRecentThreats(limit: Int = 50) throws -> [ThreatEvent] {
        try db.prepare(threats.order(tTime.desc).limit(limit)).map { row in
            ThreatEvent(
                id: UUID(uuidString: row[tId]) ?? UUID(),
                timestamp: row[tTime],
                domain: row[tDomain],
                clientIP: row[tClientIP],
                clientName: row[tClientName],
                category: ThreatCategory(rawValue: row[tCategory]) ?? .unknown,
                wasBlocked: row[tBlocked]
            )
        }
    }

    public func blockedCount(since: Date) throws -> Int {
        try db.scalar(threats.filter(tTime >= since && tBlocked == true).count)
    }

    // MARK: - Alerts

    public func insertAlert(_ alert: SecurityAlert) throws {
        try db.run(alerts.insert(
            aId <- alert.id.uuidString,
            aTitle <- alert.title,
            aMessage <- alert.message,
            aSeverity <- alert.severity.rawValue,
            aTime <- alert.timestamp,
            aRead <- alert.isRead,
            aAction <- alert.actionLabel
        ))
    }

    public func fetchAlerts(unreadOnly: Bool = false) throws -> [SecurityAlert] {
        var query = alerts.order(aTime.desc)
        if unreadOnly { query = query.filter(aRead == false) }
        return try db.prepare(query.limit(100)).map { row in
            SecurityAlert(
                id: UUID(uuidString: row[aId]) ?? UUID(),
                title: row[aTitle],
                message: row[aMessage],
                severity: AlertSeverity(rawValue: row[aSeverity]) ?? .info,
                timestamp: row[aTime],
                isRead: row[aRead],
                actionLabel: row[aAction]
            )
        }
    }

    public func markAlertRead(_ id: UUID) throws {
        try db.run(alerts.filter(aId == id.uuidString).update(aRead <- true))
    }

    // MARK: - Query logs

    public func insertQueryLog(domain: String, clientIP: String, action: String) throws {
        try db.run(queryLogs.insert(
            qTime <- Date(),
            qDomain <- domain,
            qClient <- clientIP,
            qAction <- action
        ))
    }

    public func purgeOldLogs(olderThan days: Int) throws {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return }
        try db.run(queryLogs.filter(qTime < cutoff).delete())
    }
}
