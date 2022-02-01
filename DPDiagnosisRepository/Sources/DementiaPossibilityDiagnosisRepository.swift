import Combine
import SwiftUI

final class DementiaPossibilityDiagnosisRepository{
    private let healthKitProvider = HealthKitProvider()
    private let diagnosisAPI = DPDiagnosisModel()
    private let realmManager = RealmManager.shared
    private let csvFileProvider = CsvFileProvider()

    private var resultList: DiagnosisResultList

    init() {
        resultList = .init(resultList: Dictionary<String, DiagnosisResult>()) // TODO: impl
    }

    public func requestAuthorization() -> AnyPublisher<Bool, Error> {
        healthKitProvider.requestAuthorization(quantityIdentifiers: [.heartRate], categoryIdentifiers: [.sleepAnalysis])
    }

    public func getDPDiagnosisResult(date: Date) -> AnyPublisher<DiagnosisResult, Error> {
        // Realmのキャッシュを確認
        getDPDiagnosisResultCache(date: date)
            .catch { [weak self] error -> AnyPublisher<DiagnosisResult, Error> in
                guard let self = self else { fatalError() /*TODO*/ }
                print(DateUtils.stringFromDate(date: date, format: "yyyy/MM/dd"), error)
                // キャッシュがない場合は生成
                return self.generateDPDiagnosisResult(date: date)
                    .flatMap { [weak self] result -> AnyPublisher<DiagnosisResult, Error> in
                        guard let self = self else { fatalError() /*TODO*/ }

                        if let log = result.log, let estimatedHR = result.estimatedHR {
                            return Publishers.CombineLatest(
                                self.setDPDiagnosisResultRealmCache(diagnosisResult: result),
                                self.saveLogAndEstimatedHeartRate(date: result.date, log: log, estimatedHR: estimatedHR)
                            )
                                .map { _ in result }
                                .eraseToAnyPublisher()
                        } else {
                            return self.setDPDiagnosisResultRealmCache(diagnosisResult: result)
                                .map { _ in result }
                                .eraseToAnyPublisher()
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func generateDPDiagnosisResult(date: Date) -> AnyPublisher<DiagnosisResult, Error> {
        if let result = resultList.getResult(date: date) {
            return Just(result).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: date)

        return getTheDayAsleepAnalysis(date: date)
            .flatMap { [weak self] sleepAnalysis -> AnyPublisher<[HeartRate], Error> in
                guard let self = self else { fatalError() /*TODO*/ }
                guard !sleepAnalysis.isEmpty else { return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher() }

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
                        }

                        return hr
                    }
                    .eraseToAnyPublisher()
            }
            .flatMap { [weak self] heartRate -> AnyPublisher<DiagnosisResult, Error> in
                guard let self = self else { fatalError() /*TODO*/ }
                guard heartRate.count > 15 else { // TODO: 最低限必要なデータ数を決める
                    let result = DiagnosisResult(date: today, diagnosis: .noResult, log: nil, estimatedHR: nil)
                    self.resultList.addResult(result: result)
                    return Just(result).setFailureType(to: Error.self).eraseToAnyPublisher()
                }

                return self.diagnosisAPI.dementiaPossibilityDiagnosis(heartRate: heartRate, progressPublisher: nil)
                    .map { [weak self] (apiDiagnosisResult, log, estimatedHR) -> DiagnosisResult in
                        let result = DiagnosisResult(date: today, diagnosis: apiDiagnosisResult, log: log, estimatedHR: estimatedHR)
                        self?.resultList.addResult(result: result)
                        return result
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func saveLogAndEstimatedHeartRate(date: Date, log: [DPDiagnosisModel.Log], estimatedHR: [DPDiagnosisModel.EstimatedHeartRate]) -> AnyPublisher<Void, Error> {
        let dateString = DateUtils.stringFromDate(date: date, format: "yyyyMMdd")

        print("called save:", dateString)

        var logLabel = ["dateTime", "heartRate"]
        logLabel.append(contentsOf: diagnosisAPI.getMembersLabel())
        let logData: [[String]] = log.map { l -> [String] in
            var d: [String] = [DateUtils.stringFromDate(date: l.date, format: "yyyy/MM/dd HH:mm:ss"), String(l.heartRate)]
            d.append(contentsOf: l.coefficients.map { String($0) })
            return d
        }

        let estimatedHeartRateLabel = ["dateTime", "estimatedHeartRate"]
        let estimatedHeartRateData: [[String]] = estimatedHR.map { ehr -> [String] in
            return [DateUtils.stringFromDate(date: ehr.date, format: "yyyy/MM/dd HH:mm:ss"), String(ehr.estimatedHeartRate)]
        }

        return Publishers.CombineLatest(
            csvFileProvider.saveCsv(labels: logLabel, data: logData, fileName: dateString + "_log.csv"),
            csvFileProvider.saveCsv(labels: estimatedHeartRateLabel, data: estimatedHeartRateData, fileName: dateString + "_estimatedHR.csv")
        )
            .map { _ in Void() }
            .eraseToAnyPublisher()
    }

    private func loadLogAndEstimatedHeartRate(date: Date) -> AnyPublisher<([DPDiagnosisModel.Log]?, [DPDiagnosisModel.EstimatedHeartRate]?), Error> {
        let dateString = DateUtils.stringFromDate(date: date, format: "yyyyMMdd")

        let logMembers = diagnosisAPI.getMembersLabel()
        let logPublisher = csvFileProvider.loadCsv(fileName: dateString + "_log.csv")
            .map { csv -> [DPDiagnosisModel.Log]? in
                var log: [DPDiagnosisModel.Log] = []
                for row in csv.namedRows {
                    guard let d = DateUtils.dateFromString(string: row["dateTime"] ?? "", format: "yyyy/MM/dd HH:mm:ss"),
                          let heartRate = Double(row["heartRate"] ?? "-1") else { continue }
                    let coefficients = logMembers.map { m -> Double in Double(row[m] ?? "-1") ?? -1 }


                    log.append(.init(date: d, heartRate: heartRate, coefficients: coefficients))
                }

                return log
            }

        let estimatedHRPublisher = csvFileProvider.loadCsv(fileName: dateString + "_estimatedHR.csv")
            .map { csv -> [DPDiagnosisModel.EstimatedHeartRate]? in
                var estimatedHR: [DPDiagnosisModel.EstimatedHeartRate] = []
                for row in csv.namedRows {
                    guard let d = DateUtils.dateFromString(string: row["dateTime"] ?? "", format: "yyyy/MM/dd HH:mm:ss"),
                          let ehr = Double(row["estimatedHeartRate"] ?? "-1") else { continue }

                    estimatedHR.append(.init(date: d, estimatedHeartRate: ehr))
                }

                return estimatedHR
            }

        return Publishers.CombineLatest(logPublisher, estimatedHRPublisher)
            .eraseToAnyPublisher()
    }

    private func getDPDiagnosisResultCache(date: Date) -> AnyPublisher<DiagnosisResult, Error> {
        getDPDiagnosisResultRealmCache(date: date)
            .flatMap { [weak self] (date, diagnosis) -> AnyPublisher<DiagnosisResult, Error> in
                guard let self = self, diagnosis != .noResult else { return Just(.init(date: date, diagnosis: diagnosis, log: nil, estimatedHR: nil)).setFailureType(to: Error.self).eraseToAnyPublisher() }

                return self.loadLogAndEstimatedHeartRate(date: date)
                    .map { (log, estimatedHR) -> DiagnosisResult in
                        .init(date: date, diagnosis: diagnosis, log: log, estimatedHR: estimatedHR)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }


    private func setDPDiagnosisResultRealmCache(diagnosisResult: DiagnosisResult) -> AnyPublisher<Void, Error> {
        let cache = DiagnosisResultStoreModel(
            value: [
                "key": DiagnosisResultStoreModel.diagnosisCacheGenerateId(date: diagnosisResult.date),
                "diagnosis": diagnosisResult.diagnosis.rawValue,
                "date": diagnosisResult.date,
                "version": DPDiagnosisModel.version
            ]
        )

        return realmManager.update([cache])
    }

    private func getDPDiagnosisResultRealmCache(date: Date) -> AnyPublisher<(Date, DPDiagnosisModel.DiagnosisResult), Error> {
        realmManager.query(targetType: DiagnosisResultStoreModel.self, primaryKey: DiagnosisResultStoreModel.diagnosisCacheGenerateId(date: date))
            .flatMap { diagnosisCache -> AnyPublisher<(Date, DPDiagnosisModel.DiagnosisResult), Error> in
                guard let diagnosisCache = diagnosisCache else { return Fail(error: RealmManager.ManagerError.notFoundRecord).eraseToAnyPublisher() }
                guard diagnosisCache.version == DPDiagnosisModel.version else { return Fail(error: RepositoryError.shouldUpdateResultBecauseModelVersion).eraseToAnyPublisher() }
                guard let diagnosisDate = diagnosisCache.date, let diagnosis = DPDiagnosisModel.DiagnosisResult(rawValue: diagnosisCache.diagnosis) else { return Fail(error: RepositoryError.invalidStoreFormat).eraseToAnyPublisher() }

                return Just((diagnosisDate, diagnosis)).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    public func getHeartRate(from: Date, to: Date) -> AnyPublisher<[HeartRate], Error> {
        healthKitProvider.getHeartRate(from: from, to: to)
    }

    public func getSleepAnalysis(from: Date, to: Date) -> AnyPublisher<[SleepAnalysis], Error> {
        healthKitProvider.getSleepAnalysis(from: from, to: to)
    }

    public func getTheDayAsleepAnalysis(date: Date) -> AnyPublisher<[SleepAnalysis], Error> {
        // (入力された日付 - 1) 12:00:00 ~ (入力された日付 + 1) 12:00:00 のデータで判定する
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: date)

        if let from = Calendar.current.date(byAdding: .hour, value: -12, to: calendar.startOfDay(for: date)),
           let to = Calendar.current.date(byAdding: .hour, value: 12, to: calendar.startOfDay(for: date)) {
            return getSleepAnalysis(from: from, to: to)
                .map { sleepAnalysis -> [SleepAnalysis] in
                    let longestInBed = sleepAnalysis
                        .filter { $0.sleepStatus == .inBed && $0.endDatetime >= today }
                        .sorted(by: { $0.endDatetime.timeIntervalSince($0.startDatetime) > $1.endDatetime.timeIntervalSince($1.startDatetime) })
                        .first

                    if let inBed = longestInBed {
                        return sleepAnalysis.filter {
                            $0.sleepStatus == .asleep && inBed.startDatetime <= $0.startDatetime && inBed.endDatetime >= $0.endDatetime
                        }
                    } else {
                        return []
                    }
                }
                .eraseToAnyPublisher()
        } else {
            return Fail(error: RepositoryError.calenderFormatError).eraseToAnyPublisher()
        }
    }
}

extension DementiaPossibilityDiagnosisRepository {
    enum RepositoryError: Error {
        case calenderFormatError
        case invalidStoreFormat
        case shouldUpdateResultBecauseModelVersion
    }
}
