import SwiftUI
import OSLog
import KeyboardShortcuts

struct SettingsView: View {

    // MARK: Persisted Application State

    // IMPORTANT: these @AppStorage-wrapped properties are deliberately not
    // marked as private. See `UserSettings` for details.

    @AppStorage(UserSettings.Constants.Names.keybindingMode)
    var keybindingMode = UserSettings.Constants.DefaultValues.keybindingMode

    @AppStorage(UserSettings.Constants.Names.primaryColor)
    var primaryColor = UserSettings.Constants.DefaultValues.primaryColor

    @AppStorage(UserSettings.Constants.Names.secondaryColor)
    var secondaryColor = UserSettings.Constants.DefaultValues.secondaryColor

    @AppStorage(UserSettings.Constants.Names.showGridLines)
    var showGridLines = UserSettings.Constants.DefaultValues.showGridLines

    @AppStorage(UserSettings.Constants.Names.showGridLabels)
    var showGridLabels = UserSettings.Constants.DefaultValues.showGridLabels

    @AppStorage(UserSettings.Constants.Names.targetGridCellSideLength)
    var targetGridCellSideLength = UserSettings.Constants.DefaultValues.targetGridCellSideLength

    @AppStorage(UserSettings.Constants.Names.gridViewOverallContrast)
    var gridViewOverallContrast = UserSettings.Constants.DefaultValues.gridViewOverallContrast

    @AppStorage(UserSettings.Constants.Names.elementViewOverallContrast)
    var elementViewOverallContrast = UserSettings.Constants.DefaultValues.elementViewOverallContrast

    // MARK: User Interface

    private enum Tabs: Hashable {
        case keybindings
        case presentation
    }

    var body: some View {
        TabView {
            KeybindingsSettingsView(keybindingMode: $keybindingMode)
                .tabItem {
                    Label("Keybindings", systemImage: "keyboard")
                }
                .tag(Tabs.keybindings)
            PresentationSettingsView(
                primaryColor: $primaryColor,
                secondaryColor: $secondaryColor,
                showGridLines: $showGridLines,
                showGridLabels: $showGridLabels,
                targetGridCellSideLength: $targetGridCellSideLength,
                gridViewOverallContrast: $gridViewOverallContrast,
                elementViewOverallContrast: $elementViewOverallContrast
                ).tabItem {
                    Label("Presentation", systemImage: "scribble.variable")
                }
                .tag(Tabs.presentation)
        }
        .padding(20)
        .frame(width: 460)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

struct KeybindingsSettingsView: View {

    @Binding var keybindingMode: KeybindingMode

    var body: some View {
        Form {
            Picker("Keybinding Mode:", selection: $keybindingMode) {
                Text("Emacs/ MacOS").tag(KeybindingMode.emacs)
                Text("vi").tag(KeybindingMode.vi)
            }
            .onChange(of: keybindingMode) { newValue in
                // Reset the grid, because changing the keybinding mode affects
                // which characters are available to the character-based
                // decision tree.
                (NSApp.delegate as? AppDelegate)?.inputWindow.initializeCoreDataStructuresForGridBasedMovement()

                OSLog.main.log("Now using \(keybindingMode.rawValue, privacy: .public) keybindings.")
            }
            KeyboardShortcuts.Recorder(for: .useElementBasedNavigation).formLabel(Text("Element-Based Navigation:"))
            KeyboardShortcuts.Recorder(for: .useGridBasedNavigation).formLabel(Text("Grid-Based Navigation:"))
            KeyboardShortcuts.Recorder(for: .useFreestyleNavigation).formLabel(Text("Freestyle Navigation:"))
//            Spacer()
//                .frame(height: 40)
//            Button("Restore Defaults", action: restoreDefaultsAction).formLabel(Text("Reset:"))
//            Text("Reset all keybinding-related settings to their default values. This does not impact any other settings.")
//                .font(.subheadline)
//                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 420)
    }

    func restoreDefaultsAction() {
        OSLog.main.log("Restoring default keybinding-related settings.")
        KeyboardShortcuts.reset(.useElementBasedNavigation, .useGridBasedNavigation, .useFreestyleNavigation)
        keybindingMode = UserSettings.Constants.DefaultValues.keybindingMode
    }

}

struct KeybindingsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        KeybindingsSettingsView(keybindingMode: .constant(.emacs))
    }
}

struct PresentationSettingsView: View {

    @Binding var primaryColor: Color
    @Binding var secondaryColor: Color
    @Binding var showGridLines: Bool
    @Binding var showGridLabels: Bool
    @Binding var targetGridCellSideLength: Double
    @Binding var gridViewOverallContrast: Double
    @Binding var elementViewOverallContrast: Double

