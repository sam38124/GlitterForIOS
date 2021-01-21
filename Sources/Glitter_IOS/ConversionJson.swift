//
//  ParsingJson.swift
//  GotIT EIP
//
//  Created by Ling Zhan on 2019/11/27.
//  Copyright © 2019 Ling Zhan. All rights reserved.
//

import Foundation

class ConversionJson: NSObject {
    static let shared = ConversionJson()
    
    // 解析拿到的 json 轉成 Dictionary 的格式，若沒有回傳 nil
    func JsonToDictionary(data: Data) ->  Dictionary<String,AnyObject>? {
        do {
            //create json object from data
            if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject] {
                // print(json)
                return json
            }
        } catch let error {
            print("JSON to Dictionary error: \(error.localizedDescription)")
        }
        return nil
    } // end func JSONtoDictionary
    
    // 解析拿到的 Dictionary 轉成 JSON 格式
    func DictionaryToJson(parameters: Dictionary<String,AnyObject>) -> String? {
        do {
            return  try String(data:JSONSerialization.data(withJSONObject: parameters,options: .prettyPrinted), encoding: .utf8)
        } catch let error {
            print("Dictionary to JSON error: \(error.localizedDescription)")
            return nil
        }
    }
    //
    func ArrayToJson(parameters: Array<Any>) -> String? {
        do {
            return  try String(data:JSONSerialization.data(withJSONObject: parameters,options: .prettyPrinted), encoding: .utf8)
        } catch let error {
            print("Dictionary to JSON error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 檢查 json 是否為 "<null>"
    func nullToNil(value: AnyObject?) -> AnyObject? {
        if value is NSNull {    return nil } else { return value }
    }
}


