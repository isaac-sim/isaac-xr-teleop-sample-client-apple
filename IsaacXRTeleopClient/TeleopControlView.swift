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

struct TeleopControlView: View {
    @State var viewModel: ViewModel

    var body: some View {
        Section(header: HStack {
            Text("Teleoperation Controls").font(.title2)
            Spacer()
        }) {
            VStack {
                HStack {
                    Button {
                        viewModel.teleopStartButtonPressed()
                    } label: {
                        HStack {
                            Image(systemName: viewModel.teleopStartButtonImage)
                            Text(viewModel.teleopStartButtonText)
                        }
                        .frame(width: viewModel.teleopButtonWidth)
                    }
                    .font(.title3)
                    .buttonStyle(.bordered)
                    .disabled(viewModel.teleopStartButtonDisabled)

                    Button {
                        viewModel.teleopStopButtonPressed()
                    } label: {
                        HStack {
                            Image(systemName: viewModel.teleopStopButtonImage)
                            Text(viewModel.teleopStopButtonText)
                        }
                        .frame(width: viewModel.teleopButtonWidth)
                    }
                    .font(.title3)
                    .buttonStyle(.bordered)
                    .disabled(viewModel.teleopStopButtonDisabled)
                }
                Divider()
                Button {
                    viewModel.teleopResetButtonPressed()
                } label: {
                    HStack {
                        Image(systemName: viewModel.teleopResetButtonImage)
                        Text(viewModel.teleopResetButtonText)
                    }
                    .frame(width: viewModel.teleopButtonWidth)
                }
                .font(.title3)
                .buttonStyle(.bordered)
                .disabled(viewModel.teleopButtonsDisabled)
            }
            .frame(height: 100, alignment: .top)
        }
        .padding()
        .onDisappear {
            viewModel.cancelPendingSend()
        }
    }
}

extension TeleopControlView {
    @Observable
    class ViewModel {
        @ObservationIgnored static let logger = Logger()
        private let appModel: AppModel

        private let startTeleopCommand = "start teleop"
        private let stopTeleopCommand = "stop teleop"
        private let resetTeleopCommand = "reset teleop"

        /// True while a deferred send is awaiting channel discovery.
        private var isAwaitingChannel = false

        /// Tracked deferred send task so it can be cancelled on disconnect.
        @ObservationIgnored private var deferredSendTask: Task<Void, Never>?

        var teleopRunning: Bool {
            get { appModel.teleopRunning }
            set { appModel.teleopRunning = newValue }
        }

        init(appModel: AppModel) {
            self.appModel = appModel
        }

        /// Cancel any in-flight deferred send and reset awaiting state.
        /// Called via `.onDisappear` when the teleop view is removed
        /// (e.g. on disconnect, when `showTeleopView` becomes false).
        func cancelPendingSend() {
            deferredSendTask?.cancel()
            deferredSendTask = nil
            isAwaitingChannel = false
        }

        /// Send a teleop command over the message channel.
        ///
        /// When the channel is already available, sends synchronously and
        /// returns `true`.  Otherwise queues a single deferred send that
        /// awaits channel discovery; `onDeferredSuccess` is called if that
        /// deferred send eventually succeeds.
        @discardableResult
        func sendTeleopCommandToServer(command: String, onDeferredSuccess: (() -> Void)? = nil) -> Bool {
            let teleopCommand = ClientToServerCommand(
                type: "teleop_command",
                message: [
                    "command": command
                ]
            )
            let jsonEncoder = JSONEncoder()
            guard let jsonCommand = try? jsonEncoder.encode(teleopCommand) else {
                Self.logger.error("JSON encoding failed.")
                return false
            }

            if let channel = appModel.teleopChannel {
                let success = channel.sendServerMessage(jsonCommand)
                if success {
                    Self.logger.info("Teleop command sent via MessageChannel: \(command)")
                } else {
                    Self.logger.error("MessageChannel.sendServerMessage failed for: \(command)")
                }
                return success
            } else {
                Self.logger.info("MessageChannel not ready, awaiting…")
                isAwaitingChannel = true
                deferredSendTask?.cancel()
                deferredSendTask = Task { [weak self] in
                    guard let self else { return }
                    defer {
                        self.isAwaitingChannel = false
                        self.deferredSendTask = nil
                    }
                    if let channel = await appModel.awaitTeleopChannel() {
                        guard !Task.isCancelled else { return }
                        let success = channel.sendServerMessage(jsonCommand)
                        if success {
                            Self.logger.info("Teleop command sent via MessageChannel (deferred): \(command)")
                            onDeferredSuccess?()
                        } else {
                            Self.logger.error("MessageChannel.sendServerMessage failed (deferred) for: \(command)")
                        }
                    } else {
                        Self.logger.error("Failed to send teleop command: no message channel available")
                    }
                }
                return false
            }
        }

        func teleopStartButtonPressed() {
            if sendTeleopCommandToServer(command: startTeleopCommand, onDeferredSuccess: { [weak self] in
                self?.teleopRunning = true
            }) {
                teleopRunning = true
            }
        }

        func teleopStopButtonPressed() {
            if sendTeleopCommandToServer(command: stopTeleopCommand, onDeferredSuccess: { [weak self] in
                self?.teleopRunning = false
            }) {
                teleopRunning = false
            }
        }

        func teleopResetButtonPressed() {
            sendTeleopCommandToServer(command: resetTeleopCommand)
        }

        var teleopStartButtonText: String {
            "Play"
        }

        var teleopButtonWidth: CGFloat {
            190
        }

        var teleopStartButtonImage: String {
            "play.circle"
        }

        var teleopStopButtonImage: String {
            "stop.circle"
        }

        var teleopResetButtonImage: String {
            "arrow.counterclockwise.circle"
        }

        var teleopResetButtonText: String {
            "Reset"
        }

        var teleopStopButtonText: String {
            "Stop"
        }

        var teleopButtonsDisabled: Bool {
            isAwaitingChannel
        }

        var teleopStartButtonDisabled: Bool {
            teleopRunning || teleopButtonsDisabled
        }

        var teleopStopButtonDisabled: Bool {
            !teleopRunning || teleopButtonsDisabled
        }
    }
}
