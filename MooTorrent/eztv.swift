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



class EZTV{

    var url: String = "http://eztv.ag/ezrss.xml"
    var rssURL: URL
    var shows: Dictionary<String, Set<Show>> = Dictionary()
    
    init() {
        rssURL = URL(string: url)!
        fetchShows()

    }
    
    init(url: String){
        self.url = url
        rssURL = URL(string: url)!
        fetchShows()
    }
    
    func fetchShows() {
        guard let
            data = try? Data(contentsOf: rssURL)
        else {return}
        do {
            
            let xmlDoc = try AEXMLDocument(xml: data, options: AEXMLOptions.init())
            for show in xmlDoc.root["channel"]["item"].all! {
                if show["torrent:magnetURI"].value == nil {
                    print("No Magnet Link. Continuing")
                    continue
                }
                let parsedShow = showFromTitle(title: show["title"].value!, magnet: show["torrent:magnetURI"].value, size: Int(show["torrent:contentLength"].value!)!)
                if parsedShow == nil {
                    print("Continuing")
                    continue
                }

                if shows[parsedShow!.name] == nil {
                    shows[parsedShow!.name] = Set()
                }
                print("\(parsedShow!.description) \(parsedShow!.hashValue)")
                shows[parsedShow!.name]!.insert(parsedShow!)
            }
        }
        catch {
            print("error")
            
        }
    }
    
    func downloadShow(name: String) -> Show?{
        let firstVersion: Show? = shows[name]?.first
        if firstVersion == nil {
            print ("Cannot Find Show")
            return nil
        }
        if NSWorkspace.shared().open(firstVersion!.magnet) {
            return firstVersion
        }
        return nil
    }
    
    func showFromTitle(title: String, magnet: String?, size: Int) -> Show?{
        let re: NSRegularExpression
        do {
            re = try NSRegularExpression(pattern: "([A-Za-z0-9. -]+) (S[0-9]+E[0-9]+).*? ([pPINTERNAL0-9 ]*HDTV.*)")
        } catch {
            print("Nope!")
            return nil
        }
        let t = title as NSString
        let matches = re.matches(in: title, range: NSRange(location: 0, length: t.length))
        var collectMatches: Array<String> = []
        for match in matches {
            // range at index 0: full match
            // range at index 1: first capture group
            for n in 1..<match.numberOfRanges {
                let substring = t.substring(with: match.rangeAt(n))
                collectMatches.append(substring)
            }
        }
        if collectMatches.count < 3 {
            return nil
        }
        
        return Show(name: collectMatches[0], episode: collectMatches[1], quality: collectMatches[2], magnet: URL.init(string: magnet!)!, size: size)

    }
    
}

class Show: Equatable,Hashable {
    var name: String
    var episode: String
    var magnet: URL
    var quality: String
    var size: Int

    
    var hashValue: Int {
        var hash = 5381;
        var c : Int = 0
        c += name.unicodeValue()
        c += episode.unicodeValue()
        c += magnet.absoluteString.unicodeValue()
        c += quality.unicodeValue()
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
        return hash;

    }
    
    var description: String {
        return "\(name) \(episode) \(quality) \(size)"
    }

    
    init(name: String, episode: String, quality: String, magnet: URL, size: Int){
        self.name = name
        self.episode = episode
        self.magnet = magnet
        self.quality = quality
        self.size = size
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



