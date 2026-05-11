//
//  NemuWidgetBundle.swift
//  NemuWidget
//
//  Created by 遠藤拓弥 on 2026/05/11.
//

import WidgetKit
import SwiftUI

@main
struct NemuWidgetBundle: WidgetBundle {
    var body: some Widget {
        NemuAlarmWidget()
        NemuWidgetControl()
    }
}
