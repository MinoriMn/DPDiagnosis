import Combine
import SwiftUI

class DementiaPossibilityDiagnosisViewModel: ObservableObject {
    @Published var heartRate: [HeartRate] = []

    private var cancellables: [AnyCancellable] = []

    private let repository = DementiaPossibilityDiagnosisRepository()

    init() {

    }

    func transform(input: Input) -> Output {
        cancellables.forEach({ $0.cancel() })
        cancellables.removeAll()

        repository.requestAuthorization()
            .flatMap { [weak self] _ -> AnyPublisher<[HeartRate], Error> in
                guard let self = self, let from = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { fatalError() /*TODO*/}

                return self.repository.getHeartRate(from: from, to: Date())
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print("DPDiagnosisError: \(error)")
                }
            }, receiveValue: { [weak self] heartRate in
                self?.heartRate = heartRate
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
