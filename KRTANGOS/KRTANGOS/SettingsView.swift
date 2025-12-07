//
//  SettingsView.swift
//  KRTANGOS
//
//  Settings page
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @State private var showKoreanFirst = false
    
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0"
    }
    
    private var buildNumber: String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "1"
    }
    
    private var versionString: String {
        return "\(appVersion) (\(buildNumber))"
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("学習設定")) {
                    Toggle(isOn: $showKoreanFirst) {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundColor(.orange)
                            Text("韓国語を最初に表示")
                        }
                    }
                }
                
                Section(header: Text("アプリ情報")) {
                    HStack {
                        Text("アプリバージョン")
                        Spacer()
                        Text(versionString)
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Text("このアプリについて")
                        }
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

struct AboutView: View {
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("KRTANGOS")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("韓単語ズ")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Version \(appVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding(.top, 32)
            
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("アプリについて")
                    .font(.headline)
                
                Text("KRTANGOSは、効率的に韓国語の単語を学習するためのシンプルで使いやすいアプリです。自動的に韓国語ニュースから語彙を収集し、日本語訳と共に提供します。")
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("このアプリについて")
        .navigationBarTitleDisplayMode(.inline)
    }
}
