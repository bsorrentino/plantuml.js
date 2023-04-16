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
 
    func makeUIView(context: Context) -> WKWebView {
        
        let webView = WKWebView()
        
        state.subscribe( onUpdate: { request in
            webView.load(request)
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
