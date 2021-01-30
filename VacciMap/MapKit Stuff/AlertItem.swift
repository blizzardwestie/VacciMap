//
//  AlertItem.swift
//  VacciMap
//
//  Created by Matthew Chertok on 1/29/21.
//

import SwiftUI

///Alerts that can be used throughout the app
class AlertItem: Identifiable, ObservableObject {
    static let sharedInstance = AlertItem(title: Text("Error"), secondaryOrDismissButton: Alert.Button.cancel())
    var id = UUID()
    var title: Text
    var message: Text?
    var optionalActionButton: Alert.Button?
    var secondaryOrDismissButton: Alert.Button
    
    var alert: AlertItem? {
        get {
            return alertContent
        }
        set {
            alertContent = newValue
        }
    }
    
    @Published var alertContent: AlertItem?
    
    init(title: Text, message: Text? = nil, optionalActionButton: Alert.Button? = nil, secondaryOrDismissButton: Alert.Button) {
        self.title = title
        self.message = message
        self.optionalActionButton = optionalActionButton
        self.secondaryOrDismissButton = secondaryOrDismissButton
    }
    
    func setAlert(content: AlertItem){
        self.alertContent = content
    }
}
