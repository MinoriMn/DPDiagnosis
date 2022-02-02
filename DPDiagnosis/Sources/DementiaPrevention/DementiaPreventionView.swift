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
        UITableView.appearance().separatorColor = UIColor.white
        return List {
            Section ( header: VStack (alignment: .center) {
                HStack {
                    Text("生理的アプローチ")
                        .font(.title)
                    Spacer()
                }
                HStack {
                    Text("睡眠")
                        .font(.title2)
                    Spacer()
            }})
            {
                ForEach(viewModel.sleepInfos, id: \.self) { info in
                    NavigationLink(destination: PreventionDetailView()) {
                        Text(info.description)
                            .foregroundColor(.white)
                    }
                }
                .listRowBackground(
                    Color(.sRGB, red: 0, green: 52/255, blue: 100/255, opacity: 1)
                )
            }


            Section ( header: VStack (alignment: .center) {
                HStack {
                    Text("運動")
                        .font(.title2)
                    Spacer()
            }})
            {
                ForEach(viewModel.activeInfos, id: \.self) { info in
                    NavigationLink(destination: PreventionDetailView()) {
                        Text(info.description)
                            .foregroundColor(.white)
                    }
                }
                .listRowBackground(
                    Color(.sRGB, red: 0, green: 52/255, blue: 100/255, opacity: 1)
                )
            }

            Section ( header: VStack (alignment: .center) {
                HStack {
                    Text("認知的アプローチ")
                        .font(.title)
                    Spacer()
                }
                HStack {
                    Text("知的活動")
                        .font(.title2)
                    Spacer()
            }})
            {
                ForEach(viewModel.ackInfos, id: \.self) { info in
                    NavigationLink(destination: PreventionDetailView()) {
                        Text(info.description)
                            .foregroundColor(.white)
                    }
                }
                .listRowBackground(
                    Color(.sRGB, red: 0, green: 52/255, blue: 100/255, opacity: 1)
                )
            }

            Section ( header: VStack (alignment: .center) {
                HStack {
                    Text("社会活動")
                        .font(.title2)
                    Spacer()
            }})
            {
                ForEach(viewModel.socialInfos, id: \.self) { info in
                    NavigationLink(destination: PreventionDetailView()) {
                        Text(info.description)
                            .foregroundColor(.white)
                    }
                }
                .listRowBackground(
                    Color(.sRGB, red: 0, green: 52/255, blue: 100/255, opacity: 1)
                )
            }

        }
    }
}

struct DementiaPreventionView_Previews: PreviewProvider {
    static var previews: some View {
        DementiaPreventionView()
    }
}
