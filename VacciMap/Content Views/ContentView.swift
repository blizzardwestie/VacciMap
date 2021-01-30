//
//  ContentView.swift
//  VacciMap
//
//  Created by Matthew Chertok on 1/29/21.
//

import SwiftUI
import MapKit
import FirebaseDatabase

struct ContentView: View {
    ///Tracks the center coordinate on the map
    @State private var centerCoordinate = CLLocationCoordinate2D()
    
    ///An array of locations to be passed to the map
    @State private var locations = [CodableMKPointAnnotation]()

    ///Stores the currently-selected place
    @State private var selectedPlace: MKPointAnnotation?
    
    ///Determines whether we are showing details for that place
    @State private var showingPlaceDetails = false
    
    ///Determine whether we are showing the screen to edit a location's details
    @State private var showingEditScreen = false
    
    ///Determine whether ot enable editing the site, or only viewing nearby attractions
    @State private var shouldEditSite = true

    ///Determines which alert to show
    @StateObject private var alertItem = AlertItem.sharedInstance

    var body: some View {
        ZStack {
            MapView(centerCoordinate: $centerCoordinate, selectedPlace: $selectedPlace, showingPlaceDetails: $showingPlaceDetails, annotations: locations)
                .edgesIgnoringSafeArea(.all)
            Image(systemName: "cross.circle")
                .opacity(0.3)
                .frame(width: 32, height: 32)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // create a new location
                        let newLocation = CodableMKPointAnnotation()
                        newLocation.coordinate = self.centerCoordinate
                        self.locations.append(newLocation)
                        newLocation.title = "Example location"

                        //show the edit screen when a new location is created
                        self.selectedPlace = newLocation
                        self.showingEditScreen = true

                    }) {
                        Image(systemName: "plus")
                            .padding()
                            .background(Color.black.opacity(0.75))
                            .foregroundColor(.white)
                            .font(.title)
                            .clipShape(Circle())
                            .padding(.trailing)
                    }
                }
            }
        }
        .actionSheet(isPresented: $showingPlaceDetails, content: {
            ActionSheet(title: Text("Location Options"), buttons: [
                .default(Text("Nearby Attractions")){ showingEditScreen = true; shouldEditSite = false },
                .default(Text("Edit Site")){ showingEditScreen = true; shouldEditSite = true },
                .destructive(Text("Delete Site")){
                    alertItem.alert = AlertItem(title: Text("Delete Location?"), optionalActionButton: .destructive(Text("Yes"), action: {
                        deleteLocation() //deletes the location from storage as well

                    }), secondaryOrDismissButton: .cancel())
                },
                .cancel()
            ])
        })
        
        .alert(item: $alertItem.alertContent, content: { content in
            if content.optionalActionButton != nil {
                return Alert(title: content.title, message: content.message, primaryButton: content.optionalActionButton!, secondaryButton: content.secondaryOrDismissButton)
            }
            else {
                return Alert(title: content.title, message: content.message, dismissButton: content.secondaryOrDismissButton)
            }
        })
        
        .sheet(isPresented: $showingEditScreen, onDismiss: { shouldEditSite = true }) {
            if self.selectedPlace != nil {
                EditView(placemark: self.selectedPlace!, shouldEditSite: shouldEditSite)
            }
            
        }.onAppear(perform: loadData)

    }
    
    ///Gets the documents directory from the iOS file system
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    ///Loads saved data from the file system
    func loadData() {
         /*let filename = getDocumentsDirectory().appendingPathComponent("SavedPlaces")

        do {
            let data = try Data(contentsOf: filename)
            locations = try JSONDecoder().decode([CodableMKPointAnnotation].self, from: data)
        } catch {
            print("Unable to load saved data.")
        } */
        
        let testingSitesRef = Database.database().reference().child("Testing Sites")
        let vaccinationSitesRef = Database.database().reference().child("Vaccination Sites")
        
        testingSitesRef.removeAllObservers() //avoid duplication
        vaccinationSitesRef.removeAllObservers()
        
        listenForDataAddedChangedRemoved(reference: testingSitesRef)
        listenForDataAddedChangedRemoved(reference: vaccinationSitesRef)

    }
    
    ///Saves a user's favorited locations to storage. Not currently used since I'm going with the database only.
    func saveData() {
        do {
            let filename = getDocumentsDirectory().appendingPathComponent("SavedPlaces")
            let data = try JSONEncoder().encode(self.locations)
            try data.write(to: filename, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Unable to save data.")
        }
    }
    
    ///Deletes a user's favorited location.
    func deleteLocation(){
       do {
            //delete the location from the active list
            locations.deleteElement(selectedPlace as? CodableMKPointAnnotation)
            
            //delete the entire saved places directory
            let filename = getDocumentsDirectory().appendingPathComponent("SavedPlaces")
            try FileManager.default.removeItem(at: filename)
            
            //saveData() //save the new list
        } catch {
            print("Unable to delete data.")
        }
        
        //Round latitude and longitude to the thousandth of a degree, since no two users will place the pin at exactly the same site.
        if selectedPlace == nil { return }
        let latitude =  round(Double(selectedPlace!.coordinate.latitude)*1000)/1000
        let longitude = round(Double(selectedPlace!.coordinate.longitude)*1000)/1000
        
        //Upload to database as a string "SOME_LATITUDE SOME_LONGITUDE", so latitude is string.first and longitude is string.last
        let coordinateString = "\(latitude) \(longitude)"
        //Identifies the site based on its location. Replace periods with underscores to make the key valid.
        let siteIdentifier = coordinateString.replacingOccurrences(of: ".", with: "_")
        
        //Delete the site from the database
        //Determine which database key to use, depending on if we have a vaccination or testing site
        let childToDelete = selectedPlace!.wrappedTitle == "Vaccination Site" ? "Vaccination Sites" : "Testing Sites"
        print("JOE BIDEN - child to delete is \(childToDelete), siteIdentifier is \(siteIdentifier), child key is \(siteDataKey)/\(coordinatesKey))")
        Database.database().reference().child(childToDelete).child(siteIdentifier).removeValue()
    }
    
    ///Call this when the view appears to observe both test and vaccination site data
    private func listenForDataAddedChangedRemoved(reference: DatabaseReference){
        observeDataAdded(reference: reference)
        observeDataChanged(reference: reference)
        observeDataRemoved(reference: reference)
    }
    
    ///Listens for data added. Never called separately.
    private func observeDataAdded(reference: DatabaseReference){
        reference.observe(.childAdded, with: { snapshot in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot {
                    if childSnapshot.key == siteDataKey {
                        if let value = childSnapshot.value as? [String: Any]{
                            let location = CodableMKPointAnnotation()
                            if let coordinates = value[coordinatesKey] as? String {
                                if let latitude = coordinates.split(separator: " ").first {
                                    if let latitude = Double(latitude) {
                                        location.coordinate.latitude = latitude
                                    }
                                }
                                if let longitude = coordinates.split(separator:" ").last {
                                    if let longitude = Double(longitude) {
                                        location.coordinate.longitude = longitude
                                    }
                                }
                            }
                            if let isVaccinationSite = value[isVaccinationSiteKey] as? Bool {
                                location.wrappedTitle = isVaccinationSite ? "Vaccination Site" : "Testing Site"
                            }
                            if let waitTime = value[waitTimeKey] as? String {
                                location.wrappedSubtitle = waitTime + " minute wait"
                                
                            }
                            
                            locations.append(location) //add to the list
                        }
                        
                        
                        break //stop the loop since we've found the right key
                    }
                }
            }
        })
    }
    ///Listens for data changed. Never called separately.
    private func observeDataChanged(reference: DatabaseReference){
        reference.observe(.childChanged, with: { snapshot in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot {
                    if childSnapshot.key == siteDataKey {
                        if let value = childSnapshot.value as? [String: Any]{
                            let location = CodableMKPointAnnotation()
                            if let coordinates = value[coordinatesKey] as? String {
                                if let latitude = coordinates.split(separator: " ").first {
                                    if let latitude = Double(latitude) {
                                        location.coordinate.latitude = latitude
                                    }
                                }
                                if let longitude = coordinates.split(separator:" ").last {
                                    if let longitude = Double(longitude) {
                                        location.coordinate.longitude = longitude
                                    }
                                }
                            }
                            if let isVaccinationSite = value[isVaccinationSiteKey] as? Bool {
                                location.wrappedTitle = isVaccinationSite ? "Vaccination Site" : "Testing Site"
                            }
                            if let waitTime = value[waitTimeKey] as? String {
                                location.wrappedSubtitle = waitTime + " minute wait"
                            }
                            
                            //delete the old value, then add the new one
                            locations.deleteElement(location)
                            locations.append(location)
                        }
                        
                        
                        break //stop the loop since we've found the right key
                    }
                }
            }
        })
    }
    
    ///Listens for data removed. Never called separately.
    private func observeDataRemoved(reference: DatabaseReference){
       reference.observe(.childRemoved){ snapshot in
           for child in snapshot.children {
               if let childSnapshot = child as? DataSnapshot {
                   if childSnapshot.key == siteDataKey {
                       if let value = childSnapshot.value as? [String: Any]{
                           let location = CodableMKPointAnnotation()
                           if let coordinates = value[coordinatesKey] as? String {
                               if let latitude = coordinates.split(separator: " ").first {
                                   if let latitude = Double(latitude) {
                                       location.coordinate.latitude = latitude
                                   }
                               }
                               if let longitude = coordinates.split(separator:" ").last {
                                   if let longitude = Double(longitude) {
                                       location.coordinate.longitude = longitude
                                   }
                               }
                           }
                           if let isVaccinationSite = value[isVaccinationSiteKey] as? Bool {
                               location.wrappedTitle = isVaccinationSite ? "Vaccination Site" : "Testing Site"
                           }
                           if let waitTime = value[waitTimeKey] as? String {
                                location.wrappedSubtitle = waitTime + " minute wait"
                            
                           }
                           
                        
                           locations.deleteElement(location) //delete the data
                       }
                       
                       break //stop the loop since we've found the right key
                   }
               }
           }
       }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
