import Combine
import HealthKit

final class HealthKitProvider {
    private let healthStore = HKHealthStore()

    init() {}

    public func requestAuthorization(quantityIdentifiers: [HKQuantityTypeIdentifier], categoryIdentifiers: [HKCategoryTypeIdentifier]) -> AnyPublisher<Bool, Error> {
        guard HKHealthStore.isHealthDataAvailable() else {
            return Fail(error: ProviderError.unavailableOnDevice).eraseToAnyPublisher()
        }

        let quantityTypes = quantityIdentifiers.map { identifier in
            HKQuantityType.quantityType(forIdentifier: identifier)
        }
        .compactMap { $0 }

        let categoryTypes = categoryIdentifiers.map { identifier in
            HKObjectType.categoryType(forIdentifier: identifier)
        }
        .compactMap { $0 }

        guard !quantityTypes.isEmpty else {
            return Fail(error: ProviderError.couldNotReadyType).eraseToAnyPublisher()
        }

        let readTypes = Set(quantityTypes + categoryTypes)

        let publisher = PassthroughSubject<Bool, Error>()

        healthStore.requestAuthorization(toShare: [], read: readTypes) { authSuccess, error in
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
        getData(quantityIdentifier: .heartRate, from: from, to: to)
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

    public func getSleepAnalysis(from: Date, to: Date) -> AnyPublisher<[SleepAnalysis], Error> {
        getData(categoryIdentifier: .sleepAnalysis, from: from, to: to)
            .map { items -> [SleepAnalysis] in
                items.map { item -> SleepAnalysis in
                        .init(
                            id: item.uuid.uuidString,
                            startDatetime: item.startDate,
                            endDatetime: item.endDate,
                            sleepStatus: SleepStatus(rawValue: item.value)
                        )
                }
            }
            .eraseToAnyPublisher()
    }

    private func getData(quantityIdentifier: HKQuantityTypeIdentifier, from: Date, to: Date) -> AnyPublisher<[HKQuantitySample], Error> {
        guard let sampleType = HKSampleType.quantityType(forIdentifier: quantityIdentifier) else {
            return Fail(error: ProviderError.couldNotReadyType).eraseToAnyPublisher()
        }

        return getData(identifier: sampleType, from: from, to: to)
            .map { results -> [HKQuantitySample] in
                results as? [HKQuantitySample] ?? []
            }
            .eraseToAnyPublisher()
    }

    public func getData(categoryIdentifier: HKCategoryTypeIdentifier, from: Date, to: Date) -> AnyPublisher<[HKCategorySample], Error> {
        guard let sampleType = HKSampleType.categoryType(forIdentifier: categoryIdentifier) else {
            return Fail(error: ProviderError.couldNotReadyType).eraseToAnyPublisher()
        }

        return getData(identifier: sampleType, from: from, to: to)
            .map { results -> [HKCategorySample] in
                results as? [HKCategorySample] ?? []
            }
            .eraseToAnyPublisher()
    }

    private func getData(identifier: HKSampleType, from: Date, to: Date) -> AnyPublisher<[HKSample]?, Error> {
        Future<[HKSample]?, Error> { promise in
            let query = HKSampleQuery(
                sampleType: identifier,
                predicate: HKQuery.predicateForSamples(withStart: from, end: to, options: []),
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]
            ){ (query, results, error) in
                guard error == nil else {
                    promise(.failure(error ?? ProviderError.notAllowedAccessData))
                    return
                }


                promise(.success(results))
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
