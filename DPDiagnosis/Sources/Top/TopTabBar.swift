//
//  TopTabBar.swift
//  DPDiagnosis
//
//  Created by 松田尚也 on 2021/11/24.
//

import SwiftUI

struct TopTabBar: View {
    var body: some View {
            TabView {
                DementiaPossibilityDiagnosisView()
                    .tabItem {
                        VStack {
                            Image(systemName: "a")
                            Text("TabA")
                        }
                }.tag(1)
                DementiaPreventionView()
                    .tabItem {
                        VStack {
                            Image(systemName: "bold")
                            Text("TabB")
                        }
                }.tag(2)
            }
        }
}

struct TopTabBar_Previews: PreviewProvider {
    static var previews: some View {
        TopTabBar()
    }
}
