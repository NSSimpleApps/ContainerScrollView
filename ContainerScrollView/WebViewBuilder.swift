//
//  WebViewBuilder.swift
//  ContainerScrollView
//
//  Created by NSSimpleApps on 13/09/2017.
//  Copyright © 2017 NSSimpleApps. All rights reserved.
//

import Foundation
import WebKit


public class WebViewBuilder {
    private static func webViewConfiguration(isZoomEnabled: Bool) -> WKWebViewConfiguration {
        let isZoomEnabledValue = isZoomEnabled ? "yes" : "no"
        let viewportScriptString = """
var meta = document.createElement('meta');
meta.name = 'viewport';
meta.content = 'width=device-width,initial-scale=1,minimum-scale=1,maximum-scale=5,user-scalable=\(isZoomEnabledValue),shrink-to-fit=no';
var head = document.getElementsByTagName('head')[0];
head.appendChild(meta);
"""
        let disableSelectionScriptString = "document.documentElement.style.webkitUserSelect='none';"
        let disableCalloutScriptString = "document.documentElement.style.webkitTouchCallout='none';"
        
        let viewportScript = WKUserScript(source: viewportScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let disableSelectionScript = WKUserScript(source: disableSelectionScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let disableCalloutScript = WKUserScript(source: disableCalloutScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        let userContentController = WKUserContentController()
        userContentController.addUserScript(viewportScript)
        userContentController.addUserScript(disableSelectionScript)
        userContentController.addUserScript(disableCalloutScript)
        
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.userContentController = userContentController
        
        return webViewConfiguration
    }
    
    private init() {}
    
    public static var webView: WKWebView {
        return self.webView(isZoomEnabled: false)
    }
    
    public static func webView(isZoomEnabled: Bool) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: self.webViewConfiguration(isZoomEnabled: isZoomEnabled))
        
        webView.allowsBackForwardNavigationGestures = false
        webView.contentMode = .scaleToFill
        
        let scrollView = webView.scrollView
        scrollView.decelerationRate = UIScrollView.DecelerationRate.normal
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        
        return webView
    }
}
