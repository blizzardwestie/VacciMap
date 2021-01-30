//
//  Results.swift
//  VacciMap
//
//  Created by Matthew Chertok on 1/29/21.
//  Codables to fetch data from Wikipedia

import Foundation

struct Result: Codable {
    let query: Query
}

struct Query: Codable {
    let pages: [Int: Page]
}

struct Page: Codable, Comparable {
    let pageid: Int
    let title: String
    let terms: [String: [String]]?
    
    // Define a compare function
    static func < (lhs: Page, rhs: Page) -> Bool {
        lhs.title < rhs.title
    }
    
    //Get the description, if it exists
    var description: String {
        terms?["description"]?.first ?? "No further information"
    }
}
