//
//  BlogsDataClass.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 17/12/2024.
//

import Foundation

struct Blog: Identifiable, Decodable {
    let id: String
    let Title: String
    let image: String
    let Source: String
    let Author: String
    let Date: String
}

struct BlogResponse: Decodable {
    let Blogs: [Blog]
}

struct Detail: Decodable {
    let id: String
    let Title: String
    let image: String
    let Source: String
    let Author: String
    let Date: String
    let Link: String
    let para: String
}
