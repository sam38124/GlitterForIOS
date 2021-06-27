//
//  File.swift
//  
//
//  Created by Jianzhi.wang on 2021/5/31.
//

import Foundation
class GlitterFunction {
    public static func create(){
        let glitterAct=GlitterActivity.getInstance()
        //取得紀錄
        glitterAct.addJavacScriptInterFace(interface:JavaScriptInterFace(functionName: "getPro", function: {
            item in
            DispatchQueue.main.async {
            let preferences = UserDefaults.standard
            let data=item.receiveValue["name"]
            let currentLevel = preferences.string(forKey: "\(data!)")
            item.responseValue["data"]=currentLevel
            print("getPro:\(data!)-\(currentLevel)")
            item.finish()
            }
        }))
        //存紀錄
        glitterAct.addJavacScriptInterFace(interface:JavaScriptInterFace(functionName: "setPro", function: {
            item in
            DispatchQueue.main.async {
                let preferences = UserDefaults.standard
                let name=item.receiveValue["name"]
                let data=item.receiveValue["data"]
                preferences.set("\(data!)",forKey:"\(name!)" )
                let didSave = preferences.synchronize()
                if !didSave {
                    print("saverror")
                }
                print("setPro:\(didSave)")
                item.responseValue["result"]=true
                item.finish()
            }
        }))
    }
}
