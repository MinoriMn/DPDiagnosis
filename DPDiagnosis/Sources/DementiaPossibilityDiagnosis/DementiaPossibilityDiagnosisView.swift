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
//            ForEach(viewModel.heartRate, id: \.self) { hr in
//                Text("\(hr.endDatetime) \(hr.value)")
//            }
            Text("\(viewModel.diagnosisResult.date): \(viewModel.diagnosisResult.diagnosis.rawValue)")
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
