//
//  WikidataWebView.swift
//  ReCIT_iOS
//
//  The browser the Wikidata link runs in (`W2` in the Figma file). A `WKWebView`, because the
//  three legs of OAuth are redirects only a browser follows, and SwiftUI's own `WebView` starts
//  at iOS 26.
//
//  It is handed the session cookies before it loads anything — the first leg is refused to a
//  request that names nobody — and keeps them in a store of its own, gone with the sheet:
//  nothing it is sent finds its way back into the app's jar (ADR 0008). It reports once, when
//  the browser is sent back to the website (`WikidataOAuthFlow.isReturn`), and loads nothing
//  more.
//

import SwiftUI
import WebKit

struct WikidataWebView: UIViewRepresentable {
    let startURL: URL
    let baseURL: URL
    let cookies: [HTTPCookie]
    /// Called on the main actor when the server sends the browser back.
    let onReturn: () -> Void

    func makeCoordinator() -> Coordinator {
        .init(baseURL: baseURL, onReturn: onReturn)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration: WKWebViewConfiguration = .init()
        configuration.websiteDataStore = .nonPersistent()
        let webView: WKWebView = .init(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator

        let store: WKHTTPCookieStore = configuration.websiteDataStore.httpCookieStore
        let request: URLRequest = .init(url: startURL)
        let cookies: [HTTPCookie] = cookies
        Task { @MainActor in
            for cookie in cookies {
                await store.setCookie(cookie)
            }
            webView.load(request)
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        private let baseURL: URL
        private let onReturn: () -> Void
        private var hasReturned: Bool = false

        init(baseURL: URL, onReturn: @escaping () -> Void) {
            self.baseURL = baseURL
            self.onReturn = onReturn
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url,
                  WikidataOAuthFlow.isReturn(url, baseURL: baseURL) else { return .allow }
            if hasReturned == false {
                hasReturned = true
                onReturn()
            }
            return .cancel
        }
    }
}
