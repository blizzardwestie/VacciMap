//
//  MKPointAnnotation-ObservableObject.swift
//  VacciMap
//
//  Created by Matthew Chertok on 1/29/21.
//

import Foundation
import MapKit

extension MKPointAnnotation: ObservableObject {
    public var wrappedTitle: String {
        get {
            self.title ?? ""
        }

        set {
            title = newValue
        }
    }

    public var wrappedSubtitle: String {
        get {
            self.subtitle ?? ""
        }

        set {
            subtitle = newValue
        }
    }
    
    ///Use this to store the test/vaccine availability boolean as a string
    public var wrappedHint: String {
        get {
            self.accessibilityHint ?? ""
        }
        set {
            accessibilityHint = newValue
        }
    }
}
