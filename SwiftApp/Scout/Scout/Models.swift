//
//  Models.swift
//  Scout
//
//  Created by Layanne El Assaad on 8/3/25.
//


//  Models.swift
//  Scout

import Foundation

/// — FileInfo (from SSE results) —
public struct FileInfo: Decodable, Identifiable, Hashable {
    public var id: String { path }
    public let path: String
    public let score: Double?
    public let type: String?
    public let description: String?
    public let properties: [String: String]?      // ← carry full blob

    public init(
        path: String,
        score: Double?,
        type: String?,
        description: String?,
        properties: [String:String]? = nil
    ) {
        self.path = path
        self.score = score
        self.type = type
        self.description = description
        self.properties = properties
    }
}

/// — KGListResponse (/api/kg/entities-by-type/File) —
public struct KGListResponse: Decodable {
    public let success: Bool
    public let entity_type: String
    public let results: [KGFileEntity]
    public let count: Int
}

/// — KGFileEntity (one item in KGListResponse.results) —
public struct KGFileEntity: Decodable, Identifiable {
    public var id: String { entity }
    public let entity: String
    public let type: String
    public let description: String?
    public let properties: [String: JSONValue]?
}

public enum JSONValue: Decodable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported JSON type"))
        }
    }

    public var description: String {
        switch self {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return String(b)
        case .array(let a):
            return "[" + a.map { $0.description }.joined(separator: ", ") + "]"
        case .object(let o):
            return "{" + o.map { "\($0.key): \($0.value.description)" }.joined(separator: ", ") + "}"
        }
    }
}

extension JSONValue {
  /// If this holds a String, returns it; otherwise nil.
  var stringValue: String? {
    if case let .string(s) = self { return s }
    return nil
  }
}
