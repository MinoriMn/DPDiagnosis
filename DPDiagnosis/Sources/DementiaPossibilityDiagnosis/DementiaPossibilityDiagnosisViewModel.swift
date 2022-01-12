import Combine
import SwiftUI

class DementiaPossibilityDiagnosisViewModel: ObservableObject {
    @Published var diagnosisResult: DiagnosisResult = .init(date: Date(), diagnosis: .noResult)

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

                return self.repository.getDPDiagnosisResult(date: Date())
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
                self?.diagnosisResult = diagnosisResult
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
