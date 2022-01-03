import SwiftUI

struct HeartRate: Identifiable, Hashable {
    var id: String
    var startDatetime: Date
    var endDatetime: Date
    var value: Double
}
