// SPDX-FileCopyrightText: Copyright (c) 2023-2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: LicenseRef-NvidiaProprietary
//
// NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
// property and proprietary rights in and to this material, related
// documentation and any modifications thereto. Any use, reproduction,
// disclosure or distribution of this material and related documentation
// without an express license agreement from NVIDIA CORPORATION or
// its affiliates is strictly prohibited.

import RealityKit
import Foundation
import CloudXRKit
import SwiftUI
import ARKit

@Observable
class AppModel {
    var openImmersiveSpace: OpenImmersiveSpaceAction!
    var dismissImmersiveSpace: DismissImmersiveSpaceAction!
    var openWindow: OpenWindowAction!
    var dismissWindow: DismissWindowAction!

    let initPositionOffset = simd_float3(0, 0, 0)

    let cxrSession = CloudXRSession(config: CloudXRKit.Config())

    let hmdProperties = HmdProperties()

    let sessionEntity = Entity()

    static private let savedSettings = SavedSettings()

    var configWindowIsOpen: Bool = false {
        didSet {
            // Reopen the window if the stream is running.
            if !configWindowIsOpen && cxrSession.state == .connected {
                // We might get into a situation where we falsely identify the config window as closed,
                // especially when transitioning to immersive space open and when the headset is taken
                // off. Hence, before opening the window again, we make sure everything is closed.
                Task { @MainActor in
                    dismissWindow(id: configViewTitle)
                    openWindow(id: configViewTitle)
                    configWindowIsOpen = true
                }
            }
        }
    }

    var immersiveSpaceIsOpen: Bool = false

    var teleopRunning: Bool = false

    var ipAddress = savedSettings.ipAddress {
        didSet {
            Self.savedSettings.ipAddress = ipAddress
        }
    }

    func appScenePhaseChanged(to scenePhase: ScenePhase) {
        // If the app scene phase has changed to inactive, dismiss the immersive space as well.
        // This will automatically disconnect the session.
        if scenePhase == .background && immersiveSpaceIsOpen {
            Task { @MainActor in
                await dismissImmersiveSpace()
            }
        }
    }

    func windowScenePhaseChanged(to scenePhase: ScenePhase) {
        if scenePhase == .active {
            configWindowIsOpen = true
        } else if scenePhase == .background {
            // This may have false positives, hence before we re-open the window, we
            // make sure everything is closed.
            configWindowIsOpen = false
        }
    }

    @MainActor
    func onFirstWindowAppear(
        openImmersiveSpace: OpenImmersiveSpaceAction,
        dismissImmersiveSpace: DismissImmersiveSpaceAction,
        openWindow: OpenWindowAction,
        dismissWindow: DismissWindowAction
    ) {
        self.openImmersiveSpace = openImmersiveSpace
        self.dismissImmersiveSpace = dismissImmersiveSpace
        self.openWindow = openWindow
        self.dismissWindow = dismissWindow

        configWindowIsOpen = true

        // Make sure this happens before the IPD check.
        CloudXRKit.registerSystems()

        hmdProperties.beginIpdCheck(
            openImmersiveSpace: openImmersiveSpace
        )
    }
}
