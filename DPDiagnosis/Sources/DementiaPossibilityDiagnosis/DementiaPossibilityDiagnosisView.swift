import Combine
import SwiftUI

struct DementiaPossibilityDiagnosisView: View {
    @ObservedObject var viewModel = DementiaPossibilityDiagnosisViewModel()

    private let selectedDate = PassthroughSubject<Date, Never>()

    private var cancellables: [AnyCancellable] = []

    init() {
        bind()

        //DEBUG
        
    }

    private func bind() {
        viewModel.transform(input: .init(
            selectedDate: selectedDate
        ))
    }

    var body: some View {
        List {
            Section () {
                VStack(alignment: .center) {
                    HStack {
                        Text("あなたの\n認知症可能性")
                            .font(.largeTitle)
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
            Section (header: Text(DateUtils.stringFromDate(date: viewModel.currentDate, format: "M/d") + "の記録").font(.title)) {
                VStack(alignment: .center) {
                    HStack {
                        Text("概日リズム")
                            .font(.title2)
                        Button(action: {
                            }){
                                Text("i")
                                   .font(.title) //TODO
                            }
                        Spacer()
                    }
                    HStack(alignment: .lastTextBaseline) {
                        Text("100")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("/100")
                            .font(.headline)
                            .fontWeight(.medium)
                        Text("非常に安定している")
                            .font(.headline)
                        Spacer()
                    }
                    HStack {
                        CircadianRhythmGraphView(input: .init(datePublisher: viewModel.selectedDate))
                            .frame(width: .infinity, height: 300, alignment: .center)

                    }
                    HStack {
                        Text("記録したデータ")
                            .font(.title2)
                        Spacer()
                    }
                }
            }
        }
    }
}

struct DementiaPossibilityDiagnosisView_Previews: PreviewProvider {
    static var previews: some View {
        DementiaPossibilityDiagnosisView()
    }
}
