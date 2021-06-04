import Cocoa
import Carbon
import HotKey

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var menu: NSMenu!

    var statusItem: NSStatusItem?

    @IBOutlet weak var hideMenuItem: NSMenuItem!

    @IBOutlet weak var showMenuItem: NSMenuItem!

    lazy var inputWindow: KeyboardInputWindow = {
        NSApp.orderedWindows.compactMap({ $0 as? KeyboardInputWindow }).first!
    }()

    var gridWindowControllers = [GridWindowController]()

    var gridWindows: [GridWindow] {
        gridWindowControllers.compactMap { $0.window as? GridWindow }
    }

    var gridViewControllers: [GridViewController] {
        gridWindowControllers.compactMap { $0.contentViewController as? GridViewController }
    }

    public var hotKey: HotKey? {
        didSet {
            guard let hotKey = hotKey else {
                return
            }

            hotKey.keyDownHandler = { [weak self] in
                self?.bringToForeground()
            }
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.hotKey = HotKey(key: .j, modifiers: [.command, .shift])
        self.configureMenuBarExtra()

        for screen in NSScreen.screens {
            self.spawnGridWindow(on: screen)
        }

        self.inputWindow.initializeCoreDataStructures()

        self.initializeChangeScreenParametersObserver()

        self.bringToForeground()
    }

    func applicationWillTerminate(_ aNotification: Notification) {

    }

    // MARK: Handling Screen Changes

    func spawnGridWindow(on screen: NSScreen) {
        let controller = GridWindowController.spawn(on: screen)
        gridWindowControllers.append(controller)
    }

    func resizeGridWindow(managedBy controller: GridWindowController, to size: NSRect) {
        controller.setWindowFrame(size)
    }

    func closeGridWindow(managedBy controller: GridWindowController) {
        controller.close()
        gridWindowControllers.removeAll(where: {
            $0 == controller
        })
    }

    func initializeChangeScreenParametersObserver() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared,
            queue: OperationQueue.main
        ) { [weak self] notification in

            guard let self = self else {
                return
            }

            var mustReinitialize = false

            for windowController in self.gridWindowControllers {
                guard let screen = windowController.assignedScreen,
                    NSScreen.screens.contains(screen),
                    let window = windowController.window
                else {
                    self.closeGridWindow(managedBy: windowController)
                    mustReinitialize = true
                    continue
                }

                guard window.frame == screen.frame else {
                    // Resize the window: screen dimensions have changed.
                    self.resizeGridWindow(managedBy: windowController, to: screen.visibleFrame)
                    mustReinitialize = true
                    continue
                }
            }

            let assignedScreens = self.gridWindowControllers.compactMap {
                $0.assignedScreen
            }

            let addedScreens = Set(NSScreen.screens).subtracting(assignedScreens)

            for screen in addedScreens {
                self.spawnGridWindow(on: screen)
                mustReinitialize = true
            }

            if mustReinitialize {
                self.inputWindow.initializeCoreDataStructures()
            }
        }
    }

    // MARK: Convenience

    func gridWindowController(for screen: NSScreen) -> GridWindowController? {
        self.gridWindowControllers.first(where: {
            $0.assignedScreen == screen
        })
    }

    // MARK: Menu Bar

    func configureMenuBarExtra() {
        let item = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        let image = NSImage(named: "MenuIcon")
        image?.isTemplate = true

        item.button?.image = image
        item.button?.image?.size = NSSize(width: 18.0, height: 18.0)

        item.menu = menu

        self.statusItem = item
    }

    // MARK: Activation

    func bringToForeground() {
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.async {
            self.gridWindows.forEach { window in
                window.orderFront(self)
            }
            self.inputWindow.makeMain()
            self.inputWindow.makeKeyAndOrderFront(self)
        }
    }

    // MARK: Deactivation

    func bringToBackground() {
        NSApp.hide(self)
    }

    // MARK: Actions

    @IBAction func hidePressed(_ sender: NSMenuItem) {
        bringToBackground()
    }

    @IBAction func showPressed(_ sender: NSMenuItem) {
        bringToForeground()
    }

    @IBAction func helpPressed(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(URL(string: "https://github.com/mjrusso/scoot")!)
    }

}
