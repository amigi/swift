// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// RUN: %target-run-simple-swift
// REQUIRES: executable_test
// REQUIRES: objc_interop

import Swift
import Foundation

// MARK: - Test Suite

#if FOUNDATION_XCTEST
import XCTest
class TestPropertyListEncoderSuper : XCTestCase { }
#else
import StdlibUnittest
class TestPropertyListEncoderSuper { }
#endif

class TestPropertyListEncoder : TestPropertyListEncoderSuper {
  // MARK: - Encoding Top-Level Empty Types
  func testEncodingTopLevelEmptyStruct() {
    let empty = EmptyStruct()
    _testRoundTrip(of: empty, in: .binary, expectedPlist: _plistEmptyDictionaryBinary)
    _testRoundTrip(of: empty, in: .xml, expectedPlist: _plistEmptyDictionaryXML)
  }

  func testEncodingTopLevelEmptyClass() {
    let empty = EmptyClass()
    _testRoundTrip(of: empty, in: .binary, expectedPlist: _plistEmptyDictionaryBinary)
    _testRoundTrip(of: empty, in: .xml, expectedPlist: _plistEmptyDictionaryXML)
  }

  // MARK: - Encoding Top-Level Single-Value Types
  func testEncodingTopLevelSingleValueEnum() {
    let s1 = Switch.off
    _testEncodeFailure(of: s1, in: .binary)
    _testEncodeFailure(of: s1, in: .xml)

    let s2 = Switch.on
    _testEncodeFailure(of: s2, in: .binary)
    _testEncodeFailure(of: s2, in: .xml)
  }

  func testEncodingTopLevelSingleValueStruct() {
    let t = Timestamp(3141592653)
    _testEncodeFailure(of: t, in: .binary)
    _testEncodeFailure(of: t, in: .xml)
  }

  func testEncodingTopLevelSingleValueClass() {
    let c = Counter()
    _testEncodeFailure(of: c, in: .binary)
    _testEncodeFailure(of: c, in: .xml)
  }

  // MARK: - Encoding Top-Level Structured Types
  func testEncodingTopLevelStructuredStruct() {
    // Address is a struct type with multiple fields.
    let address = Address.testValue
    _testRoundTrip(of: address, in: .binary)
    _testRoundTrip(of: address, in: .xml)
  }

  func testEncodingTopLevelStructuredClass() {
    // Person is a class with multiple fields.
    let person = Person.testValue
    _testRoundTrip(of: person, in: .binary)
    _testRoundTrip(of: person, in: .xml)
  }

  func testEncodingTopLevelDeepStructuredType() {
    // Company is a type with fields which are Codable themselves.
    let company = Company.testValue
    _testRoundTrip(of: company, in: .binary)
    _testRoundTrip(of: company, in: .xml)
  }

  // MARK: - Helper Functions
  private var _plistEmptyDictionaryBinary: Data {
    return Data(base64Encoded: "YnBsaXN0MDDQCAAAAAAAAAEBAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAJ")!
  }

  private var _plistEmptyDictionaryXML: Data {
    return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict/>\n</plist>\n".data(using: .utf8)!
  }

  private func _testEncodeFailure<T : Encodable>(of value: T, in format: PropertyListSerialization.PropertyListFormat) {
    do {
      let encoder = PropertyListEncoder()
      encoder.outputFormat = format
      let _ = try encoder.encode(value)
      expectUnreachable("Encode of top-level \(T.self) was expected to fail.")
    } catch {}
  }

  private func _testRoundTrip<T>(of value: T, in format: PropertyListSerialization.PropertyListFormat, expectedPlist plist: Data? = nil) where T : Codable, T : Equatable {
    var payload: Data! = nil
    do {
      let encoder = PropertyListEncoder()
      encoder.outputFormat = format
      payload = try encoder.encode(value)
    } catch {
      expectUnreachable("Failed to encode \(T.self) to plist.")
    }

    if let expectedPlist = plist {
      expectEqual(expectedPlist, payload, "Produced plist not identical to expected plist.")
    }

    do {
      var decodedFormat: PropertyListSerialization.PropertyListFormat = .xml
      let decoded = try PropertyListDecoder().decode(T.self, from: payload, format: &decodedFormat)
      expectEqual(format, decodedFormat, "Encountered plist format differed from requested format.")
      expectEqual(decoded, value, "\(T.self) did not round-trip to an equal value.")
    } catch {
      expectUnreachable("Failed to decode \(T.self) from plist.")
    }
  }
}

// MARK: - Test Types
/* FIXME: Import from %S/Inputs/Coding/SharedTypes.swift somehow. */

