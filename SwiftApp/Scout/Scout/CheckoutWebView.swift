
import SwiftUI
import WebKit


struct CheckoutWebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}
