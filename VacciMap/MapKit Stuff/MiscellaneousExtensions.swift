//
//  MiscellaneousExtensions.swift
//  VacciMap
//
//  Created by Matthew Chertok on 1/29/21.
//

import Foundation
import SwiftUI

extension Array where Element == CodableMKPointAnnotation {
    mutating func deleteElement(_ element: Element?){
        guard let element = element else { return }
        for index in 0..<self.count {
            if index >= self.count { return } //check to avoid going out of range
            let selectedPlace = self[index]
            let selectedLatitude =  round(Double(selectedPlace.coordinate.latitude)*1000)/1000
            let selectedLongitude = round(Double(selectedPlace.coordinate.longitude)*1000)/1000
            
            //Upload to database as a string "SOME_LATITUDE SOME_LONGITUDE", so latitude is string.first and longitude is string.last
            let selectedCoordinateString = "\(selectedLatitude) \(selectedLongitude)"
            //Identifies the site based on its location. Replace periods with underscores to make the key valid.
            let selectedSiteIdentifier = selectedCoordinateString.replacingOccurrences(of: ".", with: "_")
            
            let toDeletePlace = element
            let toDeleteLatitude =  round(Double(toDeletePlace.coordinate.latitude)*1000)/1000
            let toDeleteLongitude = round(Double(toDeletePlace.coordinate.longitude)*1000)/1000
            
            //Upload to database as a string "SOME_LATITUDE SOME_LONGITUDE", so latitude is string.first and longitude is string.last
            let toDeleteCoordString = "\(toDeleteLatitude) \(toDeleteLongitude)"
            //Identifies the site based on its location. Replace periods with underscores to make the key valid.
            let toDeleteSiteIdentifier = toDeleteCoordString.replacingOccurrences(of: ".", with: "_")
            
            
            if selectedSiteIdentifier == toDeleteSiteIdentifier {
                self.remove(at: index)
                return //exit once the element is removed
            }
        }
    }
}

extension String {
    ///Converts a String to a Text view
    func toText() -> Text {
        return Text(self)
    }
}

extension Int {
    ///Converts an integer to a string
    func toString() -> String {
        return String(describing: self)
    }
}

///Equal to the string "coordinates"; useful for storing values in the database
public var coordinatesKey = "coordinates"
///Equal to the string "is vaccination site"; useful for storing values in the database
public var isVaccinationSiteKey = "is vaccination site"
///Equal to the string "wait time"; useful for storing values in the database
public var waitTimeKey = "wait time"
///Equal to the string "site data"; useful for storing values in the database
public var siteDataKey = "site data"
///Equal to the string "comments"; useful for storing values in the database
public var commentsKey = "comments"
