import Combine
import HealthKit

final class HealthKitProvider {
    private let healthStore = HKHealthStore()

    init() {}

    public func requestAuthorization(identifiers: [HKQuantityTypeIdentifier]) -> AnyPublisher<Bool, Error> {
        guard HKHealthStore.isHealthDataAvailable() else {
            return Fail(error: ProviderError.unavailableOnDevice).eraseToAnyPublisher()
        }

        let quantityTypes = identifiers.map { identifier in
            HKQuantityType.quantityType(forIdentifier: identifier)
        }
        .compactMap { $0 }

        guard !quantityTypes.isEmpty else {
            return Fail(error: ProviderError.couldNotReadyType).eraseToAnyPublisher()
        }

        let readTypes = Set(quantityTypes)

        let publisher = PassthroughSubject<Bool, Error>()

        self.healthStore.requestAuthorization(toShare: [], read: readTypes) { authSuccess, error in
            guard error == nil else {
                publisher.send(completion: .failure(error ?? ProviderError.notAllowedAccessData))
                return
            }

            if authSuccess {
                publisher.send(true)
            } else {
                publisher.send(completion: .failure(error ?? ProviderError.notAllowedAccessData))
            }
        }

        return publisher.eraseToAnyPublisher()
    }

    public func getHeartRate(from: Date, to: Date) -> AnyPublisher<[HeartRate], Error> {
        getData(identifier: .heartRate, from: from, to: to)
            .map { items -> [HeartRate] in
                items.map { item -> HeartRate in
                    .init(
                        id: item.uuid.uuidString,
                        startDatetime: item.startDate,
                        endDatetime: item.endDate,
                        value: item.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    )
                }
            }
            .eraseToAnyPublisher()
    }

    private func getData(identifier: HKQuantityTypeIdentifier, from: Date, to: Date) -> AnyPublisher<[HKQuantitySample], Error> {
        Future<[HKQuantitySample], Error> { promise in
            guard let sampleType = HKSampleType.quantityType(forIdentifier: identifier) else {
                promise(.failure(ProviderError.couldNotReadyType))
                return
            }

            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: HKQuery.predicateForSamples(withStart: from, end: to, options: []),
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]
            ){ (query, results, error) in
                guard error == nil else {
                    promise(.failure(error ?? ProviderError.notAllowedAccessData))
                    return
                }

                let sampleResults: [HKQuantitySample] = results as? [HKQuantitySample] ?? []
                promise(.success(sampleResults))
                return
            }
            self.healthStore.execute(query)
        }
        .eraseToAnyPublisher()
    }
}

extension HealthKitProvider {
    enum ProviderError: Error {
        case unavailableOnDevice
        case couldNotReadyType
        case notAllowedAccessData
        case couldNotFoundSelf
    }
}
