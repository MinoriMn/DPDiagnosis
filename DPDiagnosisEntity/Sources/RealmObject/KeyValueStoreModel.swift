import Foundation
import RealmSwift

public final class KeyValueStoreModel: Object {
    @objc dynamic var key: String = ""
    @objc dynamic public var value: Data?
    @objc dynamic public var createdAt: Date = Date()

    public override static func primaryKey() -> String? {
        return "key"
    }
}
