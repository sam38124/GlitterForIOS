//
//  GlitterActivity.swift
//  Glitter
//
//  Created by Jianzhi.wang on 2021/1/22.
//

import UIKit
import WebKit
import JzOsBleHelper
import CoreBluetooth
import JzOsSqlHelper
@available(iOS 11.0, *)
open class GlitterActivity: UIViewController,WKUIDelegate,BleCallBack {
    
    
    let encoder: JSONEncoder = JSONEncoder()
    var webView: WKWebView!
    /// MyGlitterFunction
    var array=["setPro","getPro","closeApp","exSql","initByFile","query","playSound","getGPS","requestGPSPermission"]
    /// MapDatabase
    var dataBaseMap:Dictionary<String,SqlHelper> = Dictionary<String,SqlHelper>()
    open  override func viewDidLoad() {
        //禁止頂部下拉 和 底部上拉效果
        super.viewDidLoad()
       
    }
    var first=true
    open override func viewDidAppear(_ animated: Bool) {
        if(!first){
            return
        }
        first=false
        let conf = WKWebViewConfiguration()
        conf.userContentController = WKUserContentController()
        for a in array{
            conf.userContentController.add(self, name: a)
        }
        for b in bleFunction{
            conf.userContentController.add(self, name: b)
        }
        conf.preferences.javaScriptEnabled = true
        conf.selectionGranularity = WKSelectionGranularity.character
        conf.allowsInlineMediaPlayback = true
        conf.setValue(true, forKey: "_allowUniversalAccessFromFileURLs")
        webView = WKWebView(frame: view.frame, configuration: conf)  //.zero
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.bounces = false
        webView.frame=view.bounds
//        webView.frame=container.frame
        webView.customUserAgent = "iosGlitter"
        webView.uiDelegate = self
        //解決全屏播放視訊 狀態列閃現導致的底部白條  never:表示不計算內邊距
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(webView)
        var websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes();
        // Date from
        var dateFrom = Date(timeIntervalSince1970: 0);
        // Execute
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: dateFrom , completionHandler: {})
        let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "appData")!
        webView.loadFileURL(url, allowingReadAccessTo: url)
    }
    
    ///藍牙開發套件
    let bleFunction=["start","startScan","stopScan","writeHex","writeUtf","writeBytes","isOPen","gpsEnable","isDiscovering"]
    var bleUtil : BleHelper? = nil
    func bleLib(_ message: WKScriptMessage)->Bool{
        if(!bleFunction.contains(message.name)){return false}
        if(bleUtil==nil){
            bleUtil=BleHelper(self)
        }
        switch message.name {
        case "start":
            return true
        case "startScan":
            bleUtil?.startScan()
            return true
        case "stopScan":
            bleUtil?.stopScan()
            return true
        case "writeHex":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)!
            bleUtil?.writeHex("\(json["data"]!)", "\(json["txChannel"]!)", "\(json["rxChannel"]!)")
            return true
        case "writeUtf":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)!
            bleUtil?.writeUtf("\(json["data"]!)", "\(json["txChannel"]!)", "\(json["rxChannel"]!)")
            return true
        case "writeBytes":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)!
            bleUtil?.writeBytes(json["data"] as! [UInt8], "\(json["txChannel"]!)", "\(json["rxChannel"]!)")
            return true
        case "isOPen":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)!
            webView.evaluateJavaScript("""
            glitter.callBackList.get(\(json["callback"]!))(\(bleUtil!.isOpen()));
            glitter.callBackList.delete(\(json["callback"]!));
            """)
            return true
        case "isDiscovering":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)!
            webView.evaluateJavaScript("""
            glitter.callBackList.get(\(json["callback"]!))(\(bleUtil!.isScanning()));
            glitter.callBackList.delete(\(json["callback"]!));
            """)
            return true
        default:
            return false
        }
    }
    open func onConnecting() {
        
    }
    
    open func onConnectFalse() {
        
    }
    
    open func onConnectSuccess() {
        
    }
    
    open func rx(_ a: BleBinary) {
        
    }
    
    open func tx(_ b: BleBinary) {
        
    }
    
    open func scanBack(_ device: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var itmap:Dictionary<String,String> = Dictionary<String,String> ()
        itmap["name"]=device.name
        itmap["rssi"]="\(RSSI)"
        let encoder: JSONEncoder = JSONEncoder()
        let encoded = String(data: try!  encoder.encode(itmap) , encoding: .utf8)!
        let data=advertisementData["kCBAdvDataManufacturerData"]
        let advermap:BleAdvertise = BleAdvertise ()
        if(data is Data){
            var tempstring = ""
            for i in (data as! Data){
                tempstring = tempstring+String(format:"%02X",i)
            }
            advermap.readHEX=tempstring
            advermap.readUTF=String(data: data as! Data, encoding: .utf8) ?? ""
            advermap.readBytes=[UInt8](data as! Data)
        }
        print("scanre:\(String(data: try!  encoder.encode(advermap) , encoding: .utf8)!)")
      
        
        webView.evaluateJavaScript("""
        glitter.bleUtil.callback.scanBack(JSON.parse('\(encoded)'),JSON.parse('\(String(data: try!  encoder.encode(advermap) , encoding: .utf8)!)'));
        """)
    }
    
    open func needOpen() {
    }
    
}

