import Combine
import SwiftUI

class DementiaPossibilityDiagnosisViewModel: ObservableObject {
    @Published var diagnosisResults: [DiagnosisResult] = []

    private var cancellables: [AnyCancellable] = []

    private let repository = DementiaPossibilityDiagnosisRepository()

    init() {

    }

    func transform(input: Input) -> Output {
        cancellables.forEach({ $0.cancel() })
        cancellables.removeAll()

        repository.requestAuthorization()
            .flatMap { [weak self] _ -> AnyPublisher<DiagnosisResult, Error> in
                guard let self = self else { fatalError() /*TODO*/}

                let today = Date()
                var publishers: [AnyPublisher<DiagnosisResult, Error>] = []
                for i in 0..<20 {
                    if let date = Calendar.current.date(byAdding: .day, value: -i, to: today) { //
                        publishers.append(self.repository.getDPDiagnosisResult(date: date))
                    }
                }

                return Publishers.MergeMany(publishers)
                    .receive(on: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print("DPDiagnosisError: \(error)")
                }
            }, receiveValue: { [weak self] diagnosisResult in
                self?.diagnosisResults.append(diagnosisResult)
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
