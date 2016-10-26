//
//  ViewController.swift
//  MooTorrent
//
//  Created by mnapolit on 10/11/16.
//  Copyright © 2016 Micmoo. All rights reserved.
//

import Cocoa
class PreferenceWindowController: NSWindowController {
    override var windowNibName : String! {
        return "Preferences"
    }

    func setViewsTorrentController(_ torrentController: TorrentController?) {
        let cvc = self.window?.contentViewController as? PreferenceViewController
        cvc?.torrentController = torrentController
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        self.window?.makeKey()
        self.window?.orderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        print("Window did load")
    }
}

class PreferenceViewController: NSViewController {
    @IBOutlet dynamic var torrentController: TorrentController?
    @IBOutlet weak dynamic var showDictionary: NSDictionaryController?
    dynamic var blacklist: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        print("view is appearing!")
        if torrentController == nil {
            return
        }
        blacklist = torrentController!.networkBlacklist.joined(separator: ", ")

    }
    
    override func viewWillDisappear() {
        torrentController?.networkBlacklist.removeAll(keepingCapacity: true)
        for ssid in blacklist.components(separatedBy: ",") {
            torrentController?.blacklist(ssid: ssid.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        torrentController?.saveState()
    }
    
    @IBAction func addShow(sender: AnyObject?) {
        let s = Show(name: "New Show.")
        s.keyword = "HDTV"
        torrentController?.shows["New Show"] = s
    }
    
}

