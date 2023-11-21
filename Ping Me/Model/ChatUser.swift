//
//  ChatUser.swift
//  Ping Me
//
//  Created by anshul on 21/11/23.
//

import Foundation
struct ChatUser: Identifiable {
    var id: String { uid }
    let fname,uid, email, profileImageurl: String
   
    init(data: [String: Any]) {
        self.fname = data["First Name"] as? String ?? ""
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.profileImageurl = data["profileImageUrl"] as? String ?? "none"
    
    
    }
}
