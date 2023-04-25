//
//  RecordView.swift
//  shutteringRecognition
//
//  Created by Nalinda on 22/4/2023.
//

import SwiftUI

struct RecordView: View {
    var body: some View {
        StutterDetectorView()
            .preferredColorScheme(.dark)
    }
}

struct RecordView_Previews: PreviewProvider {
    static var previews: some View {
        RecordView()
    }
}
