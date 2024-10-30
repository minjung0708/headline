//
//  HeadlineContentView.swift
//  headline
//
//  Created by MinJung on 10/29/24.
//

import SwiftUI
import WebKit

struct HeadlineContentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert = false
    var headline: Headline
    
    var body: some View {
        NavigationView {
            if let urlString = headline.url, let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                HeadlineWebview(url: url)
                    .navigationTitle(headline.title ?? "")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .ignoresSafeArea()
            } else {
                Color.clear
                    .navigationTitle(headline.title ?? "")
                    .navigationBarTitleDisplayMode(.inline)
                    .onAppear {
                        showAlert = true
                    }
                    .alert(isPresented: $showAlert, content: {
                        Alert(
                            title: Text("URL Error"),
                            message: Text("URL is wrong.\nGo to the previous page."),
                            dismissButton: .default(Text("go back"), action: {
                                dismiss()
                            }))
                    })
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
    let headline = Headline()
    headline.title = "Alleging ‘Russian special operation,’ Georgian president calls for protests over disputed election - CNN"
    headline.url = "https://www.cnn.com/2024/10/27/europe/georgia-election-russia-protests-intl-latam/index.html"
    return HeadlineContentView(headline: headline)
}
