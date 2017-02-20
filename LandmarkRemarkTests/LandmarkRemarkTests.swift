//
//  LandmarkRemarkTests.swift
//  LandmarkRemarkTests
//
//  Created by Arinjoy Biswas on 20/2/17.
//  Copyright © 2017 Arinjoy Biswas. All rights reserved.
//

import Quick
import Nimble
@testable import LandmarkRemark

class UtilsSpec: QuickSpec {
    override func spec() {
        describe("The String utilities") {

            it("can trim extra spaces from left and right") {
                let testString = "  A string with extra spaces   "
                let trimmedString = "A string with extra spaces"
                expect(testString.trim()).to(equal(trimmedString))
            }
        
            context("when a string has extra spaaces in between") {
                it("those spcaes are not getting trimmed off") {
                    let testString = "  A string with extra spaces    in between"
                    let trimmedString = "A string with extra spaces in between"
                    expect(testString.trim()).notTo(equal(trimmedString))
                }
            }
        
        }
    }
}
