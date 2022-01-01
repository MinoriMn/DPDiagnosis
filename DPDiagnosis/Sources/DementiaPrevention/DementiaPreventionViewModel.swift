import SwiftUI

class DementiaPreventionViewModel: ObservableObject {
    @Published var preventionInfos: [PreventionInfo] = mockPreventionInfo

    init(preventionInfos: [PreventionInfo] = mockPreventionInfo) {
        self.preventionInfos = preventionInfos
    }
}

//Mock
private let mockPreventionInfo: [PreventionInfo] = [
    .init(title: "Aの知識", description: "説明文だよ1"),
    .init(title: "Bの知識", description: "説明文だよ2"),
    .init(title: "Cの知識", description: "説明文だよ3")
]
