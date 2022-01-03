import SwiftUI

struct SleepAnalysis: Identifiable, Hashable {
    var id: String
    var startDatetime: Date
    var endDatetime: Date
    var sleepStatus: SleepStatus
}

enum SleepStatus: Int {
    case inBed
    case asleep
    case awake
    case undefined

    init(rawValue: Int) {
        switch(rawValue) {
        case 0:
            self = .inBed
        case 1:
            self = .asleep
        case 2:
            self = .awake
        default:
            self = .undefined
        }
    }

    public func description() -> String {
        switch(self) {
        case .inBed:
            return "inBed"
        case .asleep:
            return "asleep"
        case .awake:
            return "awake"
        case .undefined:
            return "undefined"
        }
    }
}
