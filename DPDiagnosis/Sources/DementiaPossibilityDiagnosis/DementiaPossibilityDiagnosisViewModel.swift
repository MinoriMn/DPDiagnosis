import Combine
import SwiftUI

class DementiaPossibilityDiagnosisViewModel: ObservableObject {
    @Published var heartRate: [HeartRate] = []
    @Published var sleepAnalysis: [SleepAnalysis] = []

    private var cancellables: [AnyCancellable] = []

    private let repository = DementiaPossibilityDiagnosisRepository()

    init() {

    }

    func transform(input: Input) -> Output {
        cancellables.forEach({ $0.cancel() })
        cancellables.removeAll()

        repository.requestAuthorization()
            .flatMap { [weak self] _ -> AnyPublisher<([HeartRate], [SleepAnalysis]), Error> in
                guard let self = self, let from = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { fatalError() /*TODO*/}

                let heartRatePublisher = self.repository.getHeartRate(from: from, to: Date())
                let sleepAnalysisPublisher = self.repository.getSleepAnalysis(from: from, to: Date())

                return Publishers.CombineLatest(heartRatePublisher, sleepAnalysisPublisher)
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print("DPDiagnosisError: \(error)")
                }
            }, receiveValue: { [weak self] (heartRate, sleepAnalysis) in
                self?.heartRate = heartRate
                self?.sleepAnalysis = sleepAnalysis
            })
            .store(in: &cancellables)

        return .init()
    }
}


extension DementiaPossibilityDiagnosisViewModel {
    struct Input {

    }

    struct Output {

    }
}
