import Combine
import SwiftUI

struct DementiaPossibilityDiagnosisView: View {
    @ObservedObject var viewModel = DementiaPossibilityDiagnosisViewModel()

    private var cancellables: [AnyCancellable] = []

    init() {
        bind()
    }

    var body: some View {
        ScrollView(content: {
            ForEach(viewModel.diagnosisResults, id: \.self) { result in
                Text("\(DateUtils.stringFromDate(date: result.date, format: "yyyy/MM/dd")): \(result.diagnosis.rawValue)")
            }
        })
    }

    private func bind() {
        let _ = viewModel.transform(input: .init())
    }
}

struct DementiaPossibilityDiagnosisView_Previews: PreviewProvider {
    static var previews: some View {
        DementiaPossibilityDiagnosisView()
    }
}
