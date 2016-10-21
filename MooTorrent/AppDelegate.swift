import Cocoa

/* TODO:
    preference: Timer
    preference: Blacklist
 
 */

@NSApplicationMain
class AppDelegate: NSObject,NSApplicationDelegate,NSMenuDelegate{
    var torrentController: TorrentController?
    var preferenceWindowController: PreferenceWindowController!
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    @IBOutlet weak var contextMenu: NSMenu!
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Did Finish...")
        statusItem.menu = contextMenu
        let img = NSImage(named: "AppIcon")
        if img == nil {
            statusItem.title = "MooTorrent"
        } else {
            img!.size = NSSize.init(width: 24, height: 24)
            statusItem.button!.image = img
        }
        
        contextMenu?.addItem(NSMenuItem(title: "Preferences", action:#selector(self.showPreferences), keyEquivalent: ","))
        contextMenu?.addItem(NSMenuItem.separator())
        contextMenu?.addItem(NSMenuItem(title: "Quit", action: #selector(self.quit), keyEquivalent: "q"))
        
        
        let def = UserDefaults.standard
        if def.bool(forKey: "torrent_controller_saved"){
            torrentController = TorrentController(withDefaults: def)
        } else {
            torrentController = TorrentController()
        }
        torrentController!.blacklist(ssid: "blizzard")
        torrentController!.getShowListNow()
        torrentController!.getShowList(timer: 30.0)
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        self.preferenceWindowController = storyboard.instantiateController(withIdentifier: "preferenceWindowController") as? PreferenceWindowController
        self.preferenceWindowController.setViewsTorrentController(torrentController)
        
    }
    
    @IBAction func updateMenu(sender: NSStatusBarButton) {
        print("SDFSDF")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        print("Saving")
        torrentController?.saveState()
    }
    
    func showPreferences() {
        print("Show Preferences")
        self.preferenceWindowController.showWindow(nil)
        
        
        
        
    
    }
    
    func quit() {
        NSApplication.shared().terminate(self)

    }
    
    
    
    func menuWillOpen(_ menu: NSMenu) {
        print("OPENED!")
        
    }
    
    func menuDidClose(_ menu: NSMenu) {
        print("CLOSED")
    }

    


}
