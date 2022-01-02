import Combine
import SwiftUI

final class DementiaPossibilityDiagnosisRepository{
    private let healthKitProvider = HealthKitProvider()

    public func requestAuthorization() -> AnyPublisher<Bool, Error> {
        healthKitProvider.requestAuthorization(identifiers: [.heartRate])
    }

    public func getHeartRate(from: Date, to: Date) -> AnyPublisher<[HeartRate], Error> {
        healthKitProvider.getHeartRate(from: from, to: to)
    }
}
