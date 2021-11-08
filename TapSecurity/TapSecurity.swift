//
//  TapSecurity.swift
//  TapSecurity
//
//  Created by Dennis Pashkov on 1/25/17.
//  Copyright © 2017 Tap Payments. All rights reserved.
//

import TapAdditionsKitV2

import struct CCommonCrypto.CCAlgorithm
import func CCommonCrypto.CCCrypt
import struct CCommonCrypto.CCOperation
import struct CCommonCrypto.CCOptions
import struct CCommonCrypto.CCStatus
import var CCommonCrypto.kCCAlgorithmAES128
import var CCommonCrypto.kCCBlockSizeAES128
import var CCommonCrypto.kCCDecrypt
import var CCommonCrypto.kCCEncrypt
import var CCommonCrypto.kCCOptionPKCS7Padding
import var CCommonCrypto.kCCSuccess
import func TapSwiftFixesV2.synchronized

//import Foundation
//import SwiftFixes
//import TapAdditionsKit

/// Tap Security.
public class TapSecurity {
    
    //MARK: - Public -
    //MARK: Methods
    
    /// Encrypts string.
    ///
    /// - Parameter string: String to encrypt.
    /// - Returns: Encrypted string.
    public static func encryptString(_ string: String?) -> String? {
        
        return synchronized(self) {
            
            var inString: String
            var randomData: String
            
            if let nonnullString = string, nonnullString.tap_length > 0 {
                
                randomData = self.randomString(with: 6)
                inString = nonnullString + randomData
            }
            else {
                
                randomData = self.randomString(with: 16)
                inString = randomData
            }
            
            guard let secretData = inString.data(using: .ascii, allowLossyConversion: true) else {
                
                return nil
            }
            
            guard let keyData = "qYB5P2iOaXl6HL13".data(using: .utf8, allowLossyConversion: true) else {
                
                return nil
            }
            
            guard let encryptedData = self.encrypt(secretData, key: keyData, padding: CCOptions(kCCOptionPKCS7Padding)) else {
                
                return nil
            }
            
            let result = randomData + encryptedData.base64EncodedString()
            
            return result
        }
    }
    
    /// Encrypts dictionary.
    ///
    /// - Parameter dictionary: Dictionary to encrypt.
    /// - Returns: Encrypted string.
    public static func encryptDictionary(_ dictionary: [String: String]?) -> String? {
        
        return synchronized(self) {
            
            guard let nonnullDictionary = dictionary, nonnullDictionary.count > 0 else { return nil }
            
            let char_1 = UInt8(1).tap_charString
            let char_4 = UInt8(4).tap_charString
            let char_29 = UInt8(29).tap_charString
            let char_30 = UInt8(30).tap_charString
            
            var stringData = char_1
            
            for (key, value) in nonnullDictionary {
                
                stringData += key + char_29 + value + char_30
            }
            
            stringData += char_4
            
            guard let secretData = stringData.data(using: .utf8, allowLossyConversion: true) else { return nil }
            guard let keyData = "9vcZs54qTms67nwt".data(using: .utf8, allowLossyConversion: true) else { return nil }
            
            guard let encryptedData = self.encrypt(secretData, key: keyData, padding: CCOptions(kCCOptionPKCS7Padding)) else { return nil }
            
            return encryptedData.base64EncodedString()
        }
    }
    
    /// Decrypts dictionary from a given string.
    ///
    /// - Parameter string: Encoded string.
    /// - Returns: Dictionary.
    public static func decryptDictionary(_ string: String?) -> [String: String]? {
        
        return synchronized(self) {
            
            return self.decryptDictionary(string, with: "e3LxM1ANjFb3q5rK")
        }
    }
    
    /// Decrypts encrypted in the app dictionary from a given string.
    ///
    /// - Parameter string: Encrypted string.
    /// - Returns: Dictionary.
    public static func selfDecryptDictionary(_ string: String?) -> [String: String]? {
        
        return synchronized(self) {
            
            return self.decryptDictionary(string, with: "9vcZs54qTms67nwt")
        }
    }
    
    /// Encrypts NSError.
    ///
    /// - Parameter error: Error to encrypt.
    /// - Returns: Encrypted string.
    public static func encryptError(_ error: NSError?) -> String? {
        
        return synchronized(self) {
            
            guard let nonnullError = error else { return "" }
            
            let char_1 = UInt8(1).tap_charString
            let char_4 = UInt8(4).tap_charString
            let char_29 = UInt8(29).tap_charString
            let char_30 = UInt8(30).tap_charString
            
            var stringData = char_1
            stringData += "CODE" + char_29 + "\(nonnullError.code)" + char_30
            stringData += "DMN" + char_29 + nonnullError.domain + char_30
            stringData += "INF" + char_29 + "\(nonnullError.userInfo.tap_safeJSONString)" + char_30
            stringData += char_4
            
            guard let data = stringData.data(using: .ascii, allowLossyConversion: true) else { return "" }
            guard let keyData = "nOduKbtXwOelG1tR".data(using: .utf8, allowLossyConversion: true) else { return "" }
            
            return self.encrypt(data, key: keyData, padding: CCOptions(kCCOptionPKCS7Padding))?.base64EncodedString()
        }
    }
    
