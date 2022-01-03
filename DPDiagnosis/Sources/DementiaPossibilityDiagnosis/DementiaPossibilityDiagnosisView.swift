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
            ForEach(viewModel.sleepAnalysis, id: \.self) { sa in
                Text("\(sa.id)\n\(sa.startDatetime)\n\(sa.endDatetime)\n\(sa.sleepStatus.description())\n")
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
