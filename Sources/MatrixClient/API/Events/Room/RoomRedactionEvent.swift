import Foundation
import AnyCodable

public struct RoomRedactionEvent: RoomEvent {
    public static var type = "m.room.redaction"
    
    public let content: Content
    public let type: String
    public let eventID: String
    public let sender: String
    public let date: Date
    public let unsigned: AnyCodable?
    
    public let redacts: String?
    
    enum CodingKeys: String, CodingKey {
        case content
        case type
        case eventID = "event_id"
        case sender
        case date = "origin_server_ts"
        case unsigned
        case redacts
    }
    
    public struct Content: Decodable {
        public let reason: String?
    }
}
