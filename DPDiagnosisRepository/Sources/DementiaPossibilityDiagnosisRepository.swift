import Combine
import SwiftUI

final class DementiaPossibilityDiagnosisRepository{
    private let healthKitProvider = HealthKitProvider()

    public func requestAuthorization() -> AnyPublisher<Bool, Error> {
        healthKitProvider.requestAuthorization(quantityIdentifiers: [.heartRate], categoryIdentifiers: [.sleepAnalysis])
    }

    public func getHeartRate(from: Date, to: Date) -> AnyPublisher<[HeartRate], Error> {
        healthKitProvider.getHeartRate(from: from, to: to)
    }

    public func getSleepAnalysis(from: Date, to: Date) -> AnyPublisher<[SleepAnalysis], Error> {
        healthKitProvider.getSleepAnalysis(from: from, to: to)
    }
}
