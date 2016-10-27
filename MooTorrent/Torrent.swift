//
//  eztv.swift
//  MooTorrent
//
//  Created by mnapolit on 10/11/16.
//  Copyright © 2016 Micmoo. All rights reserved.
//

import Foundation
import AEXML

enum Day : Int {
    case Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday
}

protocol ShowSite {
    func syncShows()
    var delegate: ShowSiteDelegate? { get set }
    var url: String { get set }
}

protocol ShowSiteDelegate {
    func gotNewShows(shows: Dictionary<String, Set<Show>>)
    
}

// TODO: Syncronize self.shows
class EZTV : ShowSite, ShowSiteDelegate{

    var url: String = "http://eztv.ag/ezrss.xml"
    var rssURL: URL
    var shows: Dictionary<String, Set<Show>> = Dictionary()
    var delegate: ShowSiteDelegate?
    var urlSession: URLSession!

    
    
    init() {
        let conf = URLSessionConfiguration.default
        conf.urlCache = nil
        conf.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
        urlSession = URLSession(configuration: conf)
        rssURL = URL(string: url)!
    }
    
    
    init(url: String){
        let conf = URLSessionConfiguration.default
        conf.urlCache = nil
        conf.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
        urlSession = URLSession(configuration: conf)
        self.url = url
        rssURL = URL(string: url)!
    }
    
    func gotNewShows(shows: Dictionary<String, Set<Show>>){
        print(shows.description)
    }
    
    func syncShows() {
        if delegate == nil {
            delegate = self
        }
        
        
        let task = urlSession.dataTask(with: rssURL){(data, response, error) -> Void in
            if error != nil {
                print(error)
                return
            }
            
            if let data = data {
                do {
                    let xmlDoc = try AEXMLDocument(xml: data, options: AEXMLOptions.init())

                    let backgroundQueue = DispatchQueue(label: "org.micmoo.syncShows",
                                                        qos: .background,
                                                        target: nil)

                    backgroundQueue.sync(execute: { () -> Void in
                        var replaceShows: Dictionary<String, Set<Show>> = Dictionary()
                        
                        for show in xmlDoc.root["channel"]["item"].all! {
                            if show["torrent:magnetURI"].value == nil {
                                print("No Magnet Link. Continuing")
                                continue
                            }
                            let parsedShow = self.showFromTitle(title: show["title"].value!, magnet: show["torrent:magnetURI"].value, size: Int(show["torrent:contentLength"].value!)!)
                            
                            if parsedShow == nil {
                                continue
                            }
                            if replaceShows[parsedShow!.name] == nil {
                                replaceShows[parsedShow!.name] = Set()
                            }
                            replaceShows[parsedShow!.name]!.insert(parsedShow!)
                        }
                        if replaceShows.count > 0 {
                            self.delegate?.gotNewShows(shows: replaceShows)
                            self.shows.removeAll(keepingCapacity: false)
                            self.shows = replaceShows
                        }
                        
                    })
                    
                }
                catch let error as NSError {
                    print(error)
                }
            } else if let error = error {
                print(error)
            }
        }
        
        task.resume()
        urlSession.flush{print("Flushed!")}
        
        
    }
    
    func showFromTitle(title: String, magnet: String?, size: Int) -> Show?{
        let re: NSRegularExpression
        do {
            re = try NSRegularExpression(pattern: "([A-Za-z0-9. -]+) (S[0-9]+E[0-9]+|20[0-9][0-9] [0-9][0-9] [0-9][0-9]) (.*)")
        } catch {
            print("Nope!")
            return nil
        }
        let t = title as NSString
        let matches = re.matches(in: title, range: NSRange(location: 0, length: t.length))
        var collectMatches: Array<String> = []
        for match in matches {
            for n in 1..<match.numberOfRanges {
                let substring = t.substring(with: match.rangeAt(n))
                collectMatches.append(substring)
            }
        }
        if collectMatches.count < 2 {
            print("Skipping, \(title)")
            return nil
        }
        
        let show =  Show(name: collectMatches[0].capitalized, episode: collectMatches[1], magnet: URL.init(string: magnet!)!, size: size)
        if collectMatches.count == 3 {
            show.keyword = collectMatches[2]
        }
        return show

    }
    
}
class Show: NSObject, NSCoding, NSCopying{
    dynamic var name: String
    var episode: String
    var magnet: URL?
    dynamic var keyword: String?
    var size: Int?
    
    override var hashValue: Int {
        var hash = 5381;
        var c : Int = 0
        c += name.unicodeValue()
        c += episode.unicodeValue()
        if magnet != nil {
            c += magnet!.absoluteString.unicodeValue()
        }
        if keyword != nil {
            c += keyword!.unicodeValue()
        }
        if size != nil {
            c += size!
        }
        
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
        return hash;

    }
    
    override var hash: Int {
        return hashValue
    }
    
    override func copy() -> Any {
        let copy = Show(name: name, episode: episode, magnet: magnet, size: size)
        copy.keyword = keyword
        return copy
    }

    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Show(name: name, episode: episode, magnet: magnet, size: size)
        copy.keyword = keyword
        return copy
    }

    
    
    override  func isEqual(_ object: Any?) -> Bool {
        if let rhs = object as? Show {
            return self.hashValue == rhs.hashValue
        }
        return false
    }
    
    override var description: String {
        return "\(name) \(episode) \(size)"
    }
    
    override init() {
        self.name = ""
        self.episode = "S00E00"
        super.init()
    }

    init(name: String, episode: String) {
        self.name = name
        self.episode = episode

        super.init()
    }
    
    init(name:String){
        self.name = name
        self.episode = "S00E00"

        super.init()
    }
    
    
    init(name: String, episode: String, magnet: URL?, size: Int?){
        self.name = name
        self.episode = episode
        self.magnet = magnet
        self.size = size

        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        if let name = aDecoder.decodeObject(forKey: "name") as? String {
            self.name = name
        } else {
            self.name = ""
        }
        if let episode = aDecoder.decodeObject(forKey: "episode") as? String {
            self.episode = episode
        } else {
            self.episode = ""
        }
        if let keyword = aDecoder.decodeObject(forKey: "keyword") as? String {
            self.keyword = keyword
        }
        
        if let size = aDecoder.decodeObject(forKey: "size") as? Int  {
            self.size = size
        }

        if let url = aDecoder.decodeObject(forKey:"magnet") as? URL {
            self.magnet = url
        }

        
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: "name")
        aCoder.encode(self.episode, forKey: "episode")
        if let size = self.size {
            aCoder.encode(size, forKey: "size")

        }
        if let url = self.magnet {
            aCoder.encode(url, forKey: "magnet")
        }
        if let keyword = self.keyword {
            aCoder.encode(keyword, forKey: "keyword")
        }

    }

    
    func isMax() -> Bool {
        return self.episode == "S00E00" && self.size == nil
    }
    
    deinit {
        //print("DEINIT: \(name) \(episode) \(size)")
        // perform the deinitialization
    }
}

func ==(lhs: Show, rhs: Show) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

extension String {
    func unicodeValue() -> Int {
        var c: Int = 0
        for s in self.unicodeScalars {
            c += Int(s.value)
        }
        return c
    }
}

func synced(lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}




