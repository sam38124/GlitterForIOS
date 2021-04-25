//
//  GlitterActivity.swift
//  Glitter
//
//  Created by Jianzhi.wang on 2021/1/22.
//
#if !os(macOS)
import UIKit
#endif
import WebKit
import JzOsSqlHelper
import JzOsHttpExtension
@available(iOS 11.0, *)
open class GlitterActivity: UIViewController,WKUIDelegate {
    //取得單例
    public static var instance:GlitterActivity? = nil
    public static var getInstance:()->GlitterActivity = {
        if(GlitterActivity.instance==nil){ GlitterActivity.instance=GlitterActivity()}
        return GlitterActivity.instance!
    }
    public var projectRout="appData"
    let encoder: JSONEncoder = JSONEncoder()
    open var webView: WKWebView!
    /// MyGlitterFunction
    var array=["setPro","getPro","closeApp","exSql","initByFile","query","playSound","getGPS","requestGPSPermission","initDatabase","reloadPage","openNewTab","initByLocalFile","checkFileExists","downloadFile","getFile","addJsInterFace"]
    /// MapDatabase
    var dataBaseMap:Dictionary<String,SqlHelper> = Dictionary<String,SqlHelper>()

    open  override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyBoardWillShow(notification: NSNotification) {
        print("keyBoardWillShow")
    }
    
