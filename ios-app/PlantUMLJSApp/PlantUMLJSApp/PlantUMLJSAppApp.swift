//
//  PlantUMLJSAppApp.swift
//  PlantUMLJSApp
//
//  Created by Bartolomeo Sorrentino on 16/04/23.
//

import SwiftUI

@main
struct PlantUMLJSAppApp: App {
    
    var url = {
        return Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "01-basic")!
    }()
    
    var body: some Scene {
        WindowGroup {
            PlantUMLDiagramView( url: url)
        }
    }
}
