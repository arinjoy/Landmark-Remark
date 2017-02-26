//
//  LandmarkTests.swift
//  LandmarkRemark
//
//  Created by Arinjoy Biswas on 26/2/17.
//  Copyright © 2017 Arinjoy Biswas. All rights reserved.
//

import Quick
import Nimble
import Parse

@testable import LandmarkRemark

class LandmarkTests: QuickSpec {
    
    override func spec() {
        
        describe("Landmark model") {
            var dict: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
            
            beforeEach {

                dict["landmarkId"] = "landmark111" as AnyObject
                dict["note"] = "The famous landmark" as AnyObject
                let location = PFGeoPoint(latitude:-37.111, longitude: 140.333)
                dict["location"] = location as AnyObject
                dict["savedByUserName"] = "userNameABC" as AnyObject
            }
            
            xit("Can be initialzed with a dictionary of values") {
                let landmark = Landmark(dict: dict)
                expect(landmark.landmarkId).to(equal("landmark111"))
                expect(landmark.note).to(equal("The famous landmark"))
                expect(landmark.location.latitude).to(equal(-37.111))
                expect(landmark.location.longitude).to(equal(140.333))
                expect(landmark.savedByUserName).to(equal("userNameABC"))
            }
            
            it("Can be initialzed with a dictionary of values and a distance info") {
                let landmark = Landmark(dict: dict, distance: "a good distance")
                expect(landmark.landmarkId).to(equal("landmark111"))
                expect(landmark.distanceInfo!).to(equal("a good distance"))

            }
            
        }
    }

    
}
