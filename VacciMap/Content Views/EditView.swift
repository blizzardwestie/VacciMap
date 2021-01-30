//
//  EditView.swift
//  VacciMap
//
//  Created by Matthew Chertok on 1/29/21.
//

import SwiftUI
import MapKit
import FirebaseDatabase

struct EditView: View {
    @Environment(\.presentationMode) var presentationMode
    
    ///This is what gets displayed when the location is tapped
    @ObservedObject var placemark: MKPointAnnotation
    
    ///Set this to false if I only want to view nearby attractions
    var shouldEditSite: Bool
    
    ///Set to true if the site is a vaccination site, not a testing site
    @State private var isVaccinationSite = false
    
    ///Text to display whether this is a testing or vaccination site. Set to either "Testing Site" or "Vaccination Site"
    @State private var siteType = "Testing Site (tap to change)"
    
    ///Set to false if there are no vaccines or tests available
    @State private var stuffAvailable = true
    
    @State private var locationType = ""
    
    ///The wait time at the location
    @State private var locationWaitTime = ""
    
    ///Additional comments regarding the test site
    @State private var additionalComments = ""
    
    ///Represents whether data from Wikipedia is loading, loaded, or whether loading failed
    @State private var loadingState = LoadingState.loading
    ///Stores an array of pages fetched from Wikipedia
    @State private var pages = [Page]()
    
    @State private var wikipediaURL = ""
    
    ///Equal to the string "Vaccination Sites"
    let vaccinationSites = "Vaccination Sites"
    ///Equal to the string "Testing Sites"
    let testingSites = "Testing Sites"

    var body: some View {
        NavigationView {
            Form {
                if shouldEditSite { //only allow editing if I specified that I'm editing the location details
                    Section {
                        Menu {
                            Button("Testing Site"){ isVaccinationSite = false; siteType = "Testing Site" }
                            Button("Vaccination Site"){ isVaccinationSite = true; siteType = "Vaccination Site" }
                        } label: {
                            Text(siteType)
                        }
                        .onChange(of: isVaccinationSite, perform: { isVaccinationSite in
                            locationType = isVaccinationSite ? LocationTypes.vaccinationSite.rawValue : LocationTypes.testingSite.rawValue
                            placemark.wrappedTitle = isVaccinationSite ? "Vaccination Site" : "Testing Site"
                            
                        })
                        
                        Toggle(isOn: $stuffAvailable, label: {
                            if isVaccinationSite {
                                stuffAvailable ? "Vaccines Available".toText() : "Vaccines Not Available".toText()
                            }
                            else {
                                stuffAvailable ? "Tests Available".toText() : "Tests Not Available".toText()
                            }
                        })
                                                
                        TextField("Wait Time (Minutes)", text: $locationWaitTime).keyboardType(.numberPad).onChange(of: locationWaitTime){ newTime in
                            placemark.wrappedSubtitle = !newTime.isEmpty ? newTime + " minute wait" : "Unknown wait time"
                        }
                        
                        TextField("Additional Comments", text: $additionalComments)
                    }
                } //end if shouldEditSite
                
                else {
                //Show wikipedia data for nearby attractions
                    Section(header: Text("Nearby…")) {
                        if loadingState == .loaded {
                            List(pages, id: \.pageid) { page in
                                VStack {
                                    Text(page.title)
                                        .font(.headline)
                                    + Text(": ") +
                                        Text(page.description)
                                        .italic()
                                }.onTapGesture {
                                    //search Google for the location
                                    var urlString: String = page.title
                                    urlString = urlString.replacingOccurrences(of: " ", with: "+")
                                    if let url = URL(string: "http://www.google.com/search?q=\(urlString)") { UIApplication.shared.open(url) }
                                }
                            }
                        } else if loadingState == .loading {
                            Text("Loading…")
                        } else {
                            Text("Please try again later.")
                        }
                    }
                }
            }
            .navigationBarTitle(shouldEditSite ? "Site Details" : "Nearby Attractions")
            .navigationBarItems(trailing: Button("Done") {
                uploadDataToDatabase()
                self.presentationMode.wrappedValue.dismiss()
            })
            
            .onAppear{
                fetchNearbyPlaces()
                
                //determines whether this is a testing site or a vaccination site
                let title = placemark.wrappedTitle
                let subtitle = placemark.wrappedSubtitle
                isVaccinationSite = title == "Vaccination Site" //set the toggle to the correct location
                if title == "Vaccination Site" || title == "Testing Site" { siteType = title } //set the menu display text
                locationType = isVaccinationSite ? LocationTypes.vaccinationSite.rawValue : LocationTypes.testingSite.rawValue
                placemark.wrappedTitle = isVaccinationSite ? "Vaccination Site" : "Testing Site"
                
                if let waitTime = subtitle.split(separator: " ").first{
                    if waitTime.lowercased() != "unknown" { locationWaitTime = String(waitTime) }
                }
                
                stuffAvailable = placemark.wrappedHint == "true"
                
            }
        }
    }
    
    //Determine the loading state of data fetched from Wikipedia
    enum LoadingState {
        case loading, loaded, failed
    }
    
    ///Downloads data from Wikipedia using their API that displays information for a given geographical coordinate
    func fetchNearbyPlaces() {
        let urlString = "https://en.wikipedia.org/w/api.php?ggscoord=\(placemark.coordinate.latitude)%7C\(placemark.coordinate.longitude)&action=query&prop=coordinates%7Cpageimages%7Cpageterms&colimit=50&piprop=thumbnail&pithumbsize=500&pilimit=50&wbptterms=description&generator=geosearch&ggsradius=10000&ggslimit=50&format=json"
        
        wikipediaURL = urlString

        guard let url = URL(string: urlString) else {
            print("Bad URL: \(urlString)")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                // we got some data back!
                let decoder = JSONDecoder()

                if let items = try? decoder.decode(Result.self, from: data) {
                    // success – convert the array values to our pages array
                    self.pages = Array(items.query.pages.values).sorted()
                    self.loadingState = .loaded
                    return
                }
            }

            // if we're still here it means the request failed somehow
            self.loadingState = .failed
        }.resume()
    }
    
    ///Saves the testing or vaccination site to the database so other users can see it
    func uploadDataToDatabase(){
        let latitude =  Double(placemark.coordinate.latitude)
        let longitude = Double(placemark.coordinate.longitude)
        
        //Upload to database as a string "SOME_LATITUDE SOME_LONGITUDE", so latitude is string.first and longitude is string.last
        let coordinateString = "\(latitude) \(longitude)"
        let infoDict: [String: Any] = [coordinatesKey: coordinateString , isVaccinationSiteKey: isVaccinationSite, waitTimeKey: locationWaitTime, availabilityKey: stuffAvailable]
        
        //Identifies the site based on its location. Replace periods with underscores to make the key valid.
        let siteIdentifier = coordinateString.replacingOccurrences(of: ".", with: "_")
        let siteRef = Database.database().reference().child(isVaccinationSite ? vaccinationSites : testingSites).child(siteIdentifier)
        siteRef.child(siteDataKey).setValue(infoDict, withCompletionBlock: { err, _ in
            //Once the site type and wait time have been set, append the comment if there is one
            if err == nil && !additionalComments.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                siteRef.child(commentsKey).childByAutoId().setValue(additionalComments.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        })
        
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView(placemark: MKPointAnnotation.example, shouldEditSite: true)
    }
}

enum LocationTypes: String {
    case testingSite, vaccinationSite
}
