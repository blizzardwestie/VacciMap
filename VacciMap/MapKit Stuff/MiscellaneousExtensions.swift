//
//  MiscellaneousExtensions.swift
//  VacciMap
//
//  Created by Matthew Chertok on 1/29/21.
//

import Foundation
import SwiftUI
import MapKit

extension Array where Element == CodableMKPointAnnotation {
    mutating func deleteElement(_ element: Element?){
        guard let element = element else { return }
        for index in 0..<self.count {
            if index >= self.count { return } //check to avoid going out of range
            print("Attempting to delete location at index \(index)")
            if self[index].coordinate.latitude == element.coordinate.latitude && self[index].coordinate.longitude == element.coordinate.longitude {
                self.remove(at: index)
                print("Deleted location at index \(index)")
                return //exit once the element is removed
            }
        }
    }
    
    ///Determine whether a list of point annotations contains a given annotation.
    func containsLocation(location: Element) -> Bool {
        for item in self {
            if item.coordinate.latitude == location.coordinate.latitude && item.coordinate.longitude == location.coordinate.longitude {
                return true
            }
        }
        return false
    }
    
    ///Returns an array of point annotations with duplicate locations removed
     func duplicatedAnnotationsRemoved()->[Element]{
        var arrayToReturn = [Element]()
        for location in self {
            if !arrayToReturn.containsLocation(location: location) {
                arrayToReturn.append(location)
            }
        }
        return arrayToReturn
    }
    
    ///Remove duplicate location annotations
    mutating func removeDuplicateAnnotations(){
        self = self.duplicatedAnnotationsRemoved()
    }
}

extension MKAnnotation {
    ///Returns a unique identifier for each location based on its coordinates. The patter is latitude + single space + longitude
    func identifierString() -> String {
        let latitudeString = String(describing: self.coordinate.latitude)
        let longitudeString = String(describing: self.coordinate.longitude)
        return latitudeString + " " + longitudeString
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


///Returns the appropriate pin color based on whether the site is a testing or vaccination site and whether there are test/vaccines available. Available vaccines are bright green, available tests are dark green, unavailable vaccines are gray, and unavailable tests are dark gray.
public func pinColor(locationType: String, availability: String) -> UIColor {
    let isAvailable = availability == "true" ? true : false //convert the string to a boolean
    let darkGreen = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
    let lightGreen = UIColor(red: 0.4, green: 0.7, blue: 0.3, alpha: 1)
    switch locationType{
    case "Vaccination Site":
        if isAvailable { return darkGreen }
        else { return .gray }
    case "Testing Site":
        if isAvailable { return lightGreen }
        else { return .darkGray }
    default:
        return .systemRed
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
///Equal to the string "availability"; useful for storing values in the database
public var availabilityKey = "availability"
///Equal to the string "comments"; useful for storing values in the database
public var commentsKey = "comments"
