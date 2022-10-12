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
open  class GlitterActivity: UIViewController,WKUIDelegate {
    open class LifeCycle{
        open var viewDidLoad:()->() = {}
        open var viewDidAppear:()->() = {}
        open var viewDidDisappear:()->() = {}
        open var viewWillAppear:()->() = {}
        open var viewWillDisappear:()->() = {}
        public init(){}
    }

    open class GlitterConfig{
        open var parameters = "?page=home"
        open var projectRout = Bundle.main.url(forResource: "home", withExtension: "html", subdirectory: "appData")!
        open var lifeCycle=LifeCycle()
        public init(){}
    }
    public static func create(glitterConfig:GlitterConfig)->GlitterActivity{
        let config=GlitterActivity()
        config.glitterConfig=glitterConfig
        return config
    }
    let encoder: JSONEncoder = JSONEncoder()
    open var webView: WKWebView!
    /// MyGlitterFunction
    var array=["closeApp","reloadPage","addJsInterFace"]
    
    var glitterConfig:GlitterConfig = GlitterConfig()
    
   
    
    
    open func setParameters(_ par:String){
        glitterConfig.parameters=par
        if(!first){
            let url = glitterConfig.projectRout
            let url2 = URL(string: glitterConfig.parameters, relativeTo: url)!
            webView.load(URLRequest(url: url2))
        }
    }
    open  override func viewDidLoad() {
        super.viewDidLoad()
        glitterConfig.lifeCycle.viewDidLoad()
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
        glitterConfig.lifeCycle.viewDidAppear()
        if(!first){
            return
        }
        let conf = WKWebViewConfiguration()
        conf.userContentController = WKUserContentController()
        for a in array{
            conf.userContentController.add(self, name: a)
        }
        GlitterFunction.create(glitterAct: self)
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
        let url = glitterConfig.projectRout
        let url2 = URL(string: glitterConfig.parameters, relativeTo: url)!
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
    
    public override func viewWillAppear(_ animated: Bool) {
        glitterConfig.lifeCycle.viewWillAppear()
    }
    public override func viewWillDisappear(_ animated: Bool) {
        glitterConfig.lifeCycle.viewDidDisappear()
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
    public let receiveValue: Dictionary<String,Any>
    public var responseValue: Dictionary<String,Any>=Dictionary<String,Any>()
    private var finishv={}
    private var callbackv={}
    public init(receiveValue:Dictionary<String,Any>){
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


