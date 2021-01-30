//
//  PinColorsDictionary.swift
//  VacciMap
//
//  Created by Matthew Chertok on 1/30/21.
//  An observable dictionary that stores pin colors

import Foundation
import UIKit

///Contains a singleton instance which stores a dictionary of pin colors
class PinColorsDictionary: ObservableObject {
    static let shared = PinColorsDictionary()
    
    ///Map "SOME_LATITUDE SOME_LONGITUDE" to SOME_UI_COLOR
    @Published var dictionary = [String: UIColor]()
}
