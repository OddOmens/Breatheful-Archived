import SwiftUI

struct VersionView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Section {
                    Text("Release 2025.12.1")
                        .font(.headline)
                    Text("Release Date: December 2025")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("""
                        • Updated the "Request a Feature" link
                        • Updated the "Report a Issue" link
                        • Updated the "Documentation" link
                        • Updated "Help" label to "About"
                        • Removed the "Support the App" pages
                        • Removed the "Support the App" pop up
                        • Removed "More Apps" section
                        """).font(.caption)
                }
                
                Divider()
                
                Section {
                    Text("2025.09.1")
                        .font(.headline)
                    Text("Release Date: September 2025")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Added support for iOS26 and Liquid Glass
                        • Added Apple Health integration for Mindfulness Minutes
                        • Added Support Popup every 10 launches
                        • Updated the Help view to be cleaner
                        • Updated the review popup to show on the 2nd and 5th launch
                        • Fixed SVG icons being blurry
                        """).font(.caption)
                }
                
                Divider().padding()
                Section {
                    Text("Version 5.0.0")
                        .font(.headline)
                    Text("Release Date: April 11, 2025")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Added "Voice" to the navigation
                        • Added four voice guides (Basic in and out, and guided stories - English support only)
                        • Added Pastel color set
                        • Added Afternoon to other apps
                        • Added "More" menu for faster navigation
                        • Added some missing words in the translations
                        • Added option to support via one-time or monthly (optional)
                        • Added support prompt every 45 uses (Tapping support will prevent it from showing again)
                        • Removed toggle in customization to hide profile
                        • Updated some audio icons
                        • Updated back buttons to be arrows instead of "done"
                        • Updated Profile from navigation into settings
                        • Updated to iOS 18 as a baseline
                        • Fixed Chinese and Portuguese language selection bug
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 4.1.1")
                        .font(.headline)
                    Text("Release Date: December 30, 2024")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Updated report bug link
                        • Updated request feature link
                        • Fixed a depreciated section of code
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 4.1.0")
                        .font(.headline)
                    Text("Release Date: December 13, 2024")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Updated breathing mode to launch with the last used mode selected
                        • Updated audio track to launch with the last used mode selected
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 4.0.0")
                        .font(.headline)
                    Text("Release Date: November 17, 2024")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Rebuilt the Breathing animation system
                        • Rebuilt the Guide shape preview
                        • Added seven (7) new breathing guide options
                        • Added Six (6) new breathing modes
                        • Added three (3) new audio tracks
                        • Added Navigation Dim
                        • Added option to disable Profile from navigation
                        • Removed two (2) guide options
                        • Moved Profile and Settings to main navigation
                        • General cleanup of code
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 3.3.0")
                        .font(.headline)
                    Text("Release Date: September 13, 2024")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Added support for iOS 18
                        • Added help center link
                        • Updated Privacy and Terms links to new website
                        • Re-Fixed Guide Style and Text overlay bug when using default color scheme
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 3.2.1")
                        .font(.headline)
                    Text("Release Date: August 5th, 2024")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Updated Term of Service is now hosted outside the app
                        • Updated Privacy Policy is now hosted outside the app
                        • Fixed Guide Style and Text overlay bug when using default color scheme
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 3.2.0")
                        .font(.headline)
                    Text("Release Date: July 16th, 2024")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Added alternative app icons
                        • Added a Profile where you can set reminders and see stats
                        • Added color preview when selecting a color
                        • Added eight new vibrant colors
                        • Added two breathing modes (Quick & Focus)
                        • Added a new Breathing Guide
                        • Added matching secondary color selection for breathing mode and audio
                        • Added 3 Reminders throughout the day
                        • Added seconds indicator to breathing modes
                        • Added a new language, Hindi
                        • Added a new language, Japanese
                        • Added a new language, Chinese (Simplified)
                        • Added a new language, Portuguese (Portugal)
                        • Updated Expanding Rings visual
                        • Updated breathing mode "Zen" Icon
                        • Updated UI for Breathe and Audio menus
                        • Updated some missing translations.
                        • Updated Setting button to be in the profile
                        • Fixed Wind audio track
                        • Fixed Expanding Rings Bug
                        • Fixed More Apps section
                        • Renamed original colors with "Dull"
                        • Renamed "Breathing" to "Breathe"
                        • Changed "Theme" to "Dark Theme"
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 3.1.1")
                        .font(.headline)
                    Text("Release Date: April 16th, 2024")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Adjusted review prompt to show after 7th and 12th launch of the app
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 3.1.0")
                        .font(.headline)
                    Text("Release Date: April 13th, 2024")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Added Apple PrivacyInfo
                        • Updated "More Apps" Section
                        • Update settings icons and structure
                        • Fixed theme toggle
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 3.0.1")
                        .font(.headline)
                    Text("Release Date: March 8th, 2024")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Removed "Buy Me A Matcha" Button
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 3.0.0")
                        .font(.headline)
                    Text("Release Date: March 6th, 2024")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • A review popup will show on the 2nd and 4th launch then never again.
                        • Guide color now effects other UI components
                        • Added Expanding Rings
                        • Support email now opens default mail app instead of forcing Apple Mail
                        • Removed this section as it served little purpose for the app
                        • If you need assistance reach out to support
                        • Articles have been removed and replaced with Guide
                        • Guide assists you in the steps to find inner peace
                        • Added note that these will only be provided in English to prevent any translation misunderstand of the developer and Breatheful usage
                        • Language support for French
                        • Language support for German
                        • Language support for Spanish
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 2.4.0")
                        .font(.headline)
                    Text("Release Date: February 19th, 2024")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        **Design**
                        • General design adjustments
                        • Added "Swamp" audio
                        • Added "Meditation" audio
                        • Added "Sprinkler" audio
                        • Fixed bug requiring ringer to be on to hear audio
                        • Added dedicated spots for TOS and Privacy
                        • Updated Privacy Policy
                        • Updated Terms of Service
                        • Updated Support Section
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 2.3.0")
                        .font(.headline)
                    Text("Release Date: December 3rd, 2023")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Updated Icon and Logo
                        • Fixed link to Ideaful App
                        • Updated Support Section
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 2.2.0")
                        .font(.headline)
                    Text("Release Date: December 1st, 2023")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Added "More Apps" Section
                        • General Code improvements
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 2.1.0")
                        .font(.headline)
                    Text("Release Date: October 24th, 2023")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Added "Rotating Dots" Guide Style
                        • Added "Dots Glow" Guide Style
                        • Updated "Dotted" to "Dots" Guide Style
                        • Adjusted dot count in "Dots" Guide Style
                        • Fixed the iPad Release
                        • Fixed the versioning section
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 2.0.0")
                        .font(.headline)
                    Text("Release Date: October 22nd, 2023")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Rebuilt with SwiftUI
                        • New Fresh Icon and Logo
                        • Added Nine Different Breathing Colors
                        • Added Ten Different Breathing Styles
                        • Removed color based on breathing modes
                        • Added "Shallow" Breathing
                        • Added "Monk" Breathing
                        • Added "Lofi" and "Wind" Tracks
                        • Updated "Piano" Track
                        • Added "About" Page
                        • Added "Help" Page
                        • Added "Terms & Policy" Page
                        • Added "Articles" Menu
                        • Added "Settings" Menu
                        • Added Contact and Support Information
                        • Added 200 new phrases
                        • Added count down guide.
                        • Enable or Disable Articles
                        • Enable or Disable Phrases
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 1.2.0")
                        .font(.headline)
                    Text("Release Date: July 24th, 2023")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Updated all icons
                        • Added "Zen" breathing mode
                        • Added "Piano" and "Cat Purr" audio modes
                        • Added 100 new phrases
                        • General Code improvements
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 1.1.0")
                        .font(.headline)
                    Text("Release Date: July 13th, 2023")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Added 100 new phrases
                        • General Code improvements
                        """).font(.caption)
                }
                
                Divider().padding()
                
                Section {
                    Text("Version 1.0.0")
                        .font(.headline)
                    Text("Release Date: July 12th, 2023")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("""
                        • Initial Release
                        """).font(.caption)
                }
            }
            .padding()
            .navigationBarTitle("Version History", displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done".localized)
                        .foregroundColor(Color("AccentColor"))
                }
            )
        }
    }
}
