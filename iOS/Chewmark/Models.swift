import Foundation

struct DentalEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var type: String
    var notes: String
    var createdAt: Date = Date()
}