    //MARK: - Private -
    //MARK: Properties
    
    private static let encryptionTable = [
        
        "o", "P", "q", "R",
        "4", "5", "6", "7",
        "E", "f", "G", "h",
        "Y", "z", "a", "B",
        "I", "j", "K", "l",
        "M", "n", "O", "p",
        "A", "b", "C", "d",
        "Q", "r", "S", "t",
        "U", "v", "W", "x",
        "c", "D", "e", "F",
        "g", "H", "i", "J",
        "k", "L", "m", "N",
        "s", "T", "u", "V",
        "w", "X", "y", "Z",
        "0", "1", "2", "3",
        "8", "9", "+", "/"
    ]
    
    //MARK: Methods
    
    @available(*, unavailable) private init() {
        
        fatalError("This class cannot be instantiated.")
    }
    
    private static func randomString(with length: Int) -> String {
        
        let uniformLength: UInt32 = UInt32(self.encryptionTable.count)
        
        var result: String = ""
        
        while result.tap_length < length {
            
            result += self.encryptionTable[Int(arc4random_uniform(uniformLength))]
        }
        
        return result
    }
    
    private static func decryptDictionary(_ string: String?, with key: String) -> [String: String]? {
        
        guard let nonnullString = string else { return nil }
        guard let stringData = Data(base64Encoded: nonnullString) else { return nil }
        guard let keyData = key.data(using: .utf8, allowLossyConversion: true) else { return nil }
        
        guard let data = self.decrypt(stringData, key: keyData, padding: CCOptions(kCCOptionPKCS7Padding)) else { return nil }
        guard let output = String(data: data, encoding: .utf8) else { return nil }
        
        var receivedData = false
        var expectedCharacter = Character(UnicodeScalar(1))
        
        var result: [String: String] = [:]
        
        var tempKey = ""
        var tempValue = ""
        
        var tempVar = ""
        
        for index in 0..<output.tap_length {
            
            let ch = output[output.index(output.startIndex, offsetBy: index)]
            
            if ch == Character(UnicodeScalar(1)) {
                
                if ch == expectedCharacter {
                    
                    receivedData = true
                    expectedCharacter = Character(UnicodeScalar(29))
                }
                else {
                    
                    return nil
                }
            }
            else if ch == Character(UnicodeScalar(4)) {
                
                if receivedData {
                    
                    return result
                }
                else {
                    
                    return nil
                }
            }
            else if receivedData {
                
                if ch == Character(UnicodeScalar(29)) {
                    
                    if ch == expectedCharacter {
                        
                        tempKey = tempVar
                        tempVar = ""
                        
                        expectedCharacter = Character(UnicodeScalar(30))
                    }
                    else {
                        
                        return nil
                    }
                }
                else if ch == Character(UnicodeScalar(30)) {
                    
                    if ch == expectedCharacter {
                        
                        tempValue = tempVar
                        
                        result[tempKey] = tempValue
                        
                        tempKey = ""
                        tempValue = ""
                        tempVar = ""
                        
                        expectedCharacter = Character(UnicodeScalar(29))
                    }
                    else {
                        
                        return nil
                    }
                }
                else {
                    
                    tempVar += String(ch)
                }
            }
        }
        
        return nil
    }
    
    private static func encrypt(_ data: Data, key: Data, padding: CCOptions) -> Data? {
        
        return self.doCipher(data, key: key, context: CCOperation(kCCEncrypt), padding: padding)
    }
    
    private static func decrypt(_ data: Data, key: Data, padding: CCOptions) -> Data? {
        
        return self.doCipher(data, key: key, context: CCOperation(kCCDecrypt), padding: padding)
    }
    
    private static func doCipher(_ data: Data, key: Data, context: CCOperation, padding: CCOptions) -> Data? {
        
        let keyBytes = key.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in return bytes }
        let iv = Data(repeating: 0, count: kCCBlockSizeAES128)
        let ivBuffer = iv.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in return bytes }
        let dataBytes = data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in return bytes }
        
        var bufferData = Data(repeating: 0, count: data.count + kCCBlockSizeAES128)
        let bufferPointer = bufferData.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in return bytes }
        
        var bytesDecrypted = 0
        
        let cryptStatus = CCCrypt(context,
                                  CCAlgorithm(kCCAlgorithmAES128),
                                  padding,
                                  keyBytes,
                                  key.count,
                                  ivBuffer,
                                  dataBytes,
                                  data.count,
                                  bufferPointer,
                                  bufferData.count,
                                  &bytesDecrypted)
        
        if cryptStatus == CCStatus(kCCSuccess) {
            
            return bufferData.subdata(in: Range(uncheckedBounds: (0, bytesDecrypted)))
        }
        else {
            
            return nil
        }
    }
}
