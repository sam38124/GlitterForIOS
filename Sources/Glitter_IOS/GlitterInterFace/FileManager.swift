//
//  File.swift
//  
//
//  Created by Jianzhi.wang on 2021/12/14.
//

import Foundation
#if !os(macOS)
import UIKit
#endif
import JzOsHttpExtension

public class FileManagerInterFace{
    public static func create(){
        let glitterAct=GlitterActivity.getInstance()
        //判斷檔案是否存在["route"]
        glitterAct.addJavacScriptInterFace(interface: JavaScriptInterFace(functionName: "FileManager_CheckFileExists", function: {
            request in
            let fileName=request.receiveValue["route"] as! String
            let fm = FileManager.default
            let dst =  NSHomeDirectory() + "/Documents/\(fileName)"
            request.responseValue["result"]=fm.fileExists(atPath: dst)
            request.finish()
        }))
        //下載檔案["url","timeOut","route"]
        glitterAct.addJavacScriptInterFace(interface: JavaScriptInterFace(functionName: "FileManager_DownloadFile", function: {
            request in
            let rout=request.receiveValue["url"] as! String
            let timeOut=request.receiveValue["timeOut"] as! Double
            let fileName=request.receiveValue["route"] as! String
            let file=HttpCore.get("\(rout)",TimeInterval((timeOut)/1000))
            let dst =  NSHomeDirectory() + "/Documents/\(fileName)"
            let routArray=dst.split(separator: "/")
            let fm = FileManager.default
            if !fm.fileExists(atPath: dst) {
                try? fm.createDirectory(atPath: dst.sub(0..<(dst.count-routArray[routArray.count-1].count-1)), withIntermediateDirectories: true, attributes: nil)
                try! fm.createFile(atPath: dst, contents: nil, attributes: nil)
            }
            let urlfrompath = URL(fileURLWithPath: dst)
            print("加載路徑:\(urlfrompath)")
            if(file==nil){
                request.responseValue["result"]=false
            }else{
                do{
                    try file?.write(to: urlfrompath)
                    request.responseValue["result"]=true
                }catch{
                    print(error)
                    request.responseValue["result"]=false
                }
            }
            request.finish()
        }))
        //取得檔案["route","type"]
        glitterAct.addJavacScriptInterFace(interface: JavaScriptInterFace(functionName: "FileManager_GetFile", function: {
            request in
            let rout=request.receiveValue["route"] as! String
            let type=request.receiveValue["type"] as! String
            let dst =  NSHomeDirectory() + "/Documents/\(rout)"
            let urlfrompath = URL(fileURLWithPath: dst)
            do{
                var data: Data? = nil
                try data = Data(contentsOf: urlfrompath)
                switch(type){
                case "hex":
                    var tempstring=""
                    for i in data!{
                        tempstring = tempstring+String(format:"%02X",i)
                    }
                    request.responseValue["data"]=tempstring
                    break
                case "bytes":
                    request.responseValue["data"]=[UInt8](data!)
                    break
                case "text":
                    request.responseValue["data"]=String(data: data!, encoding: String.Encoding.utf8)!
                    break
                default:
                    break
                }
            }catch{
                print("error:\(error)")
            }
            request.finish()
        }))
    }
}
