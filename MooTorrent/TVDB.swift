//
//  TVDB.swift
//  MooTorrent
//
//  Created by mnapolit on 10/26/16.
//  Copyright © 2016 Micmoo. All rights reserved.
//

import Foundation
import Alamofire
import Alamofire_Synchronous


class TVDB {
    var username: String
    var userKey: String
    var apiKey: String
    let url: String = "https://api.thetvdb.com"
    var jwtoken: String?
    
    var authHeader: HTTPHeaders? {
        if jwtoken == nil {
            return nil
        }
        return ["Authorization" : "Bearer \(jwtoken!)", "Accept": "application/json"]
    }

    
    init(apiKey: String, userKey: String, username: String){
        self.username = username
        self.userKey = userKey
        self.apiKey = apiKey
    }
    
    func authenticate(completion: @escaping (Bool) -> Void){
        let parameters: Parameters = [
            "apikey": apiKey,
            "username": username,
            "userkey": userKey
        ]
        Alamofire.request("\(url)/login", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            var success = false
            if let json = response.result.value as? NSDictionary{
                self.jwtoken = json["token"] as? String
                success = true
            }
            completion(success)
            
        }
    }
    
    func getSeriesID(forName: String, completion: @escaping (Int?) -> Void){
        let parameters: Parameters = [
            "name": forName
        ]
        Alamofire.request("\(url)/search/series", method: .get, parameters: parameters,headers: authHeader).responseJSON { response in
            var smallestDistance: Int = Int.max
            var bestMatch: Int?
            if let json = response.result.value as? NSDictionary{
                if let shows = json["data"] as? NSArray {
                    for s in shows {
                        if let show = s as? NSDictionary {
                            if let seriesName = show["seriesName"] as? String{
                                let sd = Levenshtein.distanceBetween(seriesName, forName)
                                if  sd < smallestDistance {
                                    bestMatch = show["id"] as? Int
                                    smallestDistance = sd
                                }
                            }
                        }
                    }
                }
            }
        completion(bestMatch)
        }
    }

    
    func getNextEpisode(forSeries series: Int, season: Int, episode: Int, completion: @escaping (NSDictionary?) -> Void) {
        let parameters: Parameters = [
            "airedSeason": String(season),
            "airedEpisode": String(episode)
        ]
        Alamofire.request("\(url)/series/\(series)/episodes/query", method: .get, parameters: parameters, headers: authHeader).responseJSON { response in
            var episodeN = episode
            var seasonN = season
            var responseObj = response
            if response.response?.statusCode == 404 {
                let parameters2: Parameters = [
                    "airedSeason": String(seasonN),
                    "airedEpisode": String(episodeN)
                ]
                episodeN = 1
                seasonN += 1
                let response2 = Alamofire.request("\(self.url)/series/\(series)/episodes/query", method: .get, parameters: parameters2, headers: self.authHeader).responseJSON()
                if response2.response?.statusCode == 404 {
                    return
                }
                responseObj = response2
            }
            if let json = responseObj.result.value as? NSDictionary{
                print("Got next episode: inTBDB.SWIFT")
                print(json)
                completion(json)
            }
        }
        
    }
    
    func getNextEpisode(forSeries series: Int, completion: @escaping (NSDictionary?) -> Void){
        Alamofire.request("\(url)/series/\(series)/episodes", headers: authHeader).responseJSON { response in
            var latestEpisode: NSDictionary?
            if let json = response.result.value as? NSDictionary{
                var soonestDate: String = "2999-12-31"
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"

                if let episodes = json["data"] as? NSArray {
                    for e in episodes {
                        if let episode = e as? NSDictionary {
                            if episode["airedSeason"] == nil || episode["airedEpisodeNumber"] == nil || episode["firstAired"] == nil{
                                continue
                            }
                            let firstAired = episode["firstAired"] as! String
                            
                            if firstAired < dateFormatter.string(from: Date()) {
                                continue
                            }
                            
                            if firstAired < soonestDate {
                                soonestDate = firstAired
                                latestEpisode = episode
                            }
                        }
                    }
                }
            }
            completion(latestEpisode)
        }
    }
}

/**
 * Levenshtein edit distance calculator
 *
 * Inspired by https://gist.github.com/bgreenlee/52d93a1d8fa1b8c1f38b
 * Improved with http://stackoverflow.com/questions/26990394/slow-swift-arrays-and-strings-performance
 */

class Levenshtein {
    
    private class func min(_ numbers: Int...) -> Int {
        return numbers.reduce(numbers[0], {$0 < $1 ? $0 : $1})
    }
    
    class Array2D {
        var cols:Int, rows:Int
        var matrix: [Int]
        
        
        init(cols:Int, rows:Int) {
            self.cols = cols
            self.rows = rows
            matrix = Array(repeating:0, count:cols*rows)
        }
        
        subscript(col:Int, row:Int) -> Int {
            get {
                return matrix[cols * row + col]
            }
            set {
                matrix[cols*row+col] = newValue
            }
        }
        
        func colCount() -> Int {
            return self.cols
        }
        
        func rowCount() -> Int {
            return self.rows
        }
    }
    
    class func distanceBetween(_ aStr: String, _ bStr: String) -> Int {
        let a = Array(aStr.utf16)
        let b = Array(bStr.utf16)
        
        let dist = Array2D(cols: a.count + 1, rows: b.count + 1)
        
        for i in 1...a.count {
            dist[i, 0] = i
        }
        
        for j in 1...b.count {
            dist[0, j] = j
        }
        
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i-1] == b[j-1] {
                    dist[i, j] = dist[i-1, j-1]  // noop
                } else {
                    dist[i, j] = min(
                        dist[i-1, j] + 1,  // deletion
                        dist[i, j-1] + 1,  // insertion
                        dist[i-1, j-1] + 1  // substitution
                    )
                }
            }
        }
        
        return dist[a.count, b.count]
    }
}
