//
//  LocarionManager.swift
//  Glitter
//
//  Created by Jianzhi.wang on 2021/1/20.
//


import Foundation
import CoreLocation
import Glitter_IOS
import MapKit

class LocarionManager {
    static var manager=LocarionManager()
    private let locationManager = CLLocationManager()
    var haveUpdate=false
    //判斷是否有定位
    func haveLocation( control: @escaping ( _ a:String) -> Void){
        guard CLLocationManager.locationServicesEnabled() else{
            control("notOpen")
            return
        }
           // 首次使用 向使用者詢問定位自身位置權限
        if CLLocationManager.authorizationStatus()
            == .notDetermined {
            // 取得定位服務授權
            locationManager.requestWhenInUseAuthorization()
            if(!haveUpdate){
                haveUpdate=true
                locationManager.startUpdatingLocation()
            }
            DispatchQueue.global().async {
                while( CLLocationManager.authorizationStatus() == .notDetermined){sleep(1)}
                DispatchQueue.main.async {
                    LocarionManager.manager.haveLocation(control: control)
                }
            }
        }
            // 使用者已經拒絕定位自身位置權限
        else if CLLocationManager.authorizationStatus()
            == .denied {
            // 提示可至[設定]中開啟權限
            control("denied")
        }
            // 使用者已經同意定位自身位置權限
        else if CLLocationManager.authorizationStatus()
            == .authorizedWhenInUse {
            // 開始定位自身位置
            if(!haveUpdate){
                haveUpdate=true
                locationManager.startUpdatingLocation()
            }
            store()
            control("grant")
        }
        
    }
    
    var lastKnownLocation=LocationData()
    func store(){
        //1
        if(CLLocationManager.authorizationStatus()
            != .authorizedWhenInUse){return}
        let locale = Locale(identifier: "zh-tw")
        if(self.locationManager.location == nil){return}
        let loc: CLLocation = CLLocation(latitude: (self.locationManager.location!.coordinate.latitude), longitude: (self.locationManager.location!.coordinate.longitude))
        if #available(iOS 11.0, *) {
            CLGeocoder().reverseGeocodeLocation(loc, preferredLocale: locale) { placeMark, error in
                guard let placeMark = placeMark?.first, error == nil else {
                    UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                   return
                }
                var b = self.lastKnownLocation
                b.address = "\(placeMark.postalCode ?? "") \(placeMark.country ?? "") \(placeMark.locality ?? "") \(placeMark.name ?? "")"
                self.lastKnownLocation=b
            }
        }
        self.lastKnownLocation = LocationData(lat: String(self.locationManager.location!.coordinate.latitude), lon: String(self.locationManager.location!.coordinate.longitude))
    }
    var timer=Timer()
    init() {
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    @objc func timerAction() {
        store()
    }
    public static func create(){
        let glitterAct=GlitterActivity.getInstance()
        JavaScriptInterFace(functionName: "GpsManager_Status", function: {
                   request in
            LocarionManager.manager.haveLocation(control: {
                       a in
                       request.responseValue["result"]=a
                       request.finish()
                   })
               })
               
        JavaScriptInterFace(functionName: "GpsManager_getGps", function: {
            request in
         LocarionManager.manager.haveLocation(control: {
                a in
                if(a == "grant"){
                    var map:Dictionary<String,String> = Dictionary<String,String>()
                    map["latitude"]=LocarionManager.manager.lastKnownLocation.lat
                    map["longitude"]=LocarionManager.manager.lastKnownLocation.lon
                    map["address"]=LocarionManager.manager.lastKnownLocation.address
                    print("地址:latitude:\(LocarionManager.manager.lastKnownLocation.lat)-\(LocarionManager.manager.lastKnownLocation.address)")
                    request.responseValue["data"]=map
                    request.responseValue["result"]=true
                    request.finish()
                }else{
                    request.responseValue["result"]=a
                    request.finish()
                }
            })
          
        })

    }
}

struct LocationData {
    var lat:String="NA"
    var lon:String="NA"
    var address:String="尚未取得位置"
}
