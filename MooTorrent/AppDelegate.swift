import Cocoa

@NSApplicationMain
class AppDelegate: NSObject,NSApplicationDelegate,NSMenuDelegate{
    var torrentController: TorrentController?
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    @IBOutlet weak var contextMenu: NSMenu!
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem.menu = contextMenu
        let img = NSImage(named: "AppIcon")
        if img == nil {
            statusItem.title = "MooTorrent"
        } else {
            img!.size = NSSize.init(width: 24, height: 24)
            statusItem.button!.image = img
        }
        
        contextMenu?.addItem(NSMenuItem(title: "Preferences", action:nil, keyEquivalent: "P"))
        contextMenu?.addItem(NSMenuItem.separator())
        contextMenu?.addItem(NSMenuItem(title: "Quit", action: #selector(self.quit), keyEquivalent: "q"))

        
            
        
        let default_shows: Array<String> = ["South Park", "Gotham", "Brooklyn Nine-Nine", "Family Guy", "Billions", "The Big Bang Theory"].map() { $0.capitalized }
        let def = UserDefaults.standard
        if def.bool(forKey: "torrent_controller_saved"){
            torrentController = TorrentController(withDefaults: def)
        } else {
            torrentController = TorrentController(shows: default_shows)
        }
        torrentController!.blacklist(ssid: "blizzard")
        //torrentController!.getShowListNow()
        torrentController!.getShowList(timer: 5.0)
        torrentController!.removeShow(name: "Home and away")
        
        // Insert code here to initialize your application
    }
    
    @IBAction func updateMenu(sender: NSStatusBarButton) {
        print("SDFSDF")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        print("Saving")
        torrentController?.saveState()
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
