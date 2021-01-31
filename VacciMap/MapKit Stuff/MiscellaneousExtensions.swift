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
    private func elementDeleted(_ element: Element?) -> [Element]{
        guard let element = element else { return self}
        var arrayToReturn = [Element]()
        for item in self {
            //if the element isn't already in the arrayt to return, and the element is not the one we want to remove
            if !arrayToReturn.containsLocation(location: item) && !(item.coordinate.latitude == element.coordinate.latitude && item.coordinate.longitude == element.coordinate.longitude) {
                arrayToReturn.append(item)
            }
        }
        return arrayToReturn
    }
    
    ///Delete all elements at a specified coordinate
    mutating func deleteElement(_ element: Element?){
        self = self.elementDeleted(element)
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


///Returns the appropriate pin color based on whether the site is a testing or vaccination site and whether there are test/vaccines available. Available vaccines are green, available tests are teal, unavailable vaccines are dark gray, and unavailable tests are light gray.
public func pinColor(locationType: String, availability: String) -> UIColor {
    switch locationType{
    case "Vaccination Site":
        return .systemGreen
    case "No Vaccines Available":
        return .systemGray3
    case "Testing Site":
        return .systemTeal
    case "No Tests Available":
        return .systemGray
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
