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
class TorrentController: NSObject, ShowSiteDelegate {
    dynamic var shows : Dictionary<String, Show> = Dictionary() {
        willSet {
            for (k,_) in newValue {
                newValue[k.capitalized]?.name = k.capitalized
            }
        }
    }
    
    
    
    var showSite : ShowSite
    var networkBlacklist: Set<String> = Set()
    var downloadQueue : Set<Show> = Set()
    var timer: Timer? = nil
    dynamic var url: String?  {
        get { return showSite.url }
        set(new){ showSite.url = new! }
    }
    
    override init() {
        showSite = EZTV()
        super.init()
        showSite.delegate = self

    }

    init(shows sshows: Array<String>){
        showSite = EZTV()
        for s in sshows {
            self.shows[s] = Show(name:s)
        }
        super.init()
        showSite.delegate = self
    }
    
    init(withDefaults def: UserDefaults){
        print("Loading Defaults!")
        let data_shows = def.data(forKey: "torrent_controller_shows")
        if data_shows != nil {
            self.shows = NSKeyedUnarchiver.unarchiveObject(with: data_shows!) as? Dictionary<String, Show> ?? Dictionary()
            for (_,v) in self.shows {
                print(v.description)
            }
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
        super.init()
        showSite.delegate = self
    }
    
    func addShow(name: String) {
        let name = name.capitalized
        if self.shows[name] == nil {
            self.shows[name] = Show(name:name)
        }
    }
    func removeShow(name: String) {
        let name = name.capitalized
        self.shows.removeValue(forKey: name)
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
    
    // TODO: Handle getting two new shows at once.
    
    func gotNewShows(shows: Dictionary<String, Set<Show>>) {
        for (showName, showSet) in shows {
            var showDict: Dictionary<String, Set<Show>> = Dictionary()
            for show in showSet {
                if showDict[show.episode] == nil {
                    showDict[show.episode] = Set()
                }
                showDict[show.episode]!.insert(show)
            }
            
            for (episode, episodeSet) in showDict {
                print("Got New Show \(showName) \(episode)")
                let currShow : Show? = self.shows[showName]
                if currShow == nil {
                    continue
                }
                var smallestSize = Int.max
                var smallestShow: Show? = nil
                
                for show in episodeSet {
                    if episode > currShow!.episode{
                        if currShow!.keyword != nil && show.keyword == nil {
                            continue
                        }
                        if currShow!.keyword != nil && currShow!.keyword!.characters.count != 0 {
                            if show.keyword!.contains(currShow!.keyword!) {
                                smallestShow = show
                                break
                            }
                            continue
                        }
                        if show.size != nil && show.size! < smallestSize {
                            smallestSize = show.size!
                            smallestShow = show
                        }
                    }
                }
                
                if smallestShow != nil {
                    synced(lock: downloadQueue){
                        print("Added \(smallestShow!.description) to Queue")
                        downloadQueue.insert(smallestShow!.copy() as! Show)
                    }
                }
            }
        }
        download()
    }
    
    
    func download() {
        let ssid = getSSID()
        if networkBlacklist.contains(ssid) {
            print("Not downloading, ssid \(ssid) blacklisted.")
            return
        }
        var res = false
        synced(lock: downloadQueue){
            while downloadQueue.count > 0 {
                let s = downloadQueue.popFirst()
                if self.shows[s!.name] == nil {
                    continue
                }
                res = downloadShow(show: s!)
                if !res {
                    downloadQueue.insert(s!)
                    break
                }
                if self.shows[s!.name] != nil && s!.episode > self.shows[s!.name]!.episode {
                    self.shows[s!.name]!.episode = s!.episode
                }

            }
        }
        saveState()
    }
    
    
    
    func downloadShow(show: Show) -> Bool{
        print("Starting trying to download show.")
        if NSWorkspace.shared().open(show.magnet!) {
            
            print("Started Download for show \(show.description)")
            return true
        }
        print("Could not open magnet link.")
        return false
    }
    
    func downloadQueueSize() -> Int {
        return downloadQueue.count
    }
    
    
    func saveState() {
        print("Saving")
        let def = UserDefaults.standard
        let ashows = NSKeyedArchiver.archivedData(withRootObject: shows)
        let blist = NSKeyedArchiver.archivedData(withRootObject: networkBlacklist)
        let queue = NSKeyedArchiver.archivedData(withRootObject: downloadQueue)
        def.set(true, forKey: "torrent_controller_saved")
        def.set(ashows, forKey: "torrent_controller_shows")
        def.set(blist, forKey: "torrent_controller_blacklist")
        def.set(queue, forKey: "torrent_controller_queue")
        
        def.synchronize()
        
    }
    
}


func getSSID() -> String {
    return CWWiFiClient()?.interface(withName:nil)?.ssid() ?? ""
}



