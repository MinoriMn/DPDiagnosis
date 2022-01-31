import Combine
import SwiftUI

class CircadianRhythmViewModel: ObservableObject  {
    @Published var graphData: GraphData? = nil

    private var cancellables: [AnyCancellable] = []

    init() {
    }

    public func transform(input: Input) {
        cancellables.forEach({ $0.cancel() })
        cancellables.removeAll()

        input.selectedDate
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] date in
                self?.mockCircadianRhythm() //TODO
            })
            .store(in: &cancellables)

        mockCircadianRhythm() //TODO
    }
}

extension CircadianRhythmViewModel {
    struct GraphData {
        let heartRateData: [HeartRate]
        let estimatedCircadianRhythm: EstimatedCircadianRhythm?

        init(heartRateData: [HeartRate], estimatedCircadianRhythm: EstimatedCircadianRhythm) {
            self.heartRateData = heartRateData
            self.estimatedCircadianRhythm = estimatedCircadianRhythm
        }
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

        self.graphData = .init(
            heartRateData: heartRateData,
            estimatedCircadianRhythm: estimatedCircadianRhythm
        )
    }
}

extension CircadianRhythmViewModel {
    struct Input {
        let selectedDate: AnyPublisher<Date, Error>
    }
}
