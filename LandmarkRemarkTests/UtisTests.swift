//
//  UtilsTests.swift
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
            context("can trim extra spaces") {
                it("from left and right") {
                    let testString = "  A string with extra spaces   "
                    let trimmedString = "A string with extra spaces"
                    expect(testString.trim()).to(equal(trimmedString))
                }
                
                it("when a string has extra spaces in between those spaces are not getting trimmed off") {
                    let testString = "  A string with extra spaces    in between"
                    let trimmedString = "A string with extra spaces in between"
                    expect(testString.trim()).notTo(equal(trimmedString))
                }
            }
             context("can condense spaces in between the string") {
                it("extra spaces are eliminated") {
                    let testString = "A    string with       extra spaces"
                    let condensedString = "A string with extra spaces"
                    expect(testString.condenseWhitespace()).to(equal(condensedString))
                }
            }
        
            describe("The time delay utilities") {
                it("can delay a operation") {
                    
                    let valueBefore = "before operaton completion"
                    let valueAfter = "after operation completion"
                    
                    var myVal: String = valueBefore
                    Utils.delay(3.0, closure: {
                        myVal = valueAfter
                    })
                    
                    expect(myVal).toEventually(equal(valueAfter), timeout: 10.0, pollInterval: 2.0)
                }
            }
        }
    }
}
