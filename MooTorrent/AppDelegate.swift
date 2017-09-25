import Cocoa
import ServiceManagement
import Sparkle
/* TODO:
    preference: Timer
    preference: Blacklist
 
 */

@NSApplicationMain
class AppDelegate: NSObject,NSApplicationDelegate,NSMenuDelegate,SUUpdaterDelegate,TVDBControllerDelegate{
    var torrentController: TorrentController?
    var preferenceWindowController: PreferenceWindowController!
    var tvdbController: TVDBController?
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    @IBOutlet weak var contextMenu: NSMenu!
    @IBOutlet weak var sparkle: SUUpdater?
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let appBundleIdentifier = "org.micmoo.MooTorrentLauncher" as CFString
        if !SMLoginItemSetEnabled(appBundleIdentifier, true) {
            print("Could not set enabled...")
        }
        statusItem.menu = contextMenu
        let img = NSImage(named: NSImage.Name(rawValue: "AppIcon"))
        if img == nil {
            statusItem.title = "MooTorrent"
        } else {
            img!.size = NSSize.init(width: 24, height: 24)
            statusItem.button!.image = img
        }
        
        self.setupMenuBar()
        
        ValueTransformer.setValueTransformer(CapitalizedTransformer(), forName: NSValueTransformerName("ValueCapitalizedTransformer"))

        
        let def = UserDefaults.standard
        if def.bool(forKey: "torrent_controller_saved"){
            torrentController = TorrentController(withDefaults: def)
        } else {
            torrentController = TorrentController()
        }
        torrentController!.getShowListNow()
        torrentController!.getShowList(timer: 30.0)
        
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        self.preferenceWindowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "preferenceWindowController")) as? PreferenceWindowController
        self.preferenceWindowController.setViewsTorrentController(torrentController)
        self.tvdbController = TVDBController(apiKey: "D1ACA90DEF7DC26D", userKey: "4C213030526FF008", username: "luigi193")
        if (self.tvdbController != nil) {
            self.tvdbController?.delegate = self
            torrentController!.setTVDBController(tvdbController!)
        }
        
        
        sparkle = SUUpdater.shared()
        
        sparkle?.automaticallyChecksForUpdates = true
        sparkle?.automaticallyDownloadsUpdates = true
        sparkle?.delegate = self
        sparkle?.checkForUpdatesInBackground()
        sparkle?.installUpdatesIfAvailable()
    }
    
    @IBAction func updateMenu(sender: NSStatusBarButton) {
        print("SDFSDF")
    }
    
    func setupMenuBar(){
        contextMenu?.removeAllItems()
        if self.tvdbController != nil {
            let shows = self.tvdbController!.getShowsSorted()
            if shows.count > 0 && shows[0].airsToday(){
                contextMenu?.addItem(NSMenuItem(title: "Airing Today:", action: nil, keyEquivalent: ""))
            }
            for show in shows {
                if show.airsToday() {
                    contextMenu?.addItem(NSMenuItem(title: show.name, action: nil, keyEquivalent: ""))
                }
            }
            if shows.count > 0 && shows[0].airsToday(){
                contextMenu?.addItem(NSMenuItem.separator())
            }
            
            for show in shows {
                if show.airDate != nil && !show.aired() {
                    contextMenu?.addItem(NSMenuItem(title: "\(show.name): \(show.airDate!)", action: nil, keyEquivalent: ""))
                }
            }
        }
        contextMenu?.addItem(NSMenuItem.separator())
        
        contextMenu?.addItem(NSMenuItem(title: "Preferences", action:#selector(self.showPreferences), keyEquivalent: ","))
        contextMenu?.addItem(NSMenuItem(title: "Quit", action: #selector(self.quit), keyEquivalent: "q"))

    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        print("Saving")
        torrentController?.saveState()
    }
    
    @objc func showPreferences() {
        print("Show Preferences 4!")
        self.preferenceWindowController.showWindow(nil)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)

    }
    
    func menuWillOpen(_ menu: NSMenu) {
        self.setupMenuBar()
        print("OPENED!")
        
    }
    
    func menuDidClose(_ menu: NSMenu) {
        print("CLOSED")
    }
    
    func didUpdate() {
        print("Did Update from TVDB.")
    }
    
    func updaterMayCheck(forUpdates updater: SUUpdater!) -> Bool {
        return !amIBeingDebugged()
    }
    
    func updaterShouldRelaunchApplication(_ updater: SUUpdater!) -> Bool {
        print("SHOULD I?")
       return true
    }
    
    func updaterWillRelaunchApplication(_ updater: SUUpdater!) {
        print("Will Relaunch?")
    }
    
    func updater(_ updater: SUUpdater!, willInstallUpdate item: SUAppcastItem!) {
        print("Installing?")
    }
    
    
    func updaterShouldPromptForPermissionToCheck(forUpdates updater: SUUpdater!) -> Bool {
        return false
    }
    
    func updater(_ updater: SUUpdater!, didFinishLoading appcast: SUAppcast!) {
        print("Did Finish Loading Update?")
    }
    
    func updaterDidNotFindUpdate(_ updater: SUUpdater!) {
        print("Didn't find update")
    }
    
    func updater(_ updater: SUUpdater!, didFindValidUpdate item: SUAppcastItem!) {
        print(item.dsaSignature)
    }
    
    func updater(_ updater: SUUpdater!, didAbortWithError didFailWithError: Error) {
        print("Failed...?")
        print(didFailWithError)
    }

}

class CapitalizedTransformer: ValueTransformer {
    override class func allowsReverseTransformation() -> Bool { //Can I transform back?
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? { //Perform transformation
        guard let type = value as? String else { return nil }
        return type.capitalized
        
    }
    override func reverseTransformedValue(_ value: Any?) -> Any? { //Perform transformation
        guard let type = value as? String else { return nil }
        return type.capitalized
        
    }
}

func amIBeingDebugged() -> Bool {
    
    var info = kinfo_proc()
    var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = MemoryLayout<kinfo_proc>.stride
    let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
    assert(junk == 0, "sysctl failed")
    return (info.kp_proc.p_flag & P_TRACED) != 0
}

