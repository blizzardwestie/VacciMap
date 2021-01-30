//
//  VacciMapApp.swift
//  VacciMap
//
//  Created by Matthew Chertok on 1/29/21.
//

import SwiftUI
import Firebase

@main
struct VacciMapApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