    @objc func keyBoardWillHide(notification: NSNotification) {
        print("keyBoardWillHide")
        let superView=view.superview
        view.removeFromSuperview()
        superView?.addSubview(view)
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
        let url = Bundle.main.url(forResource: "home", withExtension: "html", subdirectory: projectRout)!
        webView.loadFileURL(url, allowingReadAccessTo: url)
    }
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // A nil targetFrame means a new window (from Apple's doc)
        if (navigationAction.targetFrame == nil) {
            // Let's create a new webview on the fly with the provided configuration,
            // set us as the UI delegate and return the handle to the parent webview
            let popup = WKWebView(frame: self.view.frame, configuration: configuration)
            popup.uiDelegate = self
            self.view.addSubview(popup)
            return popup
        }
        return nil;
    }
    public func webViewDidClose(_ webView: WKWebView) {
        // Popup window is closed, we remove it
        webView.removeFromSuperview()
    }
    /// JavaScriptInterFace
    var javaScriptInterFace=[JavaScriptInterFace]()
    open func addJavacScriptInterFace(interface:JavaScriptInterFace){
    javaScriptInterFace.append(interface)
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
            print("dataBaseRout"+dataBase)
            dataBaseMap[dataBase] = SqlHelper("\(dataBase).db")
            dataBaseMap[dataBase]?.autoCreat()
            webView.evaluateJavaScript("""
   glitter.callBackList.get(\(json!["callback"]!))(\(dataBaseMap[dataBase]!.initByUrl(Bundle.main.url(forResource: "\(json!["rout"]!)".replace(".db", ""), withExtension: "db", subdirectory: "appData")!.absoluteString)));
   glitter.callBackList.delete(\(json!["callback"]!));
""")
            break
        case "initByLocalFile":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            let dataBase=json!["dataBase"] as! String
            print("dataBaseRout"+dataBase)
            dataBaseMap[dataBase] = SqlHelper("\(dataBase).db")
            dataBaseMap[dataBase]?.autoCreat()
            let fm = FileManager.default
            let dst = NSHomeDirectory() + "/Documents/\(json!["rout"]!)"
            if(!fm.fileExists(atPath: dst)){fm.createFile(atPath: dst, contents: nil, attributes: nil)}
            let urlfrompath = URL(fileURLWithPath: dst)
            webView.evaluateJavaScript("""
   glitter.callBackList.get(\(json!["callback"]!))(\(dataBaseMap[dataBase]!.initByUrl(urlfrompath.absoluteString)));
   glitter.callBackList.delete(\(json!["callback"]!));
""")
            break
        case "checkFileExists":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            let fm = FileManager.default
            let dst =  NSHomeDirectory() + "/Documents/\(json!["fileName"]!)"
            webView.evaluateJavaScript("""
   glitter.callBackList.get(\(json!["callback"]!))(\(fm.fileExists(atPath: dst)));
   glitter.callBackList.delete(\(json!["callback"]!));
""")
            break
        case "initDatabase":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            let dataBase=json!["dataBase"] as! String
            dataBaseMap[dataBase] = SqlHelper("\(dataBase).db")
            dataBaseMap[dataBase]?.autoCreat()
            webView.evaluateJavaScript("""
   glitter.callBackList.get(\(json!["callback"]!))(true);
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
                                 , encoding: .utf8)
            print("rjson:\(encoded!)")
            webView.evaluateJavaScript("""
   glitter.callBackList.get(\(json!["callback"]!))(\(encoded!));
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
        case "reloadPage":
            let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "appData")!
            webView.loadFileURL(url, allowingReadAccessTo: url)
            print("reloadPage")
            break
        case "openNewTab":
            print("openNewTab")
            if let url = URL(string: message.body as! String)
            {
                if #available(iOS 10.0, *)
                {
                    UIApplication.shared.open(url, options: [:])
                }
                else
                {
                    UIApplication.shared.openURL(url)
                }
            }
            break
        case "downloadFile":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            DispatchQueue.global().async {
                let file=HttpCore.get("\(json!["rout"]!)",TimeInterval((json!["timeOut"] as! Int)/1000))
                let dst =  NSHomeDirectory() + "/Documents/\(json!["fileName"]!)"
                let routArray=dst.split(separator: "/")
                print("createRout:\(dst.sub(0..<(dst.count-routArray[routArray.count-1].count)))")
                let fm = FileManager.default
                if !fm.fileExists(atPath: dst) {
                    try? fm.createDirectory(atPath: dst.sub(0..<(dst.count-routArray[routArray.count-1].count-1)), withIntermediateDirectories: true, attributes: nil)
                    try! fm.createFile(atPath: dst, contents: nil, attributes: nil)
                }
                let urlfrompath = URL(fileURLWithPath: dst)
                print("加載路徑:\(urlfrompath)")
                do{
                    try file?.write(to: urlfrompath)
                    DispatchQueue.main.async {
                        self.webView.evaluateJavaScript("""
                        glitter.callBackList.get(\(json!["callback"]!))(true);
                        glitter.callBackList.delete(\(json!["callback"]!));
                        """)
                    }
                }catch{
                    print(error)
                    DispatchQueue.main.async {
                        self.webView.evaluateJavaScript("""
                        glitter.callBackList.get(\(json!["callback"]!))(false);
                        glitter.callBackList.delete(\(json!["callback"]!));
                        """)
                    }
                }
            }
            break
        case "getFile":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            let callbackID="\(json!["callback"]!)"
            let type="\(json!["type"]!)"
            let dst =  NSHomeDirectory() + "/Documents/\(json!["fileName"]!)"
            let urlfrompath = URL(fileURLWithPath: dst)
            DispatchQueue.global().async {
                var script="glitter.callBackList.get(\(callbackID))(undefined)"
                do{
                    var data: Data? = nil
                    try data = Data(contentsOf: urlfrompath)
                    switch(type){
                    case "hex":
                        var tempstring=""
                        for i in data!{
                            tempstring = tempstring+String(format:"%02X",i)
                        }
                        script="glitter.callBackList.get(\(callbackID))('\(tempstring)')"
                        break
                    case "bytes":
                        script="glitter.callBackList.get(\(callbackID))(\([UInt8](data!)))"
                        break
                    case "text":
                        script="glitter.callBackList.get(\(callbackID))(`\(String(data: data!, encoding: String.Encoding.utf8)!)`)"
                        print("s19text:\(String(data: data!, encoding: String.Encoding.utf8)!)")
                        break
                    default:
                        break
                    }
                }catch{
                    print("error:\(error)")
                }
                DispatchQueue.main.async {
                    self.webView.evaluateJavaScript("""
                    \(script);
                    glitter.callBackList.delete(\(callbackID));
                    """)
                }
            }
            break
        case "addJsInterFace":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            let functionName="\(json!["functionName"]!)"
            let callbackID="\(json!["callBackId"]!)"
            print("excuteNative:\(functionName)")
            var receiveValue=json!["data"]! as? Dictionary<String,AnyObject>
            if(receiveValue == nil){receiveValue=Dictionary<String,AnyObject>()}
            let cFunction=javaScriptInterFace.filter({$0.name == functionName})
            let requestFunction = RequestFunction(receiveValue: receiveValue!)
            requestFunction.finish={
            self.webView.evaluateJavaScript("""
            glitter.callBackList.get(\(callbackID))(\(ConversionJson.shared.DictionaryToJson(parameters:requestFunction.responseValue) ?? ""))
            glitter.callBackList.delete(\(callbackID));
            """)
            }
            if(cFunction.size>0){cFunction[0].function(requestFunction)}else{
                requestFunction.finish()
            }
            break
        default:
           
            break
        }
    }
  
}


public extension String{
    func replace(_ target: String, _ withString: String) -> String
    {
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
}
public struct JavaScriptInterFace{
    public var name:String=""
    public var function:(_ request: RequestFunction)-> ()
    public init(functionName:String,function:@escaping (_ request: RequestFunction)-> ()) {
        self.name=functionName
        self.function=function
    }
}
public class RequestFunction{
    public let receiveValue: Dictionary<String,AnyObject>
    public var responseValue: Dictionary<String,Any>=Dictionary<String,Any>()
    public var finish={}
    public init(receiveValue:Dictionary<String,AnyObject>){
        self.receiveValue=receiveValue
    }
}

