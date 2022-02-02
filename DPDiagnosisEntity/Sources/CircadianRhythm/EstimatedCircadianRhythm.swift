import SwiftUI

struct EstimatedCircadianRhythm: Identifiable, Hashable {
    var id: String
    var startDatetime: Date
    var endDatetime: Date
    var periods: [Double]
    var plots: [CircadianRhythmPlot]
}
