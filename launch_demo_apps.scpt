-- Launch Clawfree on three devices simultaneously

tell application "Terminal"
    activate
    
    -- Launch macOS app in first tab
    do script "cd /Users/roypctw/dev/clawfree && echo '🖥️  Launching macOS app...' && flutter run -d macos"
    delay 2
    
    -- Launch iPhone app in new tab
    tell application "System Events" to keystroke "t" using {command down}
    delay 1
    do script "cd /Users/roypctw/dev/clawfree && echo '📱 Launching iPhone app (Watch will auto-launch)...' && flutter run -d 0E6A6BCB-FFE5-4604-8483-7A822FA781BA" in window 1
    delay 2
    
    -- Instructions tab
    tell application "System Events" to keystroke "t" using {command down}
    delay 1
    do script "echo '✅ Apps launching!' && echo '' && echo '📹 Demo will auto-start in 2 seconds on Apple Watch' && echo '   Flow: Watch speaks → iPhone receives → macOS syncs' && echo '' && echo '🎬 To record:' && echo '   1. QuickTime → New Screen Recording' && echo '   2. Select area covering all three simulator windows' && echo '   3. Click Record' && echo '' && echo '⌨️  To stop apps: Close this Terminal window or Ctrl+C in each tab'" in window 1
end tell
