import SwiftUI

class DementiaPreventionViewModel: ObservableObject {
    @Published var sleepInfos: [PreventionInfo] = mockSleepInfos
    @Published var activeInfos: [PreventionInfo] = mockActiveInfos
    @Published var ackInfos: [PreventionInfo] = mockAckInfos
    @Published var socialInfos: [PreventionInfo] = mockSocialInfos

    init(sleepInfos: [PreventionInfo] = mockSleepInfos, activeInfos: [PreventionInfo] = mockActiveInfos, ackInfos: [PreventionInfo] = mockAckInfos, socialInfos: [PreventionInfo] = mockSocialInfos) {
        self.sleepInfos = sleepInfos
        self.activeInfos = activeInfos
        self.ackInfos = ackInfos
        self.socialInfos = socialInfos
    }
}

//Mock
private let mockSleepInfos: [PreventionInfo] = [
    .init(title: "Aの知識", description: "毎日同じ時間に寝よう"),
    .init(title: "Bの知識", description: "朝日を浴びよう"),
    .init(title: "Cの知識", description: "自分のベストな睡眠時間を見つけてみよう"),
    .init(title: "Dの知識", description: "睡眠直後の環境を見直そう")
]
private let mockActiveInfos: [PreventionInfo] = [
    .init(title: "Aの知識", description: "週2回以上30分の軽いウォーキングをしよう"),
    .init(title: "Cの知識", description: "頭を使う運動をしよう")
]
private let mockAckInfos: [PreventionInfo] = [
    .init(title: "Aの知識", description: "週2回以上魚を食べよう"),
    .init(title: "Bの知識", description: "ビタミンを食生活に取り入れよう"),
    .init(title: "Cの知識", description: "偏食がないかを見直そう")
]
private let mockSocialInfos: [PreventionInfo] = [
    .init(title: "Aの知識", description: "説明文だよ1"),
    .init(title: "Bの知識", description: "説明文だよ2"),
    .init(title: "Cの知識", description: "説明文だよ3")
]
