#import <Foundation/Foundation.h>

/// Builds the self-contained viewer page for one structure file.
///
/// The template (viewer.html with 3Dmol already inlined by build.sh) is read
/// and split once per process; each preview is then two string concatenations
/// around the JSON-encoded file contents.
NSString *_Nullable SPViewerPageHTML(NSURL *_Nonnull url, NSError *_Nullable *_Nullable error);
