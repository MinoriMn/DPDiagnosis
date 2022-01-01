//
//  DementiaPreventionView.swift
//  DPDiagnosis
//
//  Created by 松田尚也 on 2021/11/24.
//

import SwiftUI

struct DementiaPreventionView: View {
    @ObservedObject var viewModel = DementiaPreventionViewModel()

    var body: some View {
        List {
            Section (header: Text("AA")) {
                ForEach(viewModel.preventionInfos, id: \.self) { info in
                    NavigationLink(destination: PreventionDetailView()) {
                        Text(info.description)
                    }
                }
            }
            Section (header: Text("AA")) {
                ForEach(viewModel.preventionInfos, id: \.self) { info in
                    Text(info.description)
                }
            }
        }
    }
}

struct DementiaPreventionView_Previews: PreviewProvider {
    static var previews: some View {
        DementiaPreventionView()
    }
}
