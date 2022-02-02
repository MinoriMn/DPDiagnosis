import Combine
import SwiftUI

class CircadianRhythmViewModel: ObservableObject  {
    @Published var graphData: [GraphData] = []

    private var cancellables: [AnyCancellable] = []

    private let repository = DementiaPossibilityDiagnosisRepository()

    init() {
        mockCircadianRhythm()
    }

    public func transform(input: Input) {
        cancellables.forEach({ $0.cancel() })
        cancellables.removeAll()

        input.selectedDate
            .flatMap { [weak self] date -> AnyPublisher<DiagnosisResult, Error> in
                guard let self = self else { fatalError() /*TODO*/ }
                return self.repository.getDPDiagnosisResult(date: date)
            }
            .map { result -> [GraphData] in
                let heartRate: [HeartRate] = (result.log ?? []).map { log -> HeartRate in
                    .init(id: DateUtils.stringFromDate(date: log.date, format: "yyyyMMddHHmmss") + "_hr", startDatetime: log.date, endDatetime: log.date, value: log.heartRate)
                }
                let plots: [CircadianRhythmPlot] = (result.estimatedHR ?? []).map { estimatedHR -> CircadianRhythmPlot in
                        .init(time: estimatedHR.date, coefficients: [], estimatedHeartRate: estimatedHR.estimatedHeartRate) // TODO: coefficients
                }
                let estimatedCircadianRhythm: EstimatedCircadianRhythm = .init(id: DateUtils.stringFromDate(date: heartRate.first!.startDatetime, format: "yyyyMMddHHmmss") + "_hr", startDatetime: heartRate.first!.startDatetime, endDatetime: heartRate.last!.startDatetime, periods: [], plots: plots) // TODO: periods

                return [.init(
                    heartRateData: heartRate,
                    estimatedCircadianRhythm: estimatedCircadianRhythm
                )]
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$graphData)
    }
}

struct GraphData: Identifiable, Hashable {
    let id = UUID()
    let heartRateData: [HeartRate]
    let estimatedCircadianRhythm: EstimatedCircadianRhythm?

    init(heartRateData: [HeartRate], estimatedCircadianRhythm: EstimatedCircadianRhythm) {
        self.heartRateData = heartRateData
        self.estimatedCircadianRhythm = estimatedCircadianRhythm
    }
}

extension CircadianRhythmViewModel {
    private func mockCircadianRhythm() {
        let heartRateData: [HeartRate] = [
            .init(id: "a", startDatetime: DateUtils.dateFromString(string: "2020/01/01 20:00:00", format: "yyyy/MM/dd HH:mm:ss") ?? Date(), endDatetime: DateUtils.dateFromString(string: "2020/01/01 20:00:00", format: "yyyy/MM/dd HH:mm:ss") ?? Date(), value: 60),
            .init(id: "b", startDatetime: DateUtils.dateFromString(string: "2020/01/01 22:00:00", format: "yyyy/MM/dd HH:mm:ss") ?? Date(), endDatetime: DateUtils.dateFromString(string: "2020/01/01 22:00:00", format: "yyyy/MM/dd HH:mm:ss") ?? Date(), value: 66),
            .init(id: "c", startDatetime: DateUtils.dateFromString(string: "2020/01/01 23:00:00", format: "yyyy/MM/dd HH:mm:ss") ?? Date(), endDatetime: DateUtils.dateFromString(string: "2020/01/01 23:00:00", format: "yyyy/MM/dd HH:mm:ss") ?? Date(), value: 70)
        ]
        let estimatedCircadianRhythm: EstimatedCircadianRhythm = .init(
            id: "d",
            startDatetime: DateUtils.dateFromString(string: "2020/01/01 20:00:00", format: "yyyy/MM/dd HH:mm:ss") ?? Date(),
            endDatetime: DateUtils.dateFromString(string: "2020/01/01 23:00:00", format: "yyyy/MM/dd HH:mm:ss") ?? Date(),
            periods: [],
            plots: [
                .init(
                    time: DateUtils.dateFromString(string: "2020/01/01 20:00:00", format: "yyyy/MM/dd HH:mm:ss") ?? Date(),
                    coefficients: [],
                    estimatedHeartRate: 50
                ),
                .init(
                    time: DateUtils.dateFromString(string: "2020/01/01 20:05:00", format: "yyyy/MM/dd HH:mm:ss") ?? Date(),
                    coefficients: [],
                    estimatedHeartRate: 60
                ),
                .init(
                    time: DateUtils.dateFromString(string: "2020/01/01 20:15:00", format: "yyyy/MM/dd HH:mm:ss") ?? Date(),
                    coefficients: [],
                    estimatedHeartRate: 70
                )
            ])

        self.graphData = [
            .init(
                heartRateData: heartRateData,
                estimatedCircadianRhythm: estimatedCircadianRhythm
            )
        ]
    }
}

extension CircadianRhythmViewModel {
    struct Input {
        let selectedDate: AnyPublisher<Date, Never>
    }
}
