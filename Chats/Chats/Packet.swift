//
//  Message.swift
//  MPCRevisited
//
//  Created by Pavitra Rengarajan on 2/21/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import Foundation

class Packet: NSObject, NSCoding {
    
    required init(coder aDecoder: NSCoder) {
        self.sourcePhone = aDecoder.decodeObjectForKey("sourcePhone") as String
        self.destPhone = aDecoder.decodeObjectForKey("destPhone") as String
        self.msg = aDecoder.decodeObjectForKey("msg") as String
        self.path = aDecoder.decodeObjectForKey("path") as [AnyObject]
        self.dateString = aDecoder.decodeObjectForKey("dateString") as String
        
        //fatalError()
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(sourcePhone, forKey: "sourcePhone")
        aCoder.encodeObject(destPhone, forKey: "destPhone")
        aCoder.encodeObject(msg, forKey: "msg")
        aCoder.encodeObject(path, forKey: "path")
        aCoder.encodeObject(dateString, forKey: "dateString")
    }
    
    // assuming we get strings from front-end (can change this to NSInteger if we want)
    let sourcePhone: String
    let destPhone: String
    let msg: String
    
    let dateString: String
    let path: [AnyObject]
    
    init(sourcePhone: String, destPhone: String, msg: String, dateString: String) {
        
        self.sourcePhone = sourcePhone
        self.destPhone = destPhone
        self.msg = msg
        
        self.path = []
        self.dateString = dateString
        
    }
    
}