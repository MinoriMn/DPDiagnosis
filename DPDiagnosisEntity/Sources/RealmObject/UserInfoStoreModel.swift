import Foundation
import RealmSwift

public final class UserInfoStoreModel: Object {
    @objc dynamic var key: String = ""
    @objc dynamic public var startUsingDate: Date = Date()
    @objc dynamic public var createdAt: Date = Date()

    public override static func primaryKey() -> String? {
        return "key"
    }
}

extension UserInfoStoreModel {
    public static func userInfoId() -> String {
        "user_information"
    }
}
