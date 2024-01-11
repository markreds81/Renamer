//
//  ContentView.swift
//  Renamer
//
//  Created by Marco on 10/01/24.
//

import SwiftUI
import PDFKit

struct ContentView: View {
    @StateObject
	private var world = World()
	
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
	private var dateFormat = DateFormat.YYYYMMDD
	
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
	
	@State
	private var filename = String()
	
	enum DateFormat: String, CaseIterable, Identifiable {
		case YYYYMMDD
		case YYYYMM
		case YYYY
		
		var id: String { self.rawValue }
	}
	
    var body: some View {
        VStack {
            /// File drop and preview area
            VStack {
                if let documentUrl = world.documentUrl {
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
                                self.world.documentUrl = url
                            }
                        }
                    }
                    return true
                }
                return false
            }
            
            /// Rename options
            GroupBox(label: Text("Rename options")) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Leading text:")
                        TextField("Leading text", text: $leadingText)
                            .disableAutocorrection(true)
                            .onChange(of: leadingText) {
                                updateFilename()
                            }
                    }
                    
                    HStack {
                        Toggle(isOn: $shouldAppendDate) {
                            Text("Append date:")
                        }
                        .toggleStyle(.checkbox)
                        .onChange(of: shouldAppendDate) {
                            updateFilename()
                        }
                        
                        DatePicker("", selection: $nameDate, displayedComponents: [.date])
                            .onChange(of: nameDate) {
                                updateFilename()
                            }
                        
                        Picker("Format:", selection: $dateFormat) {
                            ForEach(DateFormat.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .onChange(of: dateFormat) {
                            updateFilename()
                        }
                    }
                    
                    HStack {
                        Toggle(isOn: $shouldAppendCounter) {
                            Text("Append counter:")
                        }
                        .toggleStyle(.checkbox)
                        .onChange(of: shouldAppendCounter) {
                            updateFilename()
                        }
                        Stepper(value: $nameCounter) {
                            TextField("Start from", value: $nameCounter, formatter: NumberFormatter())
                                .onChange(of: nameCounter) {
                                    updateFilename()
                                }
                        }
                        Text("Leading zeros:")
                        Stepper(value: $leadingZeros) {
                            TextField("Count", value: $leadingZeros, formatter: NumberFormatter())
                                .onChange(of: leadingZeros) {
                                    updateFilename()
                                }
                        }
                        
                    }
                    
                    HStack {
                        Text("Trailing text:")
                        TextField("Trailing text", text: $trailingText)
                            .disableAutocorrection(true)
                            .onChange(of: trailingText) {
                                updateFilename()
                            }
                    }
                    
                    HStack {
                        Text("Fields divider:")
                        TextField("Fields divider text", text: $fieldsDivider)
                            .disableAutocorrection(true)
                            .onChange(of: fieldsDivider) {
                                updateFilename()
                            }
                    }
                }
            }
            
            /// New file name
            VStack {
                Image(systemName: "arrow.down")
                    .imageScale(.large)
                if world.documentUrl == nil {
                    Text("No document selected")
                        .font(.caption)
                } else {
                    Text(filename)
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Rename", action: rename)
                    .disabled(world.documentUrl == nil)
                    .alert(isPresented: $errorOccurred) {
                        Alert(title: Text("Rename Error"), message: Text(errorMessage), dismissButton: .default(Text("Ok")))
                    }
            }
        }
        .padding()
        .focusable()
        .focusEffectDisabled()
        .focusedValue(\.world, world)
        .onChange(of: world.documentUrl) {
            updateFilename()
        }        
    }
	
	func updateFilename() {
		if let documentUrl = world.documentUrl {
			var filename = String()
			
			if !leadingText.isEmpty {
				filename.append(leadingText)
				filename.append(fieldsDivider)
			}
			
			if shouldAppendDate {
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = dateFormat.rawValue
				filename.append(dateFormatter.string(from: nameDate))
				filename.append(fieldsDivider)
			}
			
			if shouldAppendCounter {
				let formatter = NumberFormatter()
				formatter.minimumIntegerDigits = leadingZeros
				filename.append(formatter.string(for: nameCounter) ?? String(nameCounter))
				filename.append(fieldsDivider)
			}
			
			filename.append(trailingText)
			
			let ext = documentUrl.pathExtension
			if !ext.isEmpty {
				filename.append(".")
				filename.append(ext)
			}
			
			self.filename = filename
		}
	}
	
	func rename() {
		if let documentUrl = world.documentUrl {
			if !filename.isEmpty {
				var destinationUrl = documentUrl
				destinationUrl.deleteLastPathComponent()
				destinationUrl.appendPathComponent(filename)
				do {
					try FileManager.default.moveItem(at: documentUrl, to: destinationUrl)
					world.documentUrl = destinationUrl
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
    ContentView()
}
