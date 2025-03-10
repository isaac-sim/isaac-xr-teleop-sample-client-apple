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

@main
struct IsaacXRTeleopClientApp: App {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scenePhase

    private let appModel = AppModel()

    // Window size
    static let launchSize = CGSize(width: 500, height: 550)

    var body: some Scene {
        FetchHmdPropertiesImmersiveSpace(hmdProperties: appModel.hmdProperties)

        WindowGroup(id: configViewTitle) {
            TopConfigView(viewModel: TopConfigView.ViewModel(appModel: appModel))
                .onAppear {
                    appModel
                        .onFirstWindowAppear(
                            openImmersiveSpace: openImmersiveSpace,
                            dismissImmersiveSpace: dismissImmersiveSpace,
                            openWindow: openWindow, dismissWindow: dismissWindow
                        )
                }
                .frame(
                    // Fixed-size window
                    minWidth: Self.launchSize.width,
                    maxWidth: Self.launchSize.width,
                    minHeight: Self.launchSize.height,
                    maxHeight: Self.launchSize.height,
                    alignment: .top
                )
        }
        .defaultSize(Self.launchSize)
        .windowResizability(.contentSize)
        .onChange(of: scenePhase) {
            appModel.appScenePhaseChanged(to: scenePhase)
        }

        ImmersiveSpace(id: streamingSpaceTitle) {
            StreamingView(viewModel: StreamingView.ViewModel(appModel: appModel))
        }
    }
}
