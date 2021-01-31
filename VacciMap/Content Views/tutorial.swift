//
//  tutorial.swift
//  VacciMap
//
//  Created by Matthew Chertok on 1/30/21.
//

import SwiftUI
import WhatsNewKit

struct Tutorial: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> WhatsNewViewController {
        
        var configuration = WhatsNewViewController.Configuration(theme: .blue)
    
        configuration.itemsView.titleFont = .systemFont(ofSize: 16, weight: .semibold)
        configuration.itemsView.subtitleFont = .systemFont(ofSize: 15)
        configuration.titleView.animation = .slideRight
        configuration.itemsView.animation = .slideRight
        configuration.completionButton.animation = .slideUp
        
        let whatsNew = WhatsNew(title: "Welcome to VacciMap", items: [
            WhatsNew.Item(title: "Looking For A Vaccine?", subtitle: "VacciMap crowd-sources testing and vaccination sites in your area, as well as wait times and availability.", image: UIImage(systemName: "hand.point.right")),
            WhatsNew.Item(title: "Vaccines Available", subtitle: "Look for a green pin", image: UIImage(systemName: "hand.point.right")),
            WhatsNew.Item(title: "Testing Available", subtitle: "Look for a teal pin", image: UIImage(systemName: "hand.point.right")),
            WhatsNew.Item(title: "Out of Doses", subtitle: "Sites that have run out of vaccine doses will appear dark gray", image: UIImage(systemName: "hand.point.right")),
            WhatsNew.Item(title: "Out of Tests", subtitle: "Sites that have run out of tests will appear gray", image: UIImage(systemName: "hand.point.right")),
        ])
        
        //initialize WhatsNewViewController with the above settings
        let whatNewViewController = WhatsNewViewController(whatsNew: whatsNew, configuration: configuration)
        
        return whatNewViewController
    }
    
    func updateUIViewController(_ uiViewController: WhatsNewViewController, context: Context) {
        //don't do anything here
    }
    
    typealias UIViewControllerType = WhatsNewViewController
    
    
}


