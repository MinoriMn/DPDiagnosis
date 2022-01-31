import Foundation
import RealmSwift

public final class DiagnosisResultStoreModel: Object {
    @objc dynamic var key: String = ""
    @objc dynamic public var diagnosis: String = ""
    @objc dynamic public var date: Date?
    @objc dynamic public var version: String = ""
    @objc dynamic public var createdAt: Date = Date()

    public override static func primaryKey() -> String? {
        return "key"
    }
}

extension DiagnosisResultStoreModel {
    public static func diagnosisCacheGenerateId(date rawDate: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.startOfDay(for: rawDate)

        return "diagnosis_result_\(date.description)" // FIXME:
    }
}
