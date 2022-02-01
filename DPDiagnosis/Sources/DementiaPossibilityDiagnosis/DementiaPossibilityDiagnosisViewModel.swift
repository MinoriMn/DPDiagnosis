import Combine
import SwiftUI

class DementiaPossibilityDiagnosisViewModel: ObservableObject {
    @Published var diagnosisResults: [DiagnosisResult] = []
    @Published var selectedDate: AnyPublisher<Date, Never> = Empty<Date, Never>().eraseToAnyPublisher()
    @Published var currentDate: Date = Date()

    private var cancellables: [AnyCancellable] = []

    private let repository = DementiaPossibilityDiagnosisRepository()
    private let userRepository = UserRepository.shared

    private var userInfo = CurrentValueSubject<UserInfo?, Never>(nil)

    init() {

    }

    func transform(input: Input) {
        cancellables.forEach({ $0.cancel() })
        cancellables.removeAll()

        userRepository.$userInfo
            .flatMap { info -> AnyPublisher<UserInfo, Error> in
                guard let info = info else { return Empty<UserInfo, Error>().eraseToAnyPublisher() }

                return Just(info).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] info in
                    self?.userInfo.send(info)
                }
            )
            .store(in: &cancellables)

        userInfo
            .flatMap { [weak self] info -> AnyPublisher<[DiagnosisResult], Error> in
                guard let self = self else { fatalError() /*TODO*/}
                guard let info = info else { return Empty<[DiagnosisResult], Error>().eraseToAnyPublisher() }

                return self.repository.requestAuthorization()
                    .flatMap { [weak self] _ -> AnyPublisher<[DiagnosisResult], Error> in
                        guard let self = self else { fatalError() /*TODO*/}

                        let today = Date()
                        let passedDayFromStartUsingDay: Int = Int(today.timeIntervalSince(info.startUsingDate) / 86400)
                        var publishers: [AnyPublisher<DiagnosisResult, Error>] = []

                        for i in stride(from: passedDayFromStartUsingDay + Const.getResultDaysFromStartUsingDay, to: 0, by: -1) {
                            if let date = Calendar.current.date(byAdding: .day, value: -i, to: today) {
                                publishers.append(
                                    self.repository.getDPDiagnosisResult(date: date)
                                )
                            }
                        }

                        return Publishers.MergeMany(publishers)
                            .collect()
                            .receive(on: DispatchQueue.main)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print("DPDiagnosisError: \(error)")
                }
            }, receiveValue: { [weak self] diagnosisResults in
                self?.diagnosisResults = diagnosisResults.filter { $0.diagnosis != .noResult }.sorted(by: { $0.date.timeIntervalSince1970 > $1.date.timeIntervalSince1970 })
                if let date = self?.diagnosisResults.first?.date {
                    input.selectedDate.send(date)
                }
            })
            .store(in: &cancellables)

        self.selectedDate = input.selectedDate.eraseToAnyPublisher() // TODO:

        self.selectedDate
            .sink { [weak self] date in
                self?.currentDate = date // TODO
            }
            .store(in: &cancellables)
    }
}

extension DementiaPossibilityDiagnosisViewModel {
    private enum Const {
        // 初回利用から何日前までのデータを取得するか
        static let getResultDaysFromStartUsingDay = 60
    }
}


extension DementiaPossibilityDiagnosisViewModel {
    struct Input {
        let selectedDate: PassthroughSubject<Date, Never>
    }
}