    let targetGridCellSideLengthConfig = UserSettings.Constants.Sliders.targetGridCellSideLength
    let gridViewOverallContrastConfig = UserSettings.Constants.Sliders.gridViewOverallContrast
    let elementViewOverallContrastConfig = UserSettings.Constants.Sliders.elementViewOverallContrast

    var body: some View {
        Form {
            ColorPicker("Primary Color:", selection: $primaryColor, supportsOpacity: false)
            ColorPicker("Secondary Color:", selection: $secondaryColor, supportsOpacity: false)
            Slider(value: $elementViewOverallContrast, in: elementViewOverallContrastConfig.range, step: elementViewOverallContrastConfig.step) {
                Label("Element Contrast:", systemImage: "gear")
            }
                .labelStyle(TitleOnlyLabelStyle())
            Slider(value: $gridViewOverallContrast, in: gridViewOverallContrastConfig.range, step: gridViewOverallContrastConfig.step) {
                Label("Grid Contrast:", systemImage: "gear")
            }
                .labelStyle(TitleOnlyLabelStyle())
            Toggle("Show grid lines", isOn: $showGridLines)
            Toggle("Show grid labels", isOn: $showGridLabels)
            Slider(value: $targetGridCellSideLength, in: targetGridCellSideLengthConfig.range, step: targetGridCellSideLengthConfig.step) {
                Label("Grid Cell Size:", systemImage: "gear")
            }
                .labelStyle(TitleOnlyLabelStyle())
            Spacer()
                .frame(height: 40)
            Button("Restore Defaults", action: restoreDefaultsAction).formLabel(Text("Reset:"))
            Text("Reset all presentation-related settings to their default values. This does not impact keybindings or other settings.")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onChange(of: showGridLines) { newValue in
            OSLog.main.log("Toggled showGridLines to \(showGridLines).")
            (NSApp.delegate as? AppDelegate)?.inputWindow.redrawJumpViews()
        }
        .onChange(of: showGridLabels) { newValue in
            OSLog.main.log("Toggled showGridLabels to \(showGridLabels).")
            (NSApp.delegate as? AppDelegate)?.inputWindow.redrawJumpViews()
        }
        .onChange(of: targetGridCellSideLength) { newValue in
            OSLog.main.log("Changed targetGridCellSideLength to \(targetGridCellSideLength).")
            (NSApp.delegate as? AppDelegate)?.inputWindow.initializeCoreDataStructuresForGridBasedMovement()
            (NSApp.delegate as? AppDelegate)?.inputWindow.redrawJumpViews()
        }
        .onChange(of: gridViewOverallContrast) { [gridViewOverallContrast] newValue in
            OSLog.main.log("Changed gridViewOverallContrast to \(newValue) from \(gridViewOverallContrast).")
            (NSApp.delegate as? AppDelegate)?.inputWindow.updateGridViewContrast()
        }
        .onChange(of: elementViewOverallContrast) { [elementViewOverallContrast] newValue in
            OSLog.main.log("Changed elementViewOverallContrast to \(newValue) from \(elementViewOverallContrast).")
            (NSApp.delegate as? AppDelegate)?.inputWindow.updateElementViewContrast()
        }
        .onChange(of: primaryColor) { newValue in
            OSLog.main.log("Changed primaryColor to \(newValue).")
            (NSApp.delegate as? AppDelegate)?.inputWindow.redrawJumpViews()
        }
        .onChange(of: secondaryColor) { newValue in
            OSLog.main.log("Changed secondaryColor to \(newValue).")
            (NSApp.delegate as? AppDelegate)?.inputWindow.redrawJumpViews()
        }
        .padding(20)
        .frame(width: 420)
    }

    func restoreDefaultsAction() {
        OSLog.main.log("Restoring default presentation-related settings.")
        primaryColor = UserSettings.Constants.DefaultValues.primaryColor
        secondaryColor = UserSettings.Constants.DefaultValues.secondaryColor
        showGridLines = UserSettings.Constants.DefaultValues.showGridLines
        showGridLabels = UserSettings.Constants.DefaultValues.showGridLabels
        targetGridCellSideLength = UserSettings.Constants.DefaultValues.targetGridCellSideLength
        gridViewOverallContrast = UserSettings.Constants.DefaultValues.gridViewOverallContrast
        elementViewOverallContrast = UserSettings.Constants.DefaultValues.elementViewOverallContrast
    }

}

struct PresentationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PresentationSettingsView(
            primaryColor: .constant(Color("PrimaryColor")),
            secondaryColor: .constant(Color("SecondaryColor")),
            showGridLines: .constant(false),
            showGridLabels: .constant(true),
            targetGridCellSideLength: .constant(60),
            gridViewOverallContrast: .constant(0.0),
            elementViewOverallContrast: .constant(0.0)
        )
    }
}
