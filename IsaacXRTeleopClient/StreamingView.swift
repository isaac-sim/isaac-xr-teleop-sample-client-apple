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
import RealityKit
import CloudXRKit
import ARKit

let streamingSpaceTitle = "IsaacTeleopStreamingImmersiveSpace"

struct StreamingView: View {
    @State var viewModel: ViewModel

    var body: some View {
        RealityView { content in
            viewModel.initializeStreamingContent(content: content)
        }
        .upperLimbVisibility(.hidden)
        .persistentSystemOverlays(viewModel.showSystemOverlays)
        .onAppear {
            viewModel.updateImmersiveViewState(open: true)
        }
        .onDisappear {
            viewModel.updateImmersiveViewState(open: false)
        }
    }
}

extension StreamingView {
    @Observable
    class ViewModel {
        private let appModel: AppModel

        init(appModel: AppModel) {
            self.appModel = appModel
        }

        var showSystemOverlays: Visibility {
            (appModel.cxrSession.state == .connected) ? .hidden : .visible
        }

        func updateImmersiveViewState(open: Bool) {
            appModel.immersiveSpaceIsOpen = open

            // If immersive space is dismissed by crown, make the
            // app disconnect.
            if !open && appModel.cxrSession.state == .connected {
                appModel.cxrSession.disconnect()
            }
        }

        func initializeStreamingContent(content: RealityViewContent) {
            let sessionEntity = appModel.sessionEntity
            sessionEntity.name = "Session"

            if appModel.cxrSession.state != .connected {
                print("Oops, we shouldn't be trying to render CloudXR without being connected!")
            }

            sessionEntity.components[CloudXRSessionComponent.self] = .init(session: appModel.cxrSession)
            sessionEntity.transform = .init()
            sessionEntity.position += appModel.initPositionOffset

            content.add(sessionEntity)
        }
    }
}
