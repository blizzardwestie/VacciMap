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
                        Toggle(isOn: $isVaccinationSite, label: {
                            isVaccinationSite ? "Vaccination Site".toText() : "Testing Site".toText()
                        }).toggleStyle(SwitchToggleStyle(tint: .blue)).onChange(of: isVaccinationSite, perform: { isVaccinationSite in
                            locationType = isVaccinationSite ? LocationTypes.vaccinationSite.rawValue : LocationTypes.testingSite.rawValue
                            placemark.wrappedTitle = isVaccinationSite ? "Vaccination Site" : "Testing Site"
                            
                        })
                                                
                        TextField("Wait Time (Minutes)", text: $locationWaitTime).keyboardType(.numberPad).onChange(of: locationWaitTime){ newTime in
                            placemark.wrappedSubtitle = newTime + " minute wait"
                        }
                        
                        TextField("Additional Comments", text: $additionalComments)
                    }
                }
                
                //Handle what to display when the page loads or fails to load
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
            .navigationBarTitle(shouldEditSite ? "Edit place" : "Nearby Attractions")
            .navigationBarItems(trailing: Button("Done") {
                self.presentationMode.wrappedValue.dismiss()
            })
            
            .onAppear{
                fetchNearbyPlaces()
                
                //determines whether this is a testing site or a vaccination site
                let title = placemark.wrappedTitle
                let subtitle = placemark.wrappedSubtitle
                isVaccinationSite = title == "Vaccination Site" //set the toggle to the correct location
                locationType = isVaccinationSite ? LocationTypes.vaccinationSite.rawValue : LocationTypes.testingSite.rawValue
                placemark.wrappedTitle = isVaccinationSite ? "Vaccination Site" : "Testing Site"
                
                if let waitTime = subtitle.split(separator: " ").first{ locationWaitTime = String(waitTime) }
                
            }.onDisappear { uploadDataToDatabase() }
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
        if locationWaitTime.isEmpty { return } //don't upload any data if the wait time is empty
        
        //Round latitude and longitude to the thousandth of a degree, since no two users will place the pin at exactly the same site.
        let latitude =  round(Double(placemark.coordinate.latitude)*1000)/1000
        let longitude = round(Double(placemark.coordinate.longitude)*1000)/1000
        
        //Upload to database as a string "SOME_LATITUDE SOME_LONGITUDE", so latitude is string.first and longitude is string.last
        let coordinateString = "\(latitude) \(longitude)"
        let infoDict: [String: Any] = [coordinatesKey: coordinateString , isVaccinationSiteKey: isVaccinationSite, waitTimeKey: locationWaitTime]
        
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
