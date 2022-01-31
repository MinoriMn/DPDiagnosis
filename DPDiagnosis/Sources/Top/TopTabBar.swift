//
//  TopTabBar.swift
//  DPDiagnosis
//
//  Created by 松田尚也 on 2021/11/24.
//

import SwiftUI

struct TopTabBar: View {
    @ObservedObject var viewModel = TopViewModel()

    init() {}

    var body: some View {
        NavigationView {
            TabView {
                DementiaPossibilityDiagnosisView()
                    .tabItem {
                        VStack {
                            Image(systemName: "heart.text.square")
                                .font(.title)
                            Text("認知症可能性判定")
                        }
                }.tag(1)
                DementiaPreventionView()
                    .tabItem {
                        VStack {
                            Image(systemName: "book")
                                .font(.title)
                            Text("予防知識")
                        }
                }.tag(2)
            }
        }
    }
}

struct TopTabBar_Previews: PreviewProvider {
    static var previews: some View {
        TopTabBar()
    }
}
