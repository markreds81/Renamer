//
//  ContentView.swift
//  Renamer
//
//  Created by Marco on 10/01/24.
//

import SwiftUI
import PDFKit

struct ContentView: View {
    @EnvironmentObject
    private var appState: AppState
	
	@AppStorage("leadingText")
	private var leadingText = String()
	
	@AppStorage("trailingText")
	private var trailingText = String()
	
	@State
	private var nameDate = Date()
	
	@AppStorage("nameCounter")
	private var nameCounter = Int(1)
	
	@AppStorage("leadingZeros")
	private var leadingZeros = Int(0)
	
	@AppStorage("fieldsDivider")
	private var fieldsDivider = String()
	
	@State
	private var dateFormat = DateFormat.yyyyMMdd
	
	@AppStorage("shouldAppendDate")
	private var shouldAppendDate = false
	
	@AppStorage("shouldAppendCounter")
	private var shouldAppendCounter = false
	
	@AppStorage("shouldPutDivider")
	private var shouldPutDivider = false
	
	@State
	private var errorOccurred = false
	
	@State
	private var errorMessage = String()
	
	enum DateFormat: String, CaseIterable, Identifiable {
		case yyyyMMdd
		case yyyyMM
		case yyyy
		
		var id: String { self.rawValue }
	}
	
    var body: some View {
        VStack {
            /// File drop and preview area
            VStack {
                if let documentUrl = appState.documentUrl {
                    if documentUrl.pathExtension.caseInsensitiveCompare("pdf") == .orderedSame {
                        PDFKitView(url: documentUrl)
                        Text(documentUrl.lastPathComponent)
                            .font(.caption)
                    } else {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: documentUrl.path(percentEncoded: false)))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64.0, height: 64.0)
                        Text(documentUrl.lastPathComponent)
                    }
                } else {
                    Image(systemName: "doc.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48.0, height: 48.0)
                        .foregroundStyle(.tint)
                    Text("Drag a file here")
                }
            }
            .onDrop(of: [.fileURL], isTargeted: nil) { providers -> Bool in
                if let provider = providers.first(where: { $0.canLoadObject(ofClass: URL.self) }) {
                    let _ = provider.loadObject(ofClass: URL.self) { object, error in
                        if let url = object {
                            DispatchQueue.main.async {
                                appState.documentUrl = url
                            }
                        }
                    }
                    return true
                }
                return false
            }
            
            /// Rename options
            GroupBox(label: Text("Rules")) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Leading text:")
                        TextField("Leading text", text: $leadingText)
                            .disableAutocorrection(true)
                    }
                    
                    HStack {
                        Toggle(isOn: $shouldAppendDate) {
                            Text("Append date:")
                        }
                        .toggleStyle(.checkbox)
                        
                        DatePicker("", selection: $nameDate, displayedComponents: [.date])
                        
                        Picker("Format:", selection: $dateFormat) {
                            ForEach(DateFormat.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                    }
                    
                    HStack {
                        Toggle(isOn: $shouldAppendCounter) {
                            Text("Append counter:")
                        }
                        .toggleStyle(.checkbox)
                        
                        Stepper(value: $nameCounter) {
                            TextField("Start from", value: $nameCounter, formatter: NumberFormatter())
                        }
                        Text("Leading zeros:")
                        Stepper(value: $leadingZeros) {
                            TextField("Count", value: $leadingZeros, formatter: NumberFormatter())
                        }
                        
                    }
                    
                    HStack {
                        Text("Trailing text:")
                        TextField("Trailing text", text: $trailingText)
                            .disableAutocorrection(true)
                    }
                    
                    HStack {
                        Text("Fields divider:")
                        TextField("Fields divider text", text: $fieldsDivider)
                            .disableAutocorrection(true)
                    }
                }
            }
            
            /// New file name
            VStack {
                Image(systemName: "arrow.down")
                    .imageScale(.large)
                if appState.documentUrl == nil {
                    Text("No document selected")
                        .font(.caption)
                } else {
                    let filename = filename()
                    if filename.isEmpty {
                        Text("No filename rules")
                            .font(.caption)
                    } else {
                        Text(filename)
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Rename", action: rename)
                    .disabled(appState.documentUrl == nil)
                    .alert(isPresented: $errorOccurred) {
                        Alert(title: Text("Rename Error"), message: Text(errorMessage), dismissButton: .default(Text("Ok")))
                    }
            }
        }
        .padding()
    }
	
    func filename() -> String {
        var result = String()
		
        if let documentUrl = appState.documentUrl {
			if !leadingText.isEmpty {
                result.append(leadingText)
			}
			
			if shouldAppendDate {
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = dateFormat.rawValue
                if !result.isEmpty {
                    result.append(fieldsDivider)
                }
                result.append(dateFormatter.string(from: nameDate))
			}
			
			if shouldAppendCounter {
				let formatter = NumberFormatter()
				formatter.minimumIntegerDigits = leadingZeros
                if !result.isEmpty {
                    result.append(fieldsDivider)
                }
                result.append(formatter.string(for: nameCounter) ?? String(nameCounter))
			}
			
            if !trailingText.isEmpty {
                if !result.isEmpty {
                    result.append(fieldsDivider)
                }
                result.append(trailingText)
            }
			
            if !result.isEmpty {
                let ext = documentUrl.pathExtension
                if !ext.isEmpty {
                    result.append(".")
                    result.append(ext)
                }
            }
		}
        
        return result
	}
	
	func rename() {
		if let documentUrl = appState.documentUrl {
            let filename = filename()
			if !filename.isEmpty {
				var destinationUrl = documentUrl
				destinationUrl.deleteLastPathComponent()
				destinationUrl.appendPathComponent(filename)
				do {
					try FileManager.default.moveItem(at: documentUrl, to: destinationUrl)
                    appState.documentUrl = destinationUrl
					if shouldAppendCounter {
						nameCounter += 1
					}
				} catch {
					print(error)
					errorMessage = error.localizedDescription
					errorOccurred = true
				}
			}
		}
	}
}

struct PDFKitView: NSViewRepresentable {
	let url: URL
	
	func makeNSView(context: Context) -> PDFView {
		let pdfView = PDFView()
		
		pdfView.document = PDFDocument(url: self.url)
		pdfView.autoScales = true
		
		return pdfView
	}
	
	func updateNSView(_ pdfView: PDFView, context: Context) {
		pdfView.document = PDFDocument(url: self.url)
		pdfView.autoScales = true
	}
}

#Preview {
    ContentView().environmentObject(AppState())
}