// MARK: - Empty Types
fileprivate struct EmptyStruct : Codable, Equatable {
  static func ==(_ lhs: EmptyStruct, _ rhs: EmptyStruct) -> Bool {
    return true
  }
}

fileprivate class EmptyClass : Codable, Equatable {
  static func ==(_ lhs: EmptyClass, _ rhs: EmptyClass) -> Bool {
    return true
  }
}

// MARK: - Single-Value Types
/// A simple on-off switch type that encodes as a single Bool value.
fileprivate enum Switch : Codable {
  case off
  case on

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    switch try container.decode(Bool.self) {
    case false: self = .off
    case true:  self = .on
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .off: try container.encode(false)
    case .on:  try container.encode(true)
    }
  }
}

/// A simple timestamp type that encodes as a single Double value.
fileprivate struct Timestamp : Codable {
  let value: Double

  init(_ value: Double) {
    self.value = value
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    value = try container.decode(Double.self)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.value)
  }
}

/// A simple referential counter type that encodes as a single Int value.
fileprivate final class Counter : Codable {
  var count: Int = 0

  init() {}

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    count = try container.decode(Int.self)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.count)
  }
}

// MARK: - Structured Types
/// A simple address type that encodes as a dictionary of values.
fileprivate struct Address : Codable, Equatable {
  let street: String
  let city: String
  let state: String
  let zipCode: Int
  let country: String

  init(street: String, city: String, state: String, zipCode: Int, country: String) {
    self.street = street
    self.city = city
    self.state = state
    self.zipCode = zipCode
    self.country = country
  }

  static func ==(_ lhs: Address, _ rhs: Address) -> Bool {
    return lhs.street == rhs.street &&
           lhs.city == rhs.city &&
           lhs.state == rhs.state &&
           lhs.zipCode == rhs.zipCode &&
           lhs.country == rhs.country
  }

  static var testValue: Address {
    return Address(street: "1 Infinite Loop",
                   city: "Cupertino",
                   state: "CA",
                   zipCode: 95014,
                   country: "United States")
  }
}

/// A simple person class that encodes as a dictionary of values.
fileprivate class Person : Codable, Equatable {
  let name: String
  let email: String

  init(name: String, email: String) {
    self.name = name
    self.email = email
  }

  static func ==(_ lhs: Person, _ rhs: Person) -> Bool {
    return lhs.name == rhs.name && lhs.email == rhs.email
  }

  static var testValue: Person {
    return Person(name: "Johnny Appleseed", email: "appleseed@apple.com")
  }
}

/// A simple company struct which encodes as a dictionary of nested values.
fileprivate struct Company : Codable, Equatable {
  let address: Address
  var employees: [Person]

  init(address: Address, employees: [Person]) {
    self.address = address
    self.employees = employees
  }

  static func ==(_ lhs: Company, _ rhs: Company) -> Bool {
    return lhs.address == rhs.address && lhs.employees == rhs.employees
  }

  static var testValue: Company {
    return Company(address: Address.testValue, employees: [Person.testValue])
  }
}

// MARK: - Run Tests

#if !FOUNDATION_XCTEST
var PropertyListEncoderTests = TestSuite("TestPropertyListEncoder")
PropertyListEncoderTests.test("testEncodingTopLevelEmptyStruct")        { TestPropertyListEncoder().testEncodingTopLevelEmptyStruct()        }
PropertyListEncoderTests.test("testEncodingTopLevelEmptyClass")         { TestPropertyListEncoder().testEncodingTopLevelEmptyClass()         }
PropertyListEncoderTests.test("testEncodingTopLevelSingleValueEnum")    { TestPropertyListEncoder().testEncodingTopLevelSingleValueEnum()    }
PropertyListEncoderTests.test("testEncodingTopLevelSingleValueStruct")  { TestPropertyListEncoder().testEncodingTopLevelSingleValueStruct()  }
PropertyListEncoderTests.test("testEncodingTopLevelSingleValueClass")   { TestPropertyListEncoder().testEncodingTopLevelSingleValueClass()   }
PropertyListEncoderTests.test("testEncodingTopLevelStructuredStruct")   { TestPropertyListEncoder().testEncodingTopLevelStructuredStruct()   }
PropertyListEncoderTests.test("testEncodingTopLevelStructuredClass")    { TestPropertyListEncoder().testEncodingTopLevelStructuredClass()    }
PropertyListEncoderTests.test("testEncodingTopLevelStructuredClass")    { TestPropertyListEncoder().testEncodingTopLevelStructuredClass()    }
PropertyListEncoderTests.test("testEncodingTopLevelDeepStructuredType") { TestPropertyListEncoder().testEncodingTopLevelDeepStructuredType() }
runAllTests()
#endif
