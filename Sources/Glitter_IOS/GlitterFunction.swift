//
//  File.swift
//  
//
//  Created by Jianzhi.wang on 2021/5/31.
//

import Foundation
public class GlitterFunction {
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
        //資料庫接口
        Database.create()
        //檔案夾接口
        FileManagerInterFace.create()
        //聲音管理工具
        SoundManager.create()
        //定位請求
        LocarionManager.create()
    }
    public static func run(functionName: String,obj:Dictionary<String,Any>,finish: @escaping(_ data:Dictionary<String,Any>) -> ()){
        let requestFunction = RequestFunction(receiveValue: obj)
        requestFunction.setCallback(finishv: {
            DispatchQueue.main.async {
                finish(requestFunction.responseValue)
            }
        }, callbackv: {
            DispatchQueue.main.async {
                finish(requestFunction.responseValue)
            }
        })
        let function=GlitterActivity.getInstance().javaScriptInterFace.filter{ $0.name == functionName }
        if(function.size==1){
            function[0].function(requestFunction)
        }else{
            finish(["data":"Function not define"])
        }
    }
}
