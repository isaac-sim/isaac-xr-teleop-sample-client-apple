// SPDX-FileCopyrightText: Copyright (c) 2023-2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: LicenseRef-NvidiaProprietary
//
// NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
// property and proprietary rights in and to this material, related
// documentation and any modifications thereto. Any use, reproduction,
// disclosure or distribution of this material and related documentation
// without an express license agreement from NVIDIA CORPORATION or
// its affiliates is strictly prohibited.

import SwiftUI
import CloudXRKit

struct SettingsView: View {
    @State var viewModel: ViewModel

    var body: some View {
        Section(header: HStack {
            Text("Interpupillary Distance (IPD)").font(.title2)
            Spacer()
        }) {
            HStack {
                Text("Current IPD value: \(viewModel.roundedIpd) mm")
                Spacer()
                Button("Measure ipd") {
                    viewModel.measureIpd()
                }
                .cornerRadius(20)
                .buttonStyle(.bordered)
                .disabled(viewModel.disableIpdMeasurement)
            }
            .frame(height: 100, alignment: .top)
        }
        .padding()
    }
}

extension SettingsView {
    @Observable
    class ViewModel {
        // Defined for convenience for the HUD.
        let cxrSession: CloudXRSession

        // View-model logic will write to the appModel when UI buttons are pressed.
        let appModel: AppModel

        init(appModel: AppModel) {
            cxrSession = appModel.cxrSession
            self.appModel = appModel
        }

        func measureIpd() {
            appModel.hmdProperties.beginIpdCheck(openImmersiveSpace: appModel.openImmersiveSpace, forceRefresh: true)
        }

        private var disablePerRunParams: Bool {
            switch cxrSession.state {
            case .initialized, .disconnected: false
            default: true
            }
        }

        var disableIpdMeasurement: Bool {
            disablePerRunParams
        }

        var roundedIpd: String {
            String(format: "%.1f", appModel.hmdProperties.measuredIpd * 1000)
        }
    }
}
