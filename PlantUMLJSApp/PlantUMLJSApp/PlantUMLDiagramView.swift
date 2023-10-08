//
//  ContentView.swift
//  PlantUMLJSApp
//
//  Created by Bartolomeo Sorrentino on 16/04/23.
//

import SwiftUI
import Combine
import WebKit
import OSLog

class PlantUMLDiagramState: ObservableObject {

    private var updateSubject = PassthroughSubject<URL, Never>()
    
    private var cancellabe:Cancellable?
    
    var navigation: WKNavigation?
    
    func subscribe( onUpdate update: @escaping ( URLRequest ) -> Void ) {
        
        if self.cancellabe == nil {
            
            self.cancellabe = updateSubject
                .removeDuplicates()
                .debounce(for: .seconds(2), scheduler: RunLoop.main)
                .print()
                .map { URLRequest(url: $0 ) }
                .sink( receiveValue: update )

        }

    }
    
    func requestUpdate( forURL url:URL ) {
        updateSubject.send( url )
    }

    
    
}

struct PlantUMLDiagramView: UIViewRepresentable {
 
    @StateObject private var state = PlantUMLDiagramState()
    
    var url: URL?
    var renderText: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator( owner: self )
    }
    
    
    func makeUIView(context: Context) -> WKWebView {
        
        let configs = WKWebViewConfiguration()
        configs.setValue(true, forKey: "_allowUniversalAccessFromFileURLs")
//        configs.setURLSchemeHandler(context.coordinator, forURLScheme: "file")
        let webView = WKWebView(frame: .zero, configuration: configs)
        webView.isInspectable = true
        webView.navigationDelegate = context.coordinator
        
        // [Load local web files & resources in WKWebView](https://stackoverflow.com/a/49638654/521197)
        state.subscribe( onUpdate: { request in
            
            os_log(.debug, "on update url")
            
            if let url = request.url, url.scheme == "file" {
            
                loadHTMLString(webView, from: url)
//                loadFile(webView, from: url)
            }
            else {
                state.navigation = webView.load(request)
                
            }
        })
                
        return webView
    }

 
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = url else {
            return
        }
        
        state.requestUpdate( forURL: url)
        
        if let _ = state.navigation {
            evaluateJS( webView )
        }
    }
}

extension PlantUMLDiagramView {
    
    class Coordinator : NSObject, WKNavigationDelegate, WKURLSchemeHandler {
        
        private var owner: PlantUMLDiagramView
        
        init( owner: PlantUMLDiagramView ) {
            self.owner = owner
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            print( Self.self, #function )
            
            if let url = navigationAction.request.url {
                print("Request URL: \(url)")
            }
            decisionHandler(.allow) // Allow the navigation to continue
        }
                
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

            print( Self.self, #function)
            
            if let nav = owner.state.navigation, nav == navigation {
                owner.evaluateJS( webView )
            }
            
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print( Self.self, #function, "Navigation failed with error: \(error)")
            
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            
            print( Self.self, #function, "\(error)")
            
        }
        
        func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
            
            print( Self.self, #function)
        }
        
        func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
            
            print( Self.self, #function)
        }
    }
}

extension PlantUMLDiagramView {
    
    fileprivate func evaluateJS(_ webView: WKWebView ) {
        
        os_log(.debug, "start evaluating javascript")

        webView.evaluateJavaScript(
                                    """
                                    _render(`\(renderText)`)
                                    
                                    """) { _, error in
         
            if let error {
                os_log(.error, "error evaluating javascript \(error)")
            }
            
        }

    }
    fileprivate func loadFile( _ webView:WKWebView, from url: URL? ) {
        
        guard let url, url.scheme == "file" else { return }
        
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        
    }

    fileprivate func loadHTMLString( _ webView:WKWebView, from url: URL? ) {
        
        guard let url, url.scheme == "file" else { return }
        
        let folderURL = url.deletingLastPathComponent()
        
        print( "folderURL:\(folderURL)\nfolderPath:\(folderURL.relativePath)")
        
        let indexHtml =
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>PlantUML.js Basic Example</title>
        <!-- Require cheerpj dependency -->
        <script src="https://cjrtnc.leaningtech.com/2.3/loader.js"></script>
        <!-- Require PlantUML.js -->
        <script src="node_modules/@sakirtemel/plantuml.js/plantuml.js"></script>
        </head>
        <body>
        <img src="loading.png" id="plantuml-diagram" />
        <script type="text/javascript">
            plantuml.initialize( '\(folderURL.relativePath)', '/app/node_modules/@sakirtemel/plantuml.js').then(() => {
                const element = document.getElementById('plantuml-diagram')
                const pumlContent = `
                    @startuml
                    Bob -> Alice: Hello!
                    @enduml
                `
                const url = plantuml.renderPng(pumlContent).then((blob) => {
                    element.src = window.URL.createObjectURL(blob)
                })
            })
        </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(indexHtml, baseURL: folderURL)
    }
}
    
    
//struct PlantUMLScrollableDiagramView : View {
//
//    var url: URL?
//
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: true) {
//            PlantUMLDiagramView( url: url )
//        }
//    }
//
//}

struct PlantUMLDiagramView_Previews: PreviewProvider {
    static var previews: some View {
        PlantUMLDiagramView( renderText:"")
    }
}
