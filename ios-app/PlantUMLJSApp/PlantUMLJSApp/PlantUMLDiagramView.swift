//
//  ContentView.swift
//  PlantUMLJSApp
//
//  Created by Bartolomeo Sorrentino on 16/04/23.
//

import SwiftUI
import Combine
import WebKit

class PlantUMLDiagramState: ObservableObject {

    private var updateSubject = PassthroughSubject<URL, Never>()
    
    private var cancellabe:Cancellable?
    
    func subscribe( onUpdate update: @escaping ( URLRequest ) -> Void ) {
        
        if self.cancellabe == nil  {
            
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
 
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    
    func makeUIView(context: Context) -> WKWebView {
        
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        // [Load local web files & resources in WKWebView](https://stackoverflow.com/a/49638654/521197)
        state.subscribe( onUpdate: { request in
            
            if let url = request.url, url.scheme == "file" {
            
//                loadHTMLString(webView, from: url)
                loadFile(webView, from: url)
            }
            else {
                webView.load(request)
            }
        })
                
        return webView
    }

 
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = url else {
            return
        }
        
        state.requestUpdate( forURL: url)
        
    }
}

extension PlantUMLDiagramView {
    
    class Coordinator : NSObject, WKNavigationDelegate {
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                     decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

            print( Self.self, #function)
            decisionHandler(.allow)
        }
    }
}

extension PlantUMLDiagramView {
    
    fileprivate func loadFile( _ webView:WKWebView, from url: URL? ) {
        
        guard let url, url.scheme == "file" else { return }
        
        let folderURL = url.deletingLastPathComponent()
        
        webView.loadFileURL(url, allowingReadAccessTo: folderURL)
        
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
            plantuml.initialize('/app/\(folderURL.relativePath)/node_modules/@sakirtemel/plantuml.js').then(() => {
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
        PlantUMLDiagramView()
    }
}
