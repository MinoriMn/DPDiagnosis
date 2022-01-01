import SwiftUI

struct PreventionInfo: Codable, Hashable {
    let id: UUID
    let title: String
    let description: String

    init(id: UUID = UUID(), title: String, description: String) {
        self.id = id
        self.title = title
        self.description = description
    }
}

struct PreventionInfoList: Codable {
    let infoList: [PreventionInfo]

    init(infoList: [PreventionInfo]) {
        self.infoList = infoList
    }
}
