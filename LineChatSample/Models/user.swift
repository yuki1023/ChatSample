//
//  user.swift
//  LineChatSample
//
//  Created by 樋口裕貴 on 2021/05/03.
//

import UIKit
import Firebase

class User {

    let email: String
        let username: String
        let createdAt: Timestamp
        let profileImageUrl: String
        
        var uid: String?
        
        init(dic: [String: Any]) {
            self.email = dic["email"] as? String ?? ""
            self.username = dic["username"] as? String ?? ""
            self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
            self.profileImageUrl = dic["profileImageUrl"] as? String ?? ""
        }
    
}
