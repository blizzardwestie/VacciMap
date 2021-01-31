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
    
    ///Do a refreshing dictionary to make this easier
    @State private var locationsDict: [String: CodableMKPointAnnotation] = [:] {
        willSet {
            locations = []
            newValue.forEach { coordinate, location in
                locations.append(location)
            }
        }
    }
    
    ///An array of locations to be passed to the map
    @State private var locations = [CodableMKPointAnnotation]()

    ///Stores the currently-selected place
    @State private var selectedPlace: MKPointAnnotation?
    
    ///Determine whether to show the sheet
    @State private var showingDisplaySheet = false
    
    ///Determine whether to show the action sheet
    @State private var showingActionSheet = false
    
    ///Determine which view to display in the sheet
    @State private var sheetType: SheetType = .viewComments
    

    ///Determines which alert to show
    @StateObject private var alertItem = AlertItem.sharedInstance
    
    ///Handles location services
    let locationManager = LocationManager()
    ///Determine when to show the map
    @State private var showMap = false
    
    ///Determine my location to center the map to
    @State private var coordinates: CLLocationCoordinate2D? = nil

    ///Equal to "tutorial"; used to see if I read the tutorial
    let tutorialKey = "tutorial"
    
    var body: some View {
        ZStack {
            if showMap {
                MapView(centerCoordinate: $centerCoordinate, selectedPlace: $selectedPlace, showingPlaceDetails: $showingActionSheet, currentLocation: coordinates, annotations: locations)
                    .edgesIgnoringSafeArea(.all)
                Image(systemName: "cross.circle")
                    .opacity(0.3)
                    .frame(width: 32, height: 32)
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // create a new location. It will be added when the details are added to the database
                            let newLocation = CodableMKPointAnnotation()
                            newLocation.coordinate = self.centerCoordinate

                            //show the edit screen when a new location is created
                            self.selectedPlace = newLocation
                            sheetType = .editSite
                            self.showingDisplaySheet = true
                            
                            //Append the new location, though this will be cleared momentarily once the database is updated.
                            locations.append(newLocation)

                        }) {
                            Image(systemName: "plus")
                                .padding()
                                .background(Color.black.opacity(0.75))
                                .foregroundColor(.white)
                                .font(.title)
                                .clipShape(Circle())
                                .padding(.trailing)
                                .padding(.bottom)
                        }
                    }
                }
            } //end if showMap
        } //end ZStack
        .onReceive(locationManager.$lastLocation, perform: { newVal in
            if let newCoordinate = newVal?.coordinate {
                if coordinates == nil { //only update the coordinates the first time, when they are nil
                    coordinates = newCoordinate
                    showMap = true
                }
            }
        })
        .actionSheet(isPresented: $showingActionSheet, content: {
            ActionSheet(title: Text("Location Options"), buttons: [
                .default(Text("Directions")){
                    if selectedPlace != nil {
                        openMapsAppWithDirections(to: selectedPlace!.coordinate, destinationName: selectedPlace!.wrappedTitle)
                    }
                    
                },
                .default(Text("View Comments")){ showingDisplaySheet = true; sheetType = .viewComments },
                .default(Text("Edit Details/Add Comment")){ showingDisplaySheet = true; sheetType = .editSite },
                .default(Text("Nearby Attractions")){ showingDisplaySheet = true; sheetType = .nearbyAttractions },
                .destructive(Text("Delete Site")){
                    alertItem.alert = AlertItem(title: Text("Delete Location?"), optionalActionButton: .destructive(Text("Yes"), action: {
                        deleteLocation() //deletes the location from the database

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
        
        .sheet(isPresented: $showingDisplaySheet, onDismiss: {
            if sheetType == .tutorial {
                UserDefaults.standard.set(true, forKey: tutorialKey) //mark that I read the tutorial so I don't show it again
            }
            loadData() //reset the data
        }) {
            if sheetType == .editSite {
                if self.selectedPlace != nil {
                    EditView(placemark: self.selectedPlace!, shouldEditSite: true)
                }
            }
            else if sheetType == .viewComments {
                if self.selectedPlace != nil {
                    CommentsView(isTestingSite: selectedPlace!.wrappedTitle == "Testing Site", siteID: selectedPlace!.identifierString().replacingOccurrences(of: ".", with: "_"))
                }
            }
            else if sheetType == .nearbyAttractions {
                if self.selectedPlace != nil {
                    EditView(placemark: self.selectedPlace!, shouldEditSite: false)
                }
            }
            else if sheetType == .tutorial {
                Tutorial()
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
        locationsDict = [:]
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
        //observeValueChanged(reference: testingSitesRef)
        //observeValueChanged(reference: vaccinationSitesRef)
        
        let didReadTutorial = UserDefaults.standard.bool(forKey: tutorialKey)
        if !didReadTutorial { //show the tutorial the first time the app opens
            sheetType = .tutorial
            showingDisplaySheet = true
        }

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
      /* do { //don't need to worry about data saved on the device, since I'm only using the database
            //delete the location from the active list
            locations.deleteElement(selectedPlace as? CodableMKPointAnnotation)
            
            //delete the entire saved places directory
            let filename = getDocumentsDirectory().appendingPathComponent("SavedPlaces")
            try FileManager.default.removeItem(at: filename)
            
            //saveData() //save the new list
        } catch {
            print("Unable to delete data.")
        } */
        
        //Round latitude and longitude to the thousandth of a degree, since no two users will place the pin at exactly the same site.
        if selectedPlace == nil { return }
        let latitude =  Double(selectedPlace!.coordinate.latitude)
        let longitude = Double(selectedPlace!.coordinate.longitude)
        
        //Upload to database as a string "SOME_LATITUDE SOME_LONGITUDE", so latitude is string.first and longitude is string.last
        let coordinateString = "\(latitude) \(longitude)"
        //Identifies the site based on its location. Replace periods with underscores to make the key valid.
        let siteIdentifier = coordinateString.replacingOccurrences(of: ".", with: "_")
        
        //Delete the site from the database
        //Determine which database key to use, depending on if we have a vaccination or testing site
        let childToDelete = selectedPlace!.wrappedTitle == "Vaccination Site" || selectedPlace!.wrappedTitle == "No Vaccines Available" ? "Vaccination Sites" : "Testing Sites"
        Database.database().reference().child(childToDelete).child(siteIdentifier).removeValue()
    }
    
    ///Call this when the view appears to observe both test and vaccination site data. I can't use this right now though because it has issues.
    private func listenForDataAddedChangedRemoved(reference: DatabaseReference){
        observeDataAdded(reference: reference)
        observeDataChanged(reference: reference)
        observeDataRemoved(reference: reference)
    }
    
    
    ///Value listener isn't ideal compared to child listener, but at least this works.
    private func observeValueChanged(reference: DatabaseReference){
        reference.observe(.value){ snapshot in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot {
                    childSnapshot.ref.child(siteDataKey).observeSingleEvent(of: .value){ siteDataSnapshot in
                        if let value = siteDataSnapshot.value as? [String: Any]{
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
                                location.wrappedSubtitle = !waitTime.isEmpty ? waitTime + " minute wait" : "Unknown wait time"
                                
                            }
                            
                            //Don't forget to convert back to a boolean when setting the pin color
                            if let testAvailable = value[availabilityKey] as? Bool {
                                location.wrappedHint = testAvailable ? "true" : "false"
                            }
                            
                            //Change the title if there are no doses or tests available
                            if location.wrappedHint == "false" {
                                location.wrappedTitle = location.wrappedTitle == "Testing Site" ? "No Tests Available" : "No Vaccines Available"
                            }
                            
                            //update my locations
                            if let coordinates = value[coordinatesKey] as? String { locationsDict[coordinates] = location }
                            PinColorsDictionary.shared.dictionary[location.identifierString()] = pinColor(locationType: location.wrappedTitle, availability: location.wrappedHint)
                            print("Location added at \(location.coordinate)")
                    }
                }
            }
        }
    }
    }
    
    ///Listens for data added. Never called separately.
    private func observeDataAdded(reference: DatabaseReference){
        reference.observe(.childAdded, with: { snapshot in
            snapshot.ref.child(siteDataKey).observeSingleEvent(of: .value){ childSnapshot in
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
                        location.wrappedSubtitle = !waitTime.isEmpty ? waitTime + " minute wait" : "Unknown wait time"
                        
                    }
                    
                    //Don't forget to convert back to a boolean when setting the pin color
                    if let testAvailable = value[availabilityKey] as? Bool {
                        location.wrappedHint = testAvailable ? "true" : "false"
                    }
                    
                    //Change the title if there are no doses or tests available
                    if location.wrappedHint == "false" {
                        location.wrappedTitle = location.wrappedTitle == "Testing Site" ? "No Tests Available" : "No Vaccines Available"
                    }
                    
                    //update my locations
                    if let coordinates = value[coordinatesKey] as? String { locationsDict[coordinates] = location }
                    PinColorsDictionary.shared.dictionary[location.identifierString()] = pinColor(locationType: location.wrappedTitle, availability: location.wrappedHint)
                    print("Location added at \(location.coordinate)")
                
                }
                
            }
        })
    }
    ///Listens for data changed. Never called separately.
    private func observeDataChanged(reference: DatabaseReference){
        reference.observe(.childChanged, with: { snapshot in
            snapshot.ref.child(siteDataKey).observeSingleEvent(of: .value){ childSnapshot in
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
                        location.wrappedSubtitle = !waitTime.isEmpty ? waitTime + " minute wait" : "Unknown wait time"
                        
                    }
                    
                    //Don't forget to convert back to a boolean when setting the pin color
                    if let testAvailable = value[availabilityKey] as? Bool {
                        location.wrappedHint = testAvailable ? "true" : "false"
                    }
                    
                    //Change the title if there are no doses or tests available
                    if location.wrappedHint == "false" {
                        location.wrappedTitle = location.wrappedTitle == "Testing Site" ? "No Tests Available" : "No Vaccines Available"
                    }
                    
                    //update my locations
                    if let coordinates = value[coordinatesKey] as? String { locationsDict[coordinates] = location }
                    PinColorsDictionary.shared.dictionary[location.identifierString()] = pinColor(locationType: location.wrappedTitle, availability: location.wrappedHint)
                    print("Location added at \(location.coordinate)")
                
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
                            location.wrappedSubtitle = !waitTime.isEmpty ? waitTime + " minute wait" : "Unknown wait time"

                           }

                            //Don't forget to convert back to a boolean when setting the pin color
                            if let testAvailable = value[availabilityKey] as? Bool {
                                location.wrappedHint = testAvailable ? "true" : "false"
                            }
                        
                            //Change the title if there are no doses or tests available
                            if location.wrappedHint == "false" {
                                location.wrappedTitle = location.wrappedTitle == "Testing Site" ? "No Tests Available" : "No Vaccines Available"
                            }
                        
                            print("Trying to delete location at \(location.coordinate)")
                            PinColorsDictionary.shared.dictionary.removeValue(forKey: location.identifierString())
                            if let coordinates = value[coordinatesKey] as? String { locationsDict.removeValue(forKey: coordinates) }
                       }
                       
                       break //stop the loop since we've found the right key
                   }
               }
           }
       }
    }
    
    ///Opens a location in Apple Maps
    func openMapsAppWithDirections(to coordinate: CLLocationCoordinate2D, destinationName name: String) {
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name // Provide the name of the destination in the To: field
        mapItem.openInMaps(launchOptions: options)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

///An enum containing views that the sheet might display
enum SheetType {
    case editSite, viewComments, nearbyAttractions, tutorial
}
