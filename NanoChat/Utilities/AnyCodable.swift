import Foundation

// Wrapper for mixed types in JSON
public struct AnyCodable: Codable, Hashable, CustomStringConvertible, @unchecked Sendable {
    public let value: Any
    
    public var description: String {
        return "\(value)"
    }

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal.map { $0.value }
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if value is NSNull {
            try container.encodeNil()
        } else if let intVal = value as? Int {
            try container.encode(intVal)
        } else if let doubleVal = value as? Double {
            try container.encode(doubleVal)
        } else if let boolVal = value as? Bool {
            try container.encode(boolVal)
        } else if let stringVal = value as? String {
            try container.encode(stringVal)
        } else if let arrayVal = value as? [Any] {
            try container.encode(arrayVal.map { AnyCodable($0) })
        } else if let dictVal = value as? [String: Any] {
            try container.encode(dictVal.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
    
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (is NSNull, is NSNull): return true
        case (let l as Int, let r as Int): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as Bool, let r as Bool): return l == r
        case (let l as String, let r as String): return l == r
        case (let l as [Any], let r as [Any]):
            return l.count == r.count // Simplistic check for arrays
        case (let l as [String: Any], let r as [String: Any]):
            return l.keys == r.keys // Simplistic check for dicts
        default: return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        if value is NSNull { hasher.combine(0) }
        else if let v = value as? Int { hasher.combine(v) }
        else if let v = value as? Double { hasher.combine(v) }
        else if let v = value as? Bool { hasher.combine(v) }
        else if let v = value as? String { hasher.combine(v) }
        // Complex types fallback (not ideal for hash but prevents crashes)
    }
    
    // Helper to get typed value
    public var stringValue: String? { value as? String }
    public var intValue: Int? { value as? Int }
    public var doubleValue: Double? { value as? Double }
    public var boolValue: Bool? { value as? Bool }
    public var arrayValue: [Any]? { value as? [Any] }
    public var dictionaryValue: [String: Any]? { value as? [String: Any] }
}
