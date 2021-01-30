//
//  MapKit Delegates and Stuff.swift
//  VacciMap
//
//  Created by Matthew Chertok on 1/29/21.
//

import Foundation
import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    typealias Context = UIViewRepresentableContext<Self>

    @Binding var centerCoordinate: CLLocationCoordinate2D
    
    ///Stores the currently-selected place
    @Binding var selectedPlace: MKPointAnnotation?
    
    ///Determines whether we are showing details for that place
    @Binding var showingPlaceDetails: Bool
    
    ///A list of all locations of interest
    var annotations: [MKPointAnnotation]

    func makeUIView(context: UIViewRepresentableContext<MapView>) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        let annotation = MKPointAnnotation()
            annotation.title = "London"
            annotation.subtitle = "Capital of England"
            annotation.coordinate = CLLocationCoordinate2D(latitude: 51.5, longitude: 0.13)
            mapView.addAnnotation(annotation)

        return mapView
    }

    func updateUIView(_ view: MKMapView, context: UIViewRepresentableContext<MapView>) {
        //check whether the two arrays contain the same number of items, and if they don’t remove all existing annotations and add them again.
        if annotations.count != view.annotations.count {
            view.removeAnnotations(view.annotations)
            view.addAnnotations(annotations)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

class Coordinator: NSObject, MKMapViewDelegate {
    var parent: MapView

    init(_ parent: MapView) {
        self.parent = parent
    }
    
    ///Will be called whenever the map view changes its visible region, which means when it moves, zooms, or rotates
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        //update the center coordinate
        parent.centerCoordinate = mapView.centerCoordinate
        print(mapView.centerCoordinate)
    }
    
    ///Animation when pin is tapped
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // this is our unique identifier for view reuse
           let identifier = "Placemark"

           // attempt to find a cell we can recycle
           var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

           if annotationView == nil {
               // we didn't find one; make a new one
               annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)

               // allow this to show pop up information
               annotationView?.canShowCallout = true

               // attach an information button to the view
               annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
           } else {
               // we have a view to reuse, so give it the new annotation
               annotationView?.annotation = annotation
           }

           // whether it's a new view or a recycled one, send it back
           return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let placemark = view.annotation as? MKPointAnnotation else { return }

        parent.selectedPlace = placemark
        parent.showingPlaceDetails = true
    }
}



///A placeholder pin for MapView to satisfy the binding variable
extension MKPointAnnotation {
    static var example: MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.title = "London"
        annotation.subtitle = "Home to the 2012 Summer Olympics."
        annotation.coordinate = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.13)
        return annotation
    }
}
