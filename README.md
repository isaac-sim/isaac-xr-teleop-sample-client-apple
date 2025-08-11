# Isaac XR Teleop Sample Client

The Isaac XR Teleop Sample Client is a sample app for Apple Vision Pro which enables immersive
streaming and teleoperation of Isaac Sim and Isaac Lab simulations using CloudXR.

This README will walk you through building and installing the Isaac XR Teleop Sample Client.

These instructions are intended to be followed as a subsection of the Isaac Lab documentation:
[Setting Up CloudXR
Teleoperation](https://isaac-sim.github.io/IsaacLab/main/source/how-to/cloudxr_teleoperation.html)


## Requirements

In order to build and install the Isaac XR Teleop Sample Client, please review the following system
requirements:

* Apple Vision Pro with visionOS 2.0 or later
* Apple Silicon based Mac with macOS Sonoma 14.5 or later
* A Wifi network in which both devices are IP-reachable from one another

  Note: we recommend using a dedicated Wifi router, as many institutional wireless networks will
  prevent devices from reaching each other, resulting in the Apple Vision Pro being unable to find
  the Isaac Lab workstation on the network.


## Set Up your Apple Development Environment

On your Mac:

1. Click [here](https://developer.apple.com/programs/enroll/) to create your Apple developer account.

1. Download and install Xcode 16.0+ [here](https://developer.apple.com/xcode/).

   Be sure to install the visionOS platform when prompted to add run destinations.

1. Follow the Xcode documentation to connect your Apple Vision Pro to your Mac
   [here](https://developer.apple.com/documentation/Xcode/running-your-app-in-simulator-or-on-a-device#Connect-real-devices-to-your-Mac).

   Be sure to also follow the instructions to [Enable Developer
   Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device) on
   your device.


# Build the App

On your Mac:

1. Install `git-lfs`:

    ```
    brew install git-lfs
    git lfs install
    ```

1. Clone the Isaac XR Teleop Sample Client GitHub repository:

   ```
   git clone git@github.com:isaac-sim/isaac-xr-teleop-sample-client-apple.git
   ```

1. Open `IsaacXRTeleopClient.xcodeproject` in the root directory of the repository to launch Xcode.
   You'll need to adjust some default profile settings of your project before building.

1. Select the **Project Navigator** tab and select the top level **IsaacXRTeleopClient** object.

1. Change to the **Signing & Capabilities** Tab.

1. Change **Team** to your own team.

1. Change the **Bundle Identifier** to a new unique name, such as
   `com.developername.IsaacXRTeleopClient`.

1. Navigate to **Product > Destination** and change the target device to your Apple Vision Pro.

   Note: You can also run the app in the visionOS simulator, but this mode does not support hand
   tracking inputs.

1. Press the **Play** button, or select **Product > Run**, to build and run the client on your Apple
   Vision Pro.

On your Apple Vision Pro:

1. If you see the prompt `Untrusted Enterprise Developer: <user> has not been trusted on this
   device`, you will need to enable trust for your developer account in order to run the app:

   From the Home screen, go to **Settings > General > Device Management** and trust the certificate
   of your developer account.

   You may need to relaunch the app.

1. The Isaac XR Teleop Sample Client app should open and show the Main UI and session controls.

1. You are now ready to connect to Isaac Sim or Isaac Lab.

   See [Isaac Lab: Setting Up CloudXR
   Teleoperation](https://isaac-sim.github.io/IsaacLab/main/source/how-to/cloudxr_teleoperation.html)
   for how to set up and run CloudXR Teleoperation with Isaac Lab.

# Known Issues

The client may experience latency spikes depending on network conditions. If you encounter this issue, you can enable **Low Latency Streaming (LLS)** by following these steps:

1. Create a new entitlements file:
   - In Xcode, right-click on your folder in the Project Navigator
   - Select "New Empty File"

![](image/README/1754436121710.png)

2. Name the entitlements file:
   - Save it as `IsaacXRTeleopClient.entitlements` in your project directory

![](image/README/1754436245447.png)

3. Configure Low Latency Streaming:
   - Open the entitlements file
   - Add a new key: `com.apple.developer.low-latency-streaming`
   - Set the type to "Boolean" and value to "YES"

![](image/README/1754436304483.png)

4. Apply the entitlements to your build:
   - Select your project in the Project Navigator
   - Go to "Build Settings"
   - Search for "Code Signing Entitlements"
   - Set the path to your newly created `IsaacXRTeleopClient.entitlements` file

![](image/README/1754436298730.png)