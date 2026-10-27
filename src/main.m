#import <Cocoa/Cocoa.h>
#import "ViewerPage.h"

// Host app for the Quick Look extension. Launching it isn't required (build.sh
// registers the extension), but macOS only loads extensions that live inside
// an app.
//
//   "Structure Preview" --render in.pdb out.html   writes the preview page, for debugging

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc == 4 && strcmp(argv[1], "--render") == 0) {
            NSError *error = nil;
            NSString *html = SPViewerPageHTML([NSURL fileURLWithPath:@(argv[2])], &error);
            if (!html || ![html writeToFile:@(argv[3]) atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
                fprintf(stderr, "%s\n", error.localizedDescription.UTF8String);
                return 1;
            }
            return 0;
        }

        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        [NSApp activateIgnoringOtherApps:YES];
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"Structure Preview is installed";
        alert.informativeText = @"Select a .pdb or .cif file in Finder and press Space.";
        [alert runModal];
    }
    return 0;
}
