import Combine
import SwiftUI

struct DementiaPossibilityDiagnosisView: View {
    @ObservedObject var viewModel = DementiaPossibilityDiagnosisViewModel()

    private let selectedDate = PassthroughSubject<Date, Error>()

    private var cancellables: [AnyCancellable] = []

    init() {
        bind()
    }

    private func bind() {
        viewModel.transform(input: .init(
            selectedDate: selectedDate.eraseToAnyPublisher()
        ))
    }

    var body: some View {
        List {
            Section () {
                VStack(alignment: .center) {
                    HStack {
                        Text("あなたの\n認知症可能性")
                            .font(.title2)
                        Spacer()
                        Image("dementia_rate_high")
                            .resizable()
                            .frame(width: 140, height: 140, alignment: .trailing)
                    }
                    HStack {
                        Text("簡易的な認知症判定をベースにしています\n認知症の有無を確定するものではございません")
                            .font(.footnote)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }

                }
            }
            Section (header: Text("1月1日の記録").font(.title2)) {
                VStack(alignment: .center) {
                    HStack {
                        Text("概日リズム")
                            .font(.caption)
                        Button(action: {
                            }){
                                Text("i")
                                   .font(.largeTitle)
                            }
                        Spacer()
                    }
                    HStack(alignment: .lastTextBaseline) {
                        Text("100")
                            .font(.title)
                            .foregroundColor(.blue)
                        Text("/100")
                            .font(.caption)
                        Text("非常に安定している")
                            .font(.caption)
                        Spacer()
                    }
                    HStack {
                        CircadianRhythmGraphView(input: .init(datePublisher: viewModel.selectedDate))
                            .frame(width: .infinity, height: 300, alignment: .center)
                    }
                    HStack {
                        Text("記録したデータ")
                            .font(.caption)
                        Spacer()
                    }
                }
            }
        }
//        ScrollView(content: {
//            VStack(alignment: .center) {
//                // 左寄せ
//                HStack {
//                    Text("1月1日の記録")
//                        .font(.title)
//                    Spacer()
//                }
//
//                // 中央揃え
////                Text("中央揃え")
////
////                // 右寄せ
////                HStack {
////                    Spacer()
////                    Text("右寄せ")
////                }
//
//            }.padding()
//
//            ForEach(viewModel.diagnosisResults, id: \.self) { result in
//                Text("\(DateUtils.stringFromDate(date: result.date, format: "yyyy/MM/dd")): \(result.diagnosis.rawValue)")
//            }
//        })
    }
}

struct DementiaPossibilityDiagnosisView_Previews: PreviewProvider {
    static var previews: some View {
        DementiaPossibilityDiagnosisView()
    }
}