extension GlitterActivity: WKScriptMessageHandler {
    open func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "setPro":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            let preferences = UserDefaults.standard
            preferences.set(json!["data"]!,forKey: json!["tag"] as! String)
            let didSave = preferences.synchronize()
            if !didSave {
                print("saverror")
            }
            print("setPro:data-\(json!["data"]!)=tag-\(json!["tag"]!)")
            break
        case "getPro":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            let preferences = UserDefaults.standard
            let currentLevelKey = "\(json!["tag"]!)"
            if preferences.object(forKey: currentLevelKey) == nil {
                webView.evaluateJavaScript("""
glitter.callBackList.get(\(json!["callback"]!))(undefined);
glitter.callBackList.delete(\(json!["callback"]!));
""")
                print("getPro:data-null=tag-\(json!["tag"]!)")
            } else {
                let currentLevel = preferences.string(forKey: currentLevelKey)
                webView.evaluateJavaScript("""
   glitter.callBackList.get(\(json!["callback"]!))('\(currentLevel!)');
glitter.callBackList.delete(\(json!["callback"]!));
""")
                print("getPro:data-\(currentLevel)=tag-\(json!["tag"]!)")
            }
            
            break
        case "closeApp":
            exit(0)
            break
        case "exSql":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            let dataBase=json!["dataBase"] as! String
            if(dataBaseMap[dataBase] == nil){
                dataBaseMap[dataBase] = SqlHelper("\(dataBase).db")
                dataBaseMap[dataBase]?.autoCreat()
            }
            dataBaseMap[dataBase]?.exSql(json!["text"] as! String)
            webView.evaluateJavaScript("""
   glitter.callBackList.get(\(json!["callback"]!))(true);
   glitter.callBackList.delete(\(json!["callback"]!));
""")
            
            break
        case "initByFile":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            let dataBase=json!["dataBase"] as! String
            dataBaseMap[dataBase] = SqlHelper("\(dataBase).db")
            dataBaseMap[dataBase]?.autoCreat()
            webView.evaluateJavaScript("""
   glitter.callBackList.get(\(json!["callback"]!))(\(dataBaseMap[dataBase]!.initByUrl(Bundle.main.url(forResource: "\(json!["rout"]!)".replace(".db", ""), withExtension: "db", subdirectory: "appData")!.absoluteString)));
   glitter.callBackList.delete(\(json!["callback"]!));
""")
            break
        case "query":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            var dataList:Array<Dictionary<String,String>> = Array()
            let dataBase=json!["dataBase"] as! String
            dataBaseMap[dataBase]?.query(json!["text"] as! String, {a in
                var itmap:Dictionary<String,String> = Dictionary<String,String> ()
                for b in 0..<a.getColumnsCount(){
                    itmap[a.getColumnsName(b)]=a.getString(b)
                }
                dataList.append(itmap)
            }, {})
            let encoder: JSONEncoder = JSONEncoder()
            let encoded = String(data: try!  encoder.encode(dataList)
                                 , encoding: .utf8)?.replace("\\\"", "\\\\\"")
            print("rjson:\(encoded!)")
            webView.evaluateJavaScript("""
   glitter.callBackList.get(\(json!["callback"]!))('\(encoded!)');
   glitter.callBackList.delete(\(json!["callback"]!));
""")
            
            break
        case "playSound":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            let res:String=String("\(json!["rout"]!)".split(separator: ".")[0])
            let ext:String=String("\(json!["rout"]!)".split(separator: ".")[1])
            let rout=Bundle.main.url(forResource: res, withExtension: ext, subdirectory: "appData")!
            Util_Play_Sound.getInstance.playSound(rout)
            break
        case "requestGPSPermission":
            LocarionManager.manager.haveLocation(self)
            break
        case "getGPS":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            var map:Dictionary<String,String> = Dictionary<String,String>()
            map["latitude"]=LocarionManager.manager.lastKnownLocation.lat
            map["longitude"]=LocarionManager.manager.lastKnownLocation.lon
            map["address"]=LocarionManager.manager.lastKnownLocation.address
            let encoded = String(data: try!  encoder.encode(map)
                                 , encoding: .utf8)?.replace("\\\"", "\\\\\"")
            webView.evaluateJavaScript("""
   glitter.callBackList.get(\(json!["callback"]!))('\(encoded!)');
   glitter.callBackList.delete(\(json!["callback"]!));
""")
            break
        default:
            if(bleLib(message)){}
            break
        }
    }
}

//[{"data":"{"id":"26C45F","pre":1,"tem":26,"data":"B726C45F94E54AC5000151000481EB","time":"2021-01-20 10:47:03"}"}]

public extension String{
    func replace(_ target: String, _ withString: String) -> String
    {
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
}


class BleAdvertise:Encodable {
    var readUTF=""
    var readBytes:[UInt8]=[UInt8]()
    var readHEX=""
}
