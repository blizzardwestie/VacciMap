//
//  MKPointAnnotation-Codable.swift
//  VacciMap
//
//  Created by Matthew Chertok on 1/29/21.
//  Allows the user to save locations

import Foundation
import MapKit

class CodableMKPointAnnotation: MKPointAnnotation, Codable {
    enum CodingKeys: CodingKey {
        case title, subtitle, latitude, longitude, accessibilityHint
    }

    override init() {
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        super.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        accessibilityHint = try container.decode(String.self, forKey: .accessibilityHint)

        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(subtitle, forKey: .subtitle)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(accessibilityHint, forKey: .accessibilityHint)
    }
}
