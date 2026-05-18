import Foundation

public enum ThreatCategory: String, Codable, CaseIterable, Sendable {
    case ads, trackers, malware, phishing, scam, telemetry, miners, exploits, unknown

    public var displayName: String {
        switch self {
        case .ads: return "Ads"
        case .trackers: return "Trackers"
        case .malware: return "Malware"
        case .phishing: return "Phishing"
        case .scam: return "Scam"
        case .telemetry: return "Telemetry"
        case .miners: return "Crypto miners"
        case .exploits: return "Exploits"
        case .unknown: return "Unknown"
        }
    }

    public var icon: String {
        switch self {
        case .ads: return "rectangle.slash"
        case .trackers: return "eye.slash"
        case .malware: return "ladybug"
        case .phishing: return "fish"
        case .scam: return "exclamationmark.shield"
        case .telemetry: return "antenna.radiowaves.left.and.right.slash"
        case .miners: return "bitcoinsign.circle"
        case .exploits: return "bolt.shield"
        case .unknown: return "questionmark.circle"
        }
    }
}

public struct NetworkDevice: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var ipAddress: String
    public var macAddress: String
    public var vendor: String
    public var isTrusted: Bool
    public var isBlocked: Bool
    public var lastSeen: Date
    public var firstSeen: Date
    public var deviceType: DeviceType

    public init(
        id: UUID = UUID(),
        name: String,
        ipAddress: String,
        macAddress: String,
        vendor: String = "",
        isTrusted: Bool = false,
        isBlocked: Bool = false,
        lastSeen: Date = .now,
        firstSeen: Date = .now,
        deviceType: DeviceType = .unknown
    ) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.vendor = vendor
        self.isTrusted = isTrusted
        self.isBlocked = isBlocked
        self.lastSeen = lastSeen
        self.firstSeen = firstSeen
        self.deviceType = deviceType
    }
}

public enum DeviceType: String, Codable, CaseIterable, Sendable {
    case phone, tablet, computer, tv, iot, router, unknown

    public var icon: String {
        switch self {
        case .phone: return "iphone"
        case .tablet: return "ipad"
        case .computer: return "desktopcomputer"
        case .tv: return "tv"
        case .iot: return "homepodmini"
        case .router: return "wifi.router"
        case .unknown: return "questionmark.square.dashed"
        }
    }
}

public struct ThreatEvent: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var timestamp: Date
    public var domain: String
    public var clientIP: String
    public var clientName: String
    public var category: ThreatCategory
    public var wasBlocked: Bool

    public init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        domain: String,
        clientIP: String,
        clientName: String = "",
        category: ThreatCategory,
        wasBlocked: Bool = true
    ) {
        self.id = id
        self.timestamp = timestamp
        self.domain = domain
        self.clientIP = clientIP
        self.clientName = clientName
        self.category = category
        self.wasBlocked = wasBlocked
    }
}

public struct ProtectionStats: Codable, Sendable {
    public var blockedToday: Int
    public var allowedToday: Int
    public var activeDevices: Int
    public var blocklistDomains: Int
    public var protectionEnabled: Bool
    public var dnsRunning: Bool
    public var firewallEnabled: Bool
    public var lanIPAddress: String

    public init(
        blockedToday: Int = 0,
        allowedToday: Int = 0,
        activeDevices: Int = 0,
        blocklistDomains: Int = 0,
        protectionEnabled: Bool = false,
        dnsRunning: Bool = false,
        firewallEnabled: Bool = false,
        lanIPAddress: String = ""
    ) {
        self.blockedToday = blockedToday
        self.allowedToday = allowedToday
        self.activeDevices = activeDevices
        self.blocklistDomains = blocklistDomains
        self.protectionEnabled = protectionEnabled
        self.dnsRunning = dnsRunning
        self.firewallEnabled = firewallEnabled
        self.lanIPAddress = lanIPAddress
    }

    public static let empty = ProtectionStats()
}

public struct SecurityAlert: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var message: String
    public var severity: AlertSeverity
    public var timestamp: Date
    public var isRead: Bool
    public var actionLabel: String?

    public init(
        id: UUID = UUID(),
        title: String,
        message: String,
        severity: AlertSeverity,
        timestamp: Date = .now,
        isRead: Bool = false,
        actionLabel: String? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.severity = severity
        self.timestamp = timestamp
        self.isRead = isRead
        self.actionLabel = actionLabel
    }
}

public enum AlertSeverity: String, Codable, Sendable {
    case info, warning, critical

    public var colorName: String {
        switch self {
        case .info: return "accent"
        case .warning: return "warning"
        case .critical: return "danger"
        }
    }
}

public struct AppSettings: Codable, Sendable {
    public var protectionEnabled: Bool
    public var blockAds: Bool
    public var blockMalware: Bool
    public var blockPhishing: Bool
    public var blockTrackers: Bool
    public var blockMiners: Bool
    public var forceDNS: Bool
    public var showMenuBarExtra: Bool
    public var notifyOnThreat: Bool
    public var onboardingComplete: Bool
    public var routerDNSConfigured: Bool

    public init(
        protectionEnabled: Bool = true,
        blockAds: Bool = true,
        blockMalware: Bool = true,
        blockPhishing: Bool = true,
        blockTrackers: Bool = true,
        blockMiners: Bool = true,
        forceDNS: Bool = false,
        showMenuBarExtra: Bool = true,
        notifyOnThreat: Bool = true,
        onboardingComplete: Bool = false,
        routerDNSConfigured: Bool = false
    ) {
        self.protectionEnabled = protectionEnabled
        self.blockAds = blockAds
        self.blockMalware = blockMalware
        self.blockPhishing = blockPhishing
        self.blockTrackers = blockTrackers
        self.blockMiners = blockMiners
        self.forceDNS = forceDNS
        self.showMenuBarExtra = showMenuBarExtra
        self.notifyOnThreat = notifyOnThreat
        self.onboardingComplete = onboardingComplete
        self.routerDNSConfigured = routerDNSConfigured
    }
}

public enum DaemonStatus: String, Codable, Sendable {
    case running, stopped, starting, error
}

public struct DaemonState: Codable, Sendable {
    public var status: DaemonStatus
    public var message: String
    public var stats: ProtectionStats
    public var updatedAt: Date

    public init(status: DaemonStatus, message: String, stats: ProtectionStats, updatedAt: Date = .now) {
        self.status = status
        self.message = message
        self.stats = stats
        self.updatedAt = updatedAt
    }
}
