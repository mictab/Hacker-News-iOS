//
//  Networkcheck.swift
//  Hacker News
//
//  Created by Michel Tabari on 5/29/16.
//  Copyright © 2016 Michel Tabari. All rights reserved.
//

import Foundation

class Networkcheck {
    
    @objc func networkStatusChanged(notification: NSNotification) {
        let userInfo = notification.userInfo
        print(userInfo)
    }
    
    func networkIsDown() -> Bool {
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            return true
        default:
            return false
        }
    }
}

let NetworkCheck = Networkcheck()