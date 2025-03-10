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
import os.log

struct StreamingControlsView: View {
    @State var viewModel: ViewModel

    var body: some View {
        Section(header: HStack {
            VStack(alignment: .leading) {
                Text("Session Controls").font(.title2)
                if viewModel.showConnectionStatus {
                    Text(viewModel.connectingText).font(.callout)
                } else {
                    // Blank line to keep UI height consistent when the connecting text appears
                    Text(" ").font(.callout)
                }
            }
            Spacer()
        }) {
            HStack {
                TextField("0.0.0.0", text: $viewModel.ipAddress)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.decimalPad)
                    .searchDictationBehavior(.inline(activation: .onLook))
                    .disabled(viewModel.ipFieldDisabled)
                    .onAppear { UITextField.appearance().clearButtonMode = .whileEditing }

                Button {
                    viewModel.pressConnectionButton()
                } label: {
                    HStack {
                        viewModel.connectionButtonIcon
                        Text(viewModel.connectionButtonText)
                    }
                    .frame(width: 190)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.connectionButtonDisabled)
                .tint(viewModel.connectionButtonColor)
            }
        }
        .onChange(of: viewModel.connectionState) { oldValue, newValue in
            viewModel.connectionStateChanged(oldValue: oldValue, newValue: newValue)
        }
        .padding()
    }
}

extension StreamingControlsView {
    @Observable
    class ViewModel {
        @ObservationIgnored static let logger = Logger()
        let appModel: AppModel

        init(appModel: AppModel) {
            self.appModel = appModel
        }

        var connectionState: SessionState {
            appModel.cxrSession.state
        }

        var connectionButtonColor: Color? {
            if connectionState == .connected {
                .red
            } else {
                nil
            }
        }

        var connectionButtonText: String {
            switch connectionState {
            case .disconnected, .initialized:
                "Connect"
            default:
                "Disconnect"
            }
        }

        var connectionButtonIcon: Image {
            switch connectionState {
            case .disconnected, .initialized:
                Image(systemName: "plus")
            default:
                Image(systemName: "x.circle.fill")
            }
        }

        var connectingText: String {
            "Connecting..."
        }

        var showConnectionStatus: Bool {
            switch connectionState {
            case .connecting, .authenticating, .authenticated:
                true
            default:
                false
            }
        }

        func connectionStateChanged(
            oldValue: SessionState,
            newValue: SessionState
        ) {
            Task { @MainActor in
                if newValue == .connected {
                    if !appModel.immersiveSpaceIsOpen {
                        await appModel.openImmersiveSpace(id: streamingSpaceTitle)
                    }
                } else {
                    if appModel.immersiveSpaceIsOpen {
                        await appModel.dismissImmersiveSpace()
                    }
                }
            }
        }

        func pressConnectionButton() {
            switch connectionState {
            case .connected:
                disconnect()
            default:
                connect()
            }
        }

        private func disconnect() {
            Task { @MainActor in
                appModel.cxrSession.disconnect()
            }
        }

        private func connect() {
            Task { @MainActor in
                switch connectionState {
                case .initialized, .disconnected:
                    var config = CloudXRKit.Config()

                    config.connectionType = .local(ip: ipAddress)
                    config.resolutionPreset = .standardPreset
                    config.handTrackingMode = .legacy
                    appModel.cxrSession.configure(config: config)
                    try await appModel.cxrSession.connect()
                default:
                    let errorMessage = "Connect button pressed when state was \(self.connectionState)"
                    Self.logger.error("Streaming controls state machine error: \(errorMessage)")
                }
            }
        }

        var ipAddress: String {
            get { appModel.ipAddress }
            set {
                appModel.ipAddress = newValue.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
        }

        var ipFieldDisabled: Bool {
            switch connectionState {
            case .initialized, .disconnected:
                false
            default:
                true
            }
        }

        var connectionButtonDisabled: Bool {
            switch connectionState {
            case .disconnected, .initialized:
                ipAddress.isEmpty
            case .connected:
                false
            default:
                true
            }
        }
    }
}

#Preview {
    StreamingControlsView(viewModel: StreamingControlsView.ViewModel(appModel: AppModel()))
}
