//
//  HeadlineContentView.swift
//  headline
//
//  Created by MinJung on 10/29/24.
//

import SwiftUI
import WebKit

struct HeadlineContentView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var headline: HeadlineViewModel.Headline
    
    var body: some View {
        NavigationView {
            if let urlString = headline.url, let url = URL(string: urlString) {
                HeadlineWebview(url: url)
                    .navigationTitle(headline.title ?? "")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .ignoresSafeArea()
            }
        }
    }
}

struct HeadlineWebview: UIViewRepresentable {
    var url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webview = WKWebView()
        webview.load(URLRequest(url: url))
        return webview
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) { }
}

#Preview {
    HeadlineContentView(headline: .init(
        id: UUID(),
        title: "Alleging ‘Russian special operation,’ Georgian president calls for protests over disputed election - CNN",
        url: "https://www.cnn.com/2024/10/27/europe/georgia-election-russia-protests-intl-latam/index.html")
    )
}
