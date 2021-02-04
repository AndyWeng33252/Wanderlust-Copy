//
//  Post.swift
//  WanderlustApp
//
//  Created by Andy Weng on 10/22/20.
//

import UIKit

class Posts {
    var userName: String!
    var caption: String!
    var description: String!
    var imageList:[UIImage]!
    
    init(userName:String, caption: String, description:String, imageList:[UIImage]) {
        self.userName = userName
        self.caption = caption
        self.description = description
        self.imageList = imageList
    }
}
