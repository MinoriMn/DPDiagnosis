//
//  PreventionDetailView.swift
//  DPDiagnosis
//
//  Created by 松田尚也 on 2022/01/01.
//

import SwiftUI

struct PreventionDetailView: View {
    // TODO:
    @State var selectedDate: Date = Date()
    @State var existDataDate: [Date] = []

    var body: some View {
        VStack (alignment: .leading, spacing: 10){
            ZStack {
                Image("bio_sleep")
                    .resizable()
                    .scaledToFill()
                    .frame(width: .infinity, height: 100, alignment: .center)
                    .clipped()
                Text("毎日同じ時間に寝よう")
                    .font(.title)
                    .foregroundColor(.white)

            }
            .cornerRadius(15)
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            Text("　認知症の原因の一つに脳内の老廃物蓄積があります。これを脳外に排出するにはまず睡眠習慣を安定させることが大事です。")
                .lineLimit(nil)
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(Color.gray)
                .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
            CalendarView(selectedDate: $selectedDate, existDataDate: $existDataDate)

            List {
                Section(header: Text("詳しく知りたい")
                            .font(.title2)) {
                    Text("認知症の増加傾向は 年 多くの国で抱える問題である 日本も例外ではなく 2012 年では462 万人 2025 年の推 は675 万人 730 万人に増加すると われている そのうち アルツハイマー型 知症(AD) の患 は 知症 齢 全体の半分程度を占め 特に患 数が多い 知症である しかし AD は完全な予防法や根本的な治療法は不十分であり また 初期症状が現れるまでに約十数年かかることから AD が発 する には処置が困 な場合が多い そのため AD の早期発・早期対応が  な 題となっている AD を含む 広く利用されている 知症判定法にはMini-Mental State Examination(MMSE) [1] などの口頭 問や筆 によるスクリーニング検査があるが 検査対象 に心理的 担がかかり")
                        .lineLimit(nil)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

            }
        }
    }
}

struct PreventionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PreventionDetailView()
    }
}
