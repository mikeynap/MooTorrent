import Cocoa

@NSApplicationMain
class AppDelegate: NSObject,NSApplicationDelegate{
    var torrentController: TorrentController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let default_shows: Array<String> = ["Home and Away", "South Park", "Gotham", "Brooklyn Nine-Nine", "Family Guy", "Billions", "The Big Bang Theory"].map() { $0.capitalized }
        let def = UserDefaults.standard
        if def.bool(forKey: "torrent_controller_saved"){
            torrentController = TorrentController(withDefaults: def)
        } else {
            torrentController = TorrentController(shows: default_shows)
        }
        
        torrentController!.blacklist(ssid: "blizzard")
        torrentController!.getShowListNow()
        torrentController!.getShowList(timer: 5.0)
        
        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        torrentController?.saveState()
        // Insert code here to tear down your application
    }

}
