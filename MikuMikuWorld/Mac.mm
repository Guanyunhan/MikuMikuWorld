#import "Mac.hh"
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

namespace platform {

void openFolderInFinder(const std::string& path) {
    @autoreleasepool {
        NSString *nsPath = [NSString stringWithUTF8String:path.c_str()];
        NSURL *url = [NSURL fileURLWithPath:nsPath];
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

void openURLInBrowser(const std::string& url) {
    @autoreleasepool {
        NSString *nsUrlStr = [NSString stringWithUTF8String:url.c_str()];
        NSURL *nsUrl = [NSURL URLWithString:nsUrlStr];
        if (nsUrl) {
            [[NSWorkspace sharedWorkspace] openURL:nsUrl];
        }
    }
}

IO::MessageBoxResult showMessageBox(const std::string& title, const std::string& message, IO::MessageBoxButtons buttons, IO::MessageBoxIcon icon) {
    @autoreleasepool {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = [NSString stringWithUTF8String:title.c_str()];
        alert.informativeText = [NSString stringWithUTF8String:message.c_str()];
        
        switch (icon) {
            case IO::MessageBoxIcon::Information:
                alert.alertStyle = NSAlertStyleInformational;
                break;
            case IO::MessageBoxIcon::Warning:
                alert.alertStyle = NSAlertStyleWarning;
                break;
            case IO::MessageBoxIcon::Error:
                alert.alertStyle = NSAlertStyleCritical;
                break;
            default:
                alert.alertStyle = NSAlertStyleInformational;
                break;
        }
        
        switch (buttons) {
            case IO::MessageBoxButtons::Ok:
                [alert addButtonWithTitle:@"OK"];
                break;
            case IO::MessageBoxButtons::OkCancel:
                [alert addButtonWithTitle:@"OK"];
                [alert addButtonWithTitle:@"Cancel"];
                break;
            case IO::MessageBoxButtons::YesNo:
                [alert addButtonWithTitle:@"Yes"];
                [alert addButtonWithTitle:@"No"];
                break;
            case IO::MessageBoxButtons::YesNoCancel:
                [alert addButtonWithTitle:@"Yes"];
                [alert addButtonWithTitle:@"No"];
                [alert addButtonWithTitle:@"Cancel"];
                break;
        }
        
        NSModalResponse response = [alert runModal];
        
        switch (buttons) {
            case IO::MessageBoxButtons::Ok:
                return IO::MessageBoxResult::Ok;
            case IO::MessageBoxButtons::OkCancel:
                return (response == NSAlertFirstButtonReturn) ? IO::MessageBoxResult::Ok : IO::MessageBoxResult::Cancel;
            case IO::MessageBoxButtons::YesNo:
                return (response == NSAlertFirstButtonReturn) ? IO::MessageBoxResult::Yes : IO::MessageBoxResult::No;
            case IO::MessageBoxButtons::YesNoCancel:
                if (response == NSAlertFirstButtonReturn) return IO::MessageBoxResult::Yes;
                if (response == NSAlertSecondButtonReturn) return IO::MessageBoxResult::No;
                return IO::MessageBoxResult::Cancel;
            default:
                return IO::MessageBoxResult::None;
        }
    }
}

std::string getUserLanguageCode() {
    @autoreleasepool {
        NSString *localeID = [[NSLocale currentLocale] localeIdentifier];
        NSArray<NSString *> *parts = [localeID componentsSeparatedByString:@"_"];
        NSString *langCode = parts.firstObject ?: @"en";
        
        return [langCode UTF8String];
    }
}

static NSArray<NSString*>* buildAllowedFileTypes(const std::vector<IO::FileDialogFilter>& filters) {
    NSMutableSet<NSString*>* exts = [NSMutableSet set];
    for (const auto& filter : filters) {
        size_t pos = 0;
        while ((pos = filter.filterType.find("*.", pos)) != std::string::npos) {
            size_t start = pos + 2;
            size_t end = filter.filterType.find_first_of(";|", start);
            std::string ext = filter.filterType.substr(start, end - start);
            [exts addObject:[NSString stringWithUTF8String:ext.c_str()]];
            if (end == std::string::npos) break;
            pos = end + 1;
        }
    }
    return [exts allObjects];
}

IO::FileDialogResult showFileDialog( const std::string& title, const std::string& inputFilename, const std::string& defaultExtension, std::vector<IO::FileDialogFilter> filters, IO::DialogType type, std::string& outputFilename) {
    @autoreleasepool {
        NSSavePanel* savePanel = nil;
        NSOpenPanel* openPanel = nil;
        
        NSSavePanel* panel = nil;
        
        if (type == IO::DialogType::Save) {
            savePanel = [NSSavePanel savePanel];
            panel = savePanel;
        } else {
            openPanel = [NSOpenPanel openPanel];
            openPanel.canChooseFiles = YES;
            openPanel.canChooseDirectories = NO;
            openPanel.allowsMultipleSelection = NO;
            panel = openPanel;
        }
        
        panel.title = [NSString stringWithUTF8String:title.c_str()];
        
        if (!inputFilename.empty()) {
            panel.nameFieldStringValue = [NSString stringWithUTF8String:inputFilename.c_str()];
        }
        
        if (!defaultExtension.empty()) {
            panel.allowedFileTypes = @[ [NSString stringWithUTF8String:defaultExtension.c_str()] ];
        } else if (!filters.empty()) {
            panel.allowedFileTypes = buildAllowedFileTypes(filters);
        }
        
        NSInteger result = [panel runModal];
        if (result == NSModalResponseOK) {
            NSString* path = [[panel URL] path];
            outputFilename = std::string([path UTF8String]);
            return IO::FileDialogResult::OK;
        }
        
        return IO::FileDialogResult::Cancel;
    }
}

std::string getBuildVersion() {
    @autoreleasepool {
        NSString* build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        return [build UTF8String];
    }
}

}
