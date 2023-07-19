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

open  class GlitterActivity: UIViewController,WKNavigationDelegate, WKUIDelegate {
    open class LifeCycle{
        open var viewDidLoad:()->()
        open var viewDidAppear:()->()
        open var viewDidDisappear:()->()
        open var viewWillAppear:()->()
        open var viewWillDisappear:()->()
        public init(viewDidLoad:@escaping (()->())={},viewDidAppear:@escaping (()->())={},viewDidDisappear:@escaping (()->())={},viewWillAppear:@escaping(()->())={},viewWillDisappear: @escaping(()->())={}){
            self.viewDidLoad=viewDidLoad
            self.viewDidAppear=viewDidAppear
            self.viewDidDisappear=viewDidDisappear
            self.viewWillAppear=viewWillAppear
            self.viewWillDisappear = viewWillAppear
        }
    }
    
    open class GlitterConfig{
        open var parameters:String
        open var projectRout:URL?
        open var lifeCycle:LifeCycle
        public init(parameters:String = "?page=home",projectRout:URL? = Bundle.main.url(forResource: "home", withExtension: "html", subdirectory: "appData"),lifeCycle:LifeCycle = LifeCycle()){
            self.projectRout=projectRout
            self.parameters=parameters
            self.lifeCycle=lifeCycle
        }
    }
    public static func create(glitterConfig:GlitterConfig)->GlitterActivity{
        let config=GlitterActivity()
        config.glitterConfig=glitterConfig
        return config
    }

    let encoder: JSONEncoder = JSONEncoder()
    open var webView: WKWebView?
    public static var sharedInterFace=[JavaScriptInterFace]()
    /// MyGlitterFunction
    var array=["closeApp","reloadPage","addJsInterFace"]
    
    open var glitterConfig:GlitterConfig = GlitterConfig()
    
    
    
    
    open func setParameters(_ par:String){
        glitterConfig.parameters=par
        let url = glitterConfig.projectRout
        let url2 = URL(string: glitterConfig.parameters, relativeTo: url)!
        guard let webView = webView else{
            return
        }
        webView.load(URLRequest(url: url2))
    }
    
    open func initWkWebView() -> GlitterActivity{
        let conf = WKWebViewConfiguration()
        conf.userContentController = WKUserContentController()
        for a in array{
            conf.userContentController.add(self, name: a)
        }
        for e in GlitterActivity.sharedInterFace{
            javaScriptInterFace.append(e)
        }
        GlitterFunction.create(glitterAct: self)
        conf.preferences.javaScriptEnabled = true
        conf.selectionGranularity = WKSelectionGranularity.character
        conf.allowsInlineMediaPlayback = true
        conf.setValue(true, forKey: "_allowUniversalAccessFromFileURLs")
        webView = WKWebView(frame: .zero, configuration: conf)  //.zero
        if #available(iOS 16.4, *) {
            webView!.isInspectable = true
        } else {
            // Fallback on earlier versions
        }
        guard let webView = webView else{
            return self
        }
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.bounces = false
        //        webView.frame=container.frame
        webView.customUserAgent = "iosGlitter"
        webView.uiDelegate = self
        //解決全屏播放視訊 狀態列閃現導致的底部白條  never:表示不計算內邊距
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        let url = glitterConfig.projectRout
        let url2 = URL(string: glitterConfig.parameters, relativeTo: url)!
        webView.load(URLRequest(url: url2))
        return self
    }
    
    open  override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        if(webView == nil){
            initWkWebView()
        }
        guard let webView = webView else{
            return
        }
        webView.frame=view.bounds
        view.addSubview(webView)
        glitterConfig.lifeCycle.viewDidLoad()
    }
    
    @objc func keyBoardWillShow(notification: NSNotification) {
        print("keyBoardWillShow")
    }
    
    @objc func keyBoardWillHide(notification: NSNotification) {
        print("keyBoardWillHide")
    }
    open override func viewDidAppear(_ animated: Bool) {
        glitterConfig.lifeCycle.viewDidAppear()
        guard let webView = webView else{
            return
        }
        webView.frame=view.bounds
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
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.request.url?.scheme == "tel" {
            UIApplication.shared.openURL(navigationAction.request.url!)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
        
    }
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler()
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        
        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
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
        guard let webView = webView else{
            return
        }
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
            let requestFunction = RequestFunction(receiveValue: receiveValue!,glitterAct: self)
            requestFunction.setCallback(finishv: {
                DispatchQueue.main.async {
                    webView.evaluateJavaScript("""
                    glitter.callBackList.get(\(callbackID))(\(ConversionJson.shared.DictionaryToJson(parameters:requestFunction.responseValue) ?? ""))
                    glitter.callBackList.delete(\(callbackID));
                    """)
                }
            }, callbackv: {
                DispatchQueue.main.async {
                    webView.evaluateJavaScript("""
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
    public var glitterAct:GlitterActivity
    private var finishv={}
    private var callbackv={}
    public init(receiveValue:Dictionary<String,Any>,glitterAct:GlitterActivity){
        self.glitterAct=glitterAct
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


