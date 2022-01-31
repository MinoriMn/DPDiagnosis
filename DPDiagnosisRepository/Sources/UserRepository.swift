import Combine
import SwiftUI

final class UserRepository{
    public static let shared = UserRepository()

    private let realmManager = RealmManager.shared

    @Published var userInfo: UserInfo? = nil

    private init() {}

    public func setUserInfo(info: UserInfo) -> AnyPublisher<Void, Error> {
        let cache = UserInfoStoreModel(
            value: [
                "key": UserInfoStoreModel.userInfoId(),
                "startUsingDate": info.startUsingDate
            ]
        )

        return realmManager.update([cache])
            .map { [weak self] void -> Void in
                self?.userInfo = info
                return void
            }
            .eraseToAnyPublisher()
    }
    
    public func getUserInfo() -> AnyPublisher<UserInfo, Error> {
        realmManager.query(targetType: UserInfoStoreModel.self, primaryKey: UserInfoStoreModel.userInfoId())
            .flatMap { infoCache -> AnyPublisher<UserInfo, Error> in
                guard let infoCache = infoCache else { return Fail(error: RealmManager.ManagerError.notFoundRecord).eraseToAnyPublisher() }

                let result: UserInfo = .init(startUsingDate: infoCache.startUsingDate)

                return Just(result).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .map { [weak self] info -> UserInfo in
                self?.userInfo = info
                return info
            }
            .eraseToAnyPublisher()
    }
}

extension UserRepository {
    enum RepositoryError: Error {
        case calenderFormatError
        case invalidStoreFormat
    }
}
