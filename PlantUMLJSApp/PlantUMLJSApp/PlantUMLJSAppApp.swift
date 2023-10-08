//
//  PlantUMLJSAppApp.swift
//  PlantUMLJSApp
//
//  Created by Bartolomeo Sorrentino on 16/04/23.
//

import SwiftUI

@main
struct PlantUMLJSAppApp: App {
    
    var localUrl = {
        Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www")!
    }()
    
    var url = {
        URL(string: "https://bsorrentino.github.io/plantuml.js/01-basic/index.html")
    }()
    
    @State var diagramText:String =
    """
    @startuml
    title welcome
    @enduml
    """
    
    var body: some Scene {
        WindowGroup {
            
            VStack {
                PlantUMLDiagramView( url: localUrl, renderText: diagramText)
                Divider()
                TextEditor(text: $diagramText)
            }
        }
    }
}
