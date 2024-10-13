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
	
	@State
	private var namePeriod = Period.firstQuarter
	
	@State
	private var periodYear = Int(2024)
	
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
	
	@AppStorage("shouldAppendPeriod")
	private var shouldAppendPeriod = false
	
	@AppStorage("shouldAppendCounter")
	private var shouldAppendCounter = false
	
	@AppStorage("shouldPutDivider")
	private var shouldPutDivider = false
	
	@AppStorage("shouldAppendCreationDate")
	private var shouldAppendCreationDate = false
	
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
	
	enum Period: String, CaseIterable, Identifiable {
		case firstQuarter
		case secondQuarter
		case thirdQuarter
		case fourthQuarter
		
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
							.font(.headline)
                    } else {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: documentUrl.path(percentEncoded: false)))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64.0, height: 64.0)
                        Text(documentUrl.lastPathComponent)
							.font(.headline)
					}
					if let creationDate = documentUrl.creationDate {
						Text("Created on " + creationDate.formatted(date: .abbreviated, time: .omitted))
							.font(.subheadline)
					}
                } else {
                    //Image(systemName: "doc.fill")
					Image(nsImage: NSImage(named: "HomeIcon")!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64.0, height: 64.0)
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
						
						Toggle(isOn: $shouldAppendCreationDate) {
							Text("Creation date")
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
						Toggle(isOn: $shouldAppendPeriod) {
							Text("Append date as:")
						}
						.toggleStyle(.checkbox)
						
						Stepper(value: $periodYear) {
							TextField("Year", value: $periodYear, formatter: NumberFormatter())
						}
						
						Picker("Period:", selection: $namePeriod) {
							Text("1st Quarter").tag(Period.firstQuarter)
							Text("2nd Quarter").tag(Period.secondQuarter)
							Text("3rd Quarter").tag(Period.thirdQuarter)
							Text("4th Quarter").tag(Period.fourthQuarter)
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
		.onReceive(NotificationCenter.default.publisher(for: .performRenameNotification)) { object in
			rename()
		}
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
				if shouldAppendCreationDate, let creationDate = documentUrl.creationDate {
					result.append(dateFormatter.string(from: creationDate))
				} else {
					result.append(dateFormatter.string(from: nameDate))
				}
			}
			
			if shouldAppendPeriod {
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = DateFormat.yyyyMMdd.rawValue
				var components = DateComponents()
				components.year = periodYear
				switch namePeriod {
				case .firstQuarter:
					components.month = 3
					components.day = 31
				case .secondQuarter:
					components.month = 6
					components.day = 30
				case .thirdQuarter:
					components.month = 9
					components.day = 30
				case .fourthQuarter:
					components.month = 12
					components.day = 31
				}
				let calendar = Calendar.current
				if let date = calendar.date(from: components) {
					if !result.isEmpty {
						result.append(fieldsDivider)
					}
					result.append(dateFormatter.string(from: date))
				}
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
