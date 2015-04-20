#
# Be sure to run `pod lib lint BTFSpotify.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "BTFSpotify"
  s.version          = "0.2.2"
  s.summary          = "BTFSpotify wraps the Spotify Cocoa API using Reactive Cocoa and general sanity."
  s.description      = <<-DESC
											 BTFSpotify abstracts away the asynchronous nature of the CocoaLibSpotify API using Reactive Cocoa signals.
											 It also makes the login and session management much easier.
                       DESC
  s.homepage         = "https://github.com/grav/BTFSpotify"
  s.license          = 'MIT'
  s.author           = { "Mikkel Gravgaard" => "mikkel@klokke.dk" }
  s.source           = { :git => "https://github.com/grav/BTFSpotify.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/klokbaske'

  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'CocoaLibSpotify', '~> 2.4.5'
  s.dependency 'ReactiveCocoa', '~> 2.3'
end
