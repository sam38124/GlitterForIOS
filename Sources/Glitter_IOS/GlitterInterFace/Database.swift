//
//  File.swift
//  
//
//  Created by Jianzhi.wang on 2021/12/14.
//

import Foundation
import JzOsSqlHelper
public class Database {
   
    public static func create(glitterAct:GlitterActivity){
        var dataBaseMap:Dictionary<String,SqlHelper> = Dictionary<String,SqlHelper>()
        for a in [
            //執行資料庫
            JavaScriptInterFace(functionName: "DataBase_exSql", function: {
                request in
                let dataBase=request.receiveValue["name"] as! String
                let sql=request.receiveValue["string"] as! String
                if(dataBaseMap[dataBase] == nil){
                    dataBaseMap[dataBase] = SqlHelper("\(dataBase).db")
                    dataBaseMap[dataBase]?.autoCreat()
                }
                dataBaseMap[dataBase]?.exSql(sql)
                request.responseValue["result"]=true
                request.finish()
            }),
            //查詢資料庫
            JavaScriptInterFace(functionName: "DataBase_Query", function: {
                request in
                let dataBase=request.receiveValue["name"] as! String
                let sql=request.receiveValue["string"] as! String
                if(dataBaseMap[dataBase] == nil){
                    dataBaseMap[dataBase] = SqlHelper("\(dataBase).db")
                    dataBaseMap[dataBase]?.autoCreat()
                }
                var dataList:Array<Dictionary<String,String>> = Array()
                dataBaseMap[dataBase]?.query(sql, {a in
                    var itmap:Dictionary<String,String> = Dictionary<String,String> ()
                    for b in 0..<a.getColumnsCount(){
                        itmap[a.getColumnsName(b)]=a.getString(b)
                    }
                    dataList.append(itmap)
                }, {})
                request.responseValue["data"]=dataList
                request.responseValue["result"]=true
                request.finish()
            }),
            //從Assets中預載資料庫
            JavaScriptInterFace(functionName: "DataBase_InitByAssets", function: {
                request in
                let dataBase=request.receiveValue["name"] as! String
                let rout=request.receiveValue["rout"] as! String
                if(dataBaseMap[dataBase] == nil){
                    dataBaseMap[dataBase] = SqlHelper("\(dataBase).db")
                    dataBaseMap[dataBase]?.autoCreat()
                }
                request.responseValue["result"]=dataBaseMap[dataBase]!.initByUrl(Bundle.main.url(forResource: "\(rout)".replace(".db", ""), withExtension: "db", subdirectory: "appData")!.absoluteString)
                request.finish()
            }),
            //從專案檔案夾中預載資料庫
            JavaScriptInterFace(functionName: "DataBase_InitByLocal", function: {
               request in
               let dataBase=request.receiveValue["name"] as! String
               let rout=request.receiveValue["rout"] as! String
               if(dataBaseMap[dataBase] == nil){
                   dataBaseMap[dataBase] = SqlHelper("\(dataBase).db")
                   dataBaseMap[dataBase]?.autoCreat()
               }
               let fm = FileManager.default
               let dst = NSHomeDirectory() + "/Documents/\(rout)"
               if(!fm.fileExists(atPath: dst)){fm.createFile(atPath: dst, contents: nil, attributes: nil)}
               let urlfrompath = URL(fileURLWithPath: dst)
               request.responseValue["result"]=dataBaseMap[dataBase]!.initByUrl(urlfrompath.absoluteString)
               request.finish()
           })
        ]
        {
            glitterAct.addJavacScriptInterFace(interface: a)
        }
    }
}
