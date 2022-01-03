import Combine
import SwiftUI

final class DementiaPossibilityDiagnosisRepository{
    private let healthKitProvider = HealthKitProvider()
    private let diagnosisAPI = DPDiagnosisAPI()

    private var resultList: DiagnosisResultList

    init() {
        resultList = .init(resultList: Dictionary<String, DiagnosisResult>()) // TODO: impl
    }

    public func requestAuthorization() -> AnyPublisher<Bool, Error> {
        healthKitProvider.requestAuthorization(quantityIdentifiers: [.heartRate], categoryIdentifiers: [.sleepAnalysis])
    }

    public func getDPDiagnosisResult(date: Date) -> AnyPublisher<DiagnosisResult, Error> {
        // (入力された日付 - 1) 00:00:00 ~ (入力された日付 + 1) 00:00:00 のデータで判定する
        let calendar = Calendar(identifier: .gregorian)

        if let result = resultList.getResult(date: date) {
            return Just(result).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        if let from = Calendar.current.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: date)),
           let to = Calendar.current.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) {
            let today = calendar.startOfDay(for: date)
            return getSleepAnalysis(from: from, to: to)
                .map {
                    $0.filter {
                        $0.sleepStatus == .asleep && $0.endDatetime > today
                    }
                }
                .flatMap { [weak self] sleepAnalysis -> AnyPublisher<[HeartRate], Error> in
                    guard let self = self else { fatalError() /*TODO*/ }
                    if sleepAnalysis.isEmpty {
                        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
                    } else {
                        // TODO: 複数の入眠判定や間がつながっていない時はどうするか
                        let publishers: [AnyPublisher<[HeartRate], Error>] = sleepAnalysis.map { [weak self] sa -> AnyPublisher<[HeartRate], Error> in
                            guard let self = self else { return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher() }

                            return self.getHeartRate(from: sa.startDatetime, to: sa.endDatetime)
                        }

                        return Publishers.MergeMany(publishers)
                            .collect()
                            .map { hrs -> [HeartRate] in
                                var hr: [HeartRate] = []
                                let sordtedHrs = hrs.sorted(by: { (hr0, hr1) -> Bool in
                                    if let date0 = hr0.first?.startDatetime,
                                       let date1 = hr1.first?.startDatetime {
                                        return date0 < date1
                                    } else {
                                        return true
                                    }
                                })

                                for _hr in sordtedHrs {
                                    hr += _hr
                                    print("\(_hr.first?.endDatetime.description(with: .current)): \(_hr.last?.endDatetime.description(with: .current)): \(_hr.count)") //DEBUG
                                }

                                return hr
                            }
                            .eraseToAnyPublisher()
                    }
                }
                .flatMap { [weak self] heartRate -> AnyPublisher<DiagnosisResult, Error> in
                    guard let self = self else { fatalError() /*TODO*/ }
                    guard heartRate.count > 30 else { // TODO: 最低限必要なデータ数を決める
                        let result = DiagnosisResult(date: today, diagnosis: .noResult)
                        self.resultList.addResult(result: result)
                        return Just(result).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }

                    return self.diagnosisAPI.dementiaPossibilityDiagnosis(heartRate: heartRate)
                        .map { [weak self] apiDiagnosisResult -> DiagnosisResult in
                            let result = DiagnosisResult(date: today, diagnosis: apiDiagnosisResult)
                            self?.resultList.addResult(result: result)
                            return result
                        }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        } else {
            return Fail(error: RepositoryError.calenderFormatError).eraseToAnyPublisher()
        }
    }

    public func getHeartRate(from: Date, to: Date) -> AnyPublisher<[HeartRate], Error> {
        healthKitProvider.getHeartRate(from: from, to: to)
    }

    public func getSleepAnalysis(from: Date, to: Date) -> AnyPublisher<[SleepAnalysis], Error> {
        healthKitProvider.getSleepAnalysis(from: from, to: to)
    }
}

extension DementiaPossibilityDiagnosisRepository {
    enum RepositoryError: Error {
        case calenderFormatError
    }
}
