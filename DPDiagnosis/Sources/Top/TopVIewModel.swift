import Combine
import SwiftUI

class TopViewModel: ObservableObject {
    private var cancellables: [AnyCancellable] = []

    private let userRepository = UserRepository.shared
    
    init() {
        loadUserInfo()
    }

    private func loadUserInfo() {
        userRepository.getUserInfo()
            .map { _ -> Void in return Void() }
            .catch { [weak self] error -> AnyPublisher<Void, Error> in
                guard let self = self else { fatalError() /*TODO*/ }

                print(error)
                return self.userRepository.setUserInfo(info: .init(startUsingDate: Date()))
            }
            .eraseToAnyPublisher()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}
