import SwiftUI

struct UserInfo: Codable, Hashable {
    let startUsingDate: Date

    init(startUsingDate: Date) {
        self.startUsingDate = startUsingDate
    }
}
