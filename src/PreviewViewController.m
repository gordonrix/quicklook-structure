#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <WebKit/WebKit.h>
#import "ViewerPage.h"

/// Quick Look preview for .pdb / .cif: a WKWebView showing the 3Dmol cartoon.
@interface PreviewViewController : NSViewController <QLPreviewingController>
@end

@implementation PreviewViewController {
    WKWebView *_webView;
}

- (void)loadView {
    _webView = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, 900, 700)
                                  configuration:[WKWebViewConfiguration new]];
    _webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.view = _webView;
    self.preferredContentSize = NSMakeSize(900, 700);
}

- (void)preparePreviewOfFileAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))handler {
    NSError *error = nil;
    NSString *html = SPViewerPageHTML(url, &error);
    if (!html) {
        handler(error);
        return;
    }
    [_webView loadHTMLString:html baseURL:nil];
    // Hand the view to Quick Look straight away; the page paints as soon as
    // 3Dmol finishes, no need to block on the load.
    handler(nil);
}

@end
