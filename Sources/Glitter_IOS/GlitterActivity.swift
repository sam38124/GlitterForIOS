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
    
    ///
    var parameters = "?page=home"
    open func setParameters(_ par:String){
        self.parameters = par
        if(!first){
            let url = Bundle.main.url(forResource: "home", withExtension: "html", subdirectory: projectRout)!
            let url2 = URL(string: parameters, relativeTo: url)!
            webView.load(URLRequest(url: url2))
        }
    }
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
        let conf = WKWebViewConfiguration()
        conf.userContentController = WKUserContentController()
        for a in array{
            conf.userContentController.add(self, name: a)
        }
        GlitterFunction.create()
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
//        http://192.168.50.163/Petstagram/home.html?page=Page_Show_Article_Type_1&artID=20
//        url.absoluteString=""
        let url2 = URL(string: parameters, relativeTo: url)!
        webView.load(URLRequest(url: url2))
        first=false
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
       
        case "closeApp":
            exit(0)
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
        case "addJsInterFace":
            let json=ConversionJson.shared.JsonToDictionary(data:  "\(message.body)".data(using: .utf8)!)
            let functionName="\(json!["functionName"]!)"
            let callbackID="\(json!["callBackId"]!)"
            print("excuteNative:\(functionName)")
            var receiveValue=json!["data"]! as? Dictionary<String,AnyObject>
            if(receiveValue == nil){receiveValue=Dictionary<String,AnyObject>()}
            let cFunction=javaScriptInterFace.filter({$0.name == functionName})
            let requestFunction = RequestFunction(receiveValue: receiveValue!)
            requestFunction.setCallback(finishv: {
                DispatchQueue.main.async {
                    self.webView.evaluateJavaScript("""
                    glitter.callBackList.get(\(callbackID))(\(ConversionJson.shared.DictionaryToJson(parameters:requestFunction.responseValue) ?? ""))
                    glitter.callBackList.delete(\(callbackID));
                    """)
                }
            }, callbackv: {
                DispatchQueue.main.async {
                    self.webView.evaluateJavaScript("""
                    glitter.callBackList.get(\(callbackID))(\(ConversionJson.shared.DictionaryToJson(parameters:requestFunction.responseValue) ?? ""));
                    """)
                }
            })
            if(cFunction.size>0){
                cFunction[0].function(requestFunction)
            }else{
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
    private var finishv={}
    private var callbackv={}
    public init(receiveValue:Dictionary<String,AnyObject>){
        self.receiveValue=receiveValue
    }
    public func finish(){
        finishv()
    }
    public func callback(){
        callbackv()
    }
    public func setCallback(finishv:@escaping ()->(),callbackv:@escaping ()->()){
        self.callbackv=callbackv
        self.finishv=finishv
    }
}

