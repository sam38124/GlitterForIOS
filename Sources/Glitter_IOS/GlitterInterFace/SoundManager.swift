//
//  File.swift
//  
//
//  Created by Jianzhi.wang on 2021/12/17.
//

import Foundation

class SoundManager {
    public  static func create(glitterAct:GlitterActivity){
        for a in [ //播放Assets路徑中的檔案
            JavaScriptInterFace(functionName: "SoundManager_PlayAssets", function: {
                request in
                var rout = (request.receiveValue["rout"] as! String).replace("appData", "")
                let res:String=String("\(rout)".split(separator: ".")[0])
                let ext:String=String("\(rout)".split(separator: ".")[1])
                Util_Play_Sound.getInstance.playSound(Bundle.main.url(forResource: res, withExtension: ext, subdirectory: "appData")!)
            }),
            //播放下載下來的檔案
            JavaScriptInterFace(functionName: "SoundManager_PlayFile", function: {
                request in
                var rout = (request.receiveValue["rout"] as! String).replace("appData", "")
                let dst =  NSHomeDirectory() + "/Documents/\(rout)"
                Util_Play_Sound.getInstance.playSound(URL(fileURLWithPath: dst))
            })]{
            glitterAct.addJavacScriptInterFace(interface: a)
        }
    }
}
