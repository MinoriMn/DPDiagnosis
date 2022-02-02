import SwiftUI

struct CircadianRhythmPlot: Codable, Hashable {
    var time: Date
    var coefficients: [Double]
    var estimatedHeartRate: Double

    init(time: Date, coefficients: [Double], estimatedHeartRate: Double) {
        self.time = time
        self.coefficients = coefficients
        self.estimatedHeartRate = estimatedHeartRate
    }
}
