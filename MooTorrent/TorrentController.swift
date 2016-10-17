//
//  TorrentController.swift
//  MooTorrent
//
//  Created by mnapolit on 10/17/16.
//  Copyright © 2016 Micmoo. All rights reserved.
//

import Foundation
import AEXML
import CoreWLAN


// TODO: Preference for smaller, larger files.
class TorrentController: ShowSiteDelegate {
    var shows : Dictionary<String, Show> = Dictionary()
    var showSite : ShowSite
    var networkBlacklist: Set<String> = Set()
    var downloadQueue : Set<Show> = Set()
    var timer: Timer? = nil
    init(shows sshows: Array<String>){
        showSite = EZTV()
        showSite.delegate = self
        for s in sshows {
            self.shows[s] = Show(name:s)
        }
    }
    
    init(withDefaults def: UserDefaults){
        print("Loading Defaults!")
        let data_shows = def.data(forKey: "torrent_controller_shows")
        if data_shows != nil {
            self.shows = NSKeyedUnarchiver.unarchiveObject(with: data_shows!) as? Dictionary<String, Show> ?? Dictionary()
        }

        let data_queue = def.data(forKey: "torrent_controller_queue")
        if data_shows != nil {
            self.downloadQueue = NSKeyedUnarchiver.unarchiveObject(with: data_queue!) as? Set<Show> ?? Set()
        }
        let data_blist = def.data(forKey: "torrent_controller_blacklist")
        
        if data_blist != nil {
            self.networkBlacklist = NSKeyedUnarchiver.unarchiveObject(with: data_blist!) as? Set<String> ?? Set()
        }

        showSite = EZTV()
        showSite.delegate = self
    }
    
    func blacklist(ssid: String){
        networkBlacklist.insert(ssid)
    }
    
    @objc func getShowListNow() {
        showSite.syncShows()
    }
    
    func getShowList(timer t: Double) {
        timer = Timer.scheduledTimer(timeInterval: t, target: self, selector: #selector(self.getShowListNow), userInfo: nil, repeats: true)
    }
    
    
    func gotNewShows(shows: Dictionary<String, Set<Show>>) {
        
        for showSet in shows {
            print("Got New Show \(showSet.key)")
            let currShow : Show? = self.shows[showSet.key]
            if currShow == nil {
                continue
            }
            var smallestShow: Show? = nil
            for show in showSet.value {
                if show.episode >= currShow!.episode{
                    if smallestShow == nil {
                        smallestShow = show
                    } else if show.size <= smallestShow!.size {
                        smallestShow = show
                    }
                }
            }
            if smallestShow != nil {
                synced(lock: downloadQueue){
                    // for testing
                    if !downloadQueue.contains(smallestShow!) {
                        print("Added \(smallestShow!.name) to queue.")
                    }
                    downloadQueue.insert(smallestShow!)
                }
            }
        }
        download()
    }
    
    func download() {
        if networkBlacklist.contains(getSSID()) {
            print("Not downloading, ssid blacklisted.")
            return
        }
        var failed: Set<Show> = []
        synced(lock: downloadQueue){
            while downloadQueue.count > 0 {
                let s = downloadQueue.popFirst()
                if !downloadShow(show: s!) {
                    failed.insert(s!)
                } else {
                    print("Downloaded show \(s?.name)")
                    self.shows[s!.name] = s!
                }
            }
            downloadQueue = failed
        }
    }
    
    
    
    func downloadShow(show: Show) -> Bool{
        if NSWorkspace.shared().open(show.magnet!) {
            print("Started Download for show \(show.name)")
            return true
        }
        return false
    }
    
    func getSSID() -> String {
        return CWWiFiClient()?.interface(withName:nil)?.ssid() ?? ""
    }
    
    func saveState() {
        let def = UserDefaults.standard
        let ashows = NSKeyedArchiver.archivedData(withRootObject: shows)
        let blist = NSKeyedArchiver.archivedData(withRootObject: networkBlacklist)
        let queue = NSKeyedArchiver.archivedData(withRootObject: downloadQueue)
        def.set(true, forKey: "torrent_controller_saved")
        def.set(ashows, forKey: "torrent_controller_shows")
        def.set(blist, forKey: "torrent_controller_blacklist")
        def.set(queue, forKey: "torrent_controller_queue")
    }
    
}
func synced(lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}


