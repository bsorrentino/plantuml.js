//
//  PlantUMLJSAppApp.swift
//  PlantUMLJSApp
//
//  Created by Bartolomeo Sorrentino on 16/04/23.
//

import SwiftUI

@main
struct PlantUMLJSAppApp: App {
    
    var localUrlrl = {
        return Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "01-basic")!
    }()
    
    var url = {
        URL(string: "https://bsorrentino.github.io/plantuml.js/01-basic/index.html")
    }()
    
    var body: some Scene {
        WindowGroup {
            PlantUMLDiagramView( url: url)
        }
    }
}
