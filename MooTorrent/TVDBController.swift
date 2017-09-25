//
//  TVDBController.swift
//  MooTorrent
//
//  Created by mnapolit on 10/26/16.
//  Copyright © 2016 Micmoo. All rights reserved.
//

import Foundation

protocol TVDBControllerDelegate {
    func didUpdate()
}

class TVDBController {
    var tvdb: TVDB
    var shows: [String:ShowAirs] = Dictionary()
    var timer: Timer?
    var authenticated: Bool?
    
    var delegate: TVDBControllerDelegate?
    
    init(apiKey: String, userKey: String, username: String){
        tvdb = TVDB(apiKey: apiKey, userKey: userKey, username: username)
        timer = Timer.scheduledTimer(timeInterval:60.0 , target: self, selector: #selector(checkForUpdates), userInfo: nil, repeats: true)
        tvdb.authenticate(completion: self.didAuthenticate)
    }
    
    func getAirdate(forShow: String) -> String?{
        return shows[forShow]?.airDate
    }
    
    func getShowsSorted() -> [ShowAirs] {
        var rshows: [ShowAirs] = Array()
        for (_,showAirs) in shows {
            if showAirs.airDate != nil {
                rshows.append(showAirs)
            }
        }
        return rshows.sorted(by: { $0.airDate! < $1.airDate! })
    }
    
    func getShowsAiringToday() -> [String] {
        var airingToday: [String] = Array()
        for (name,showAirs) in shows {
            if showAirs.airsToday() {
                airingToday.append(name)
            }
        }
        return airingToday
    }
    
    func didAuthenticate(_ authenticated: Bool){
        print("Did auth?: \(authenticated)")
        if authenticated {
            if self.authenticated == nil {
                self.authenticated = true
                self.checkForUpdates()
            }
            self.authenticated = true
        } else {
            self.authenticated = false
        }
    }
    
    func add(show: String){
        if shows[show] == nil {
            shows[show] = ShowAirs(name:show)
        }
    }
    
    func add(shows: [String]){
        synced(lock: self.shows){
            for s in shows {
                add(show:s)
            }
        }
    }
    
    func getEpisodeAirDate(forShowAirs showAirs: ShowAirs){
        if showAirs.showID == nil {
            return
        }
        if showAirs.lastSeason == nil || showAirs.lastEpisode == nil {
            tvdb.getNextEpisode(forSeries: showAirs.showID!) { result in
                print("GOT RESULTS!")
                if result != nil {
                    showAirs.lastSeason = result!["airedSeason"] as? Int
                    showAirs.lastEpisode = result!["airedEpisodeNumber"] as? Int
                    showAirs.airDate = result!["firstAired"] as? String
                    if showAirs.lastSeason != nil && showAirs.lastEpisode != nil && showAirs.airDate != nil {
                        print("\(showAirs.showID!): Got next Episode S\(showAirs.lastSeason!)E\(showAirs.lastEpisode!). Airs: \(showAirs.airDate!)")
                    } else {
                        print("got new info for \(String(describing: showAirs.showID))")
                    }
                    synced(lock: showAirs){
                        showAirs.lastChecked = Date()
                        self.delegate?.didUpdate()

                    }
                }
                else {
                    print("Could not get latest episode airdate")
                }
            }
        } else {
            tvdb.getNextEpisode(forSeries: showAirs.showID!, season: showAirs.lastSeason!, episode: showAirs.lastEpisode!) { episode in
                if episode == nil {
                    print("Could not get airdate for series \(String(describing: showAirs.showID)).")
                } else {
                    showAirs.lastSeason = episode!["airedSeason"] as? Int
                    showAirs.lastEpisode = episode!["airedEpisodeNumber"] as? Int
                    showAirs.airDate = episode!["firstAired"] as? String
                    if showAirs.lastSeason != nil && showAirs.lastEpisode != nil && showAirs.airDate != nil {
                        print("\(showAirs.showID!): Got next Episode S\(showAirs.lastSeason!)E\(showAirs.lastEpisode!). Airs: \(showAirs.airDate!)")
                    } else {
                        print("got new info for \(String(describing: showAirs.showID))")
                    }
                    synced(lock: showAirs){
                        showAirs.lastChecked = Date()
                        self.delegate?.didUpdate()
                    }
                }
            }
        }
    }
    
    @objc func checkForUpdates() {
        print("Checking for update...")
        synced(lock: self.shows){
            if self.authenticated == nil || self.authenticated! == false {
                print("Not Authenticated")
                return
            }
            for (k,showAirs) in self.shows {
                if showAirs.shouldCheckForAirDate() {
                    if showAirs.showID == nil {
                        print("Getting series \(k) id")
                        tvdb.getSeriesID(forName: k) { seriesID in
                            if seriesID == nil {
                                print("Could not get showID for show \(k)")
                            }
                            print("Got ShowID \(String(describing: seriesID))")
                            self.delegate?.didUpdate()
                            showAirs.showID = seriesID
                            self.getEpisodeAirDate(forShowAirs: showAirs)
                        }
                    }
                    print("Check for episode: \(k)")
                } else {
                    print("Not checking \(String(describing: showAirs.showID))")
                }
            }
        }
        self.delegate?.didUpdate()
    }
}

extension Date {
    func asYYYYMMDD() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self)
    }
}

class ShowAirs {
    var name: String = ""
    var airDate: String?
    var lastChecked: Date?
    var showID: Int?
    var lastSeason: Int?
    var lastEpisode: Int?
    var lastEpisodeID: String?
    var description: String?
    
    init(name: String) {
        self.name = name
    }
    
    func aired() -> Bool {
        return airDate != nil && airDate! < Date().asYYYYMMDD()
    }
    
    func airsToday() -> Bool {
        return airDate == Date().asYYYYMMDD()
    }
    
    func shouldCheckForAirDate() -> Bool {
        if airDate != nil && airDate! > Date().asYYYYMMDD() {
            return false
        }
        if lastChecked == nil {
            return true
        }
        return lastChecked!.addingTimeInterval(21600) < Date()
    }
    
}
