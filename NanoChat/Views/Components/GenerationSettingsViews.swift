import SwiftUI

struct ImageGenerationSettingsView: View {
    let model: UserModel
    @Binding var params: [String: AnyCodable]
    @Environment(\.dismiss) private var dismiss
    
    // Initialize default params when view appears or model changes
    private func initializeDefaults() {
        var newParams = params
        
        // Add default resolution if available
        if let resolutions = model.resolutions, !resolutions.isEmpty {
            if newParams["resolution"] == nil {
                let defaultRes = model.defaultSettings?.resolution ?? resolutions[0].value
                newParams["resolution"] = AnyCodable(defaultRes)
            }
        }
        
        // Add default nImages if maxImages is available
        if let maxImages = model.maxImages, maxImages > 0 {
            if newParams["nImages"] == nil {
                let defaultN = model.defaultSettings?.nImages ?? 1
                newParams["nImages"] = AnyCodable(defaultN)
            }
        }
        
        // Gather defaults from additionalParams
        if let additionalParams = model.additionalParams {
            for (key, param) in additionalParams {
                if newParams[key] == nil, let def = param.default {
                    newParams[key] = def
                }
            }
        }
        
        // Only update if changes were made
        if newParams != params {
            params = newParams
        }
    }
    
    var body: some View {
        GlassSheet(title: "Image Settings") {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    
                    // Resolution Selector
                    if let resolutions = model.resolutions, !resolutions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Resolution")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Menu {
                                ForEach(resolutions, id: \.value) { res in
                                    Button(action: {
                                        params["resolution"] = AnyCodable(res.value)
                                    }) {
                                        HStack {
                                            if let comment = res.comment, !comment.isEmpty {
                                                Text("\(res.value) (\(comment))")
                                            } else {
                                                Text(res.value)
                                            }
                                            
                                            if let r = params["resolution"]?.stringValue, r == res.value {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(params["resolution"]?.stringValue ?? "Select Resolution")
                                        .font(Theme.Typography.body)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                                .padding()
                                .background(Theme.Colors.cardBackground)
                                .cornerRadius(Theme.Radius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    // Number of Images
                    if let maxImages = model.maxImages, maxImages > 1 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Number of Images")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                Spacer()
                                Text("\(params["nImages"]?.intValue ?? 1)")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { Double(params["nImages"]?.intValue ?? 1) },
                                    set: { params["nImages"] = AnyCodable(Int($0)) }
                                ),
                                in: 1...Double(maxImages),
                                step: 1
                            )
                            .tint(Theme.Colors.primary)
                        }
                    }
                    
                    // Dynamic Additional Params
                    if let additionalParams = model.additionalParams {
                        ForEach(Array(additionalParams.keys.sorted()), id: \.self) { key in
                            if let param = additionalParams[key] {
                                DynamicParamView(key: key, param: param, params: $params)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            initializeDefaults()
        }
    }
}

struct VideoGenerationSettingsView: View {
    let model: UserModel
    @Binding var params: [String: AnyCodable]
    @Environment(\.dismiss) private var dismiss
    
    private func initializeDefaults() {
        var newParams = params
         // Gather defaults from additionalParams
        if let additionalParams = model.additionalParams {
            for (key, param) in additionalParams {
                if newParams[key] == nil, let def = param.default {
                    newParams[key] = def
                }
            }
        }
        
        if newParams != params {
            params = newParams
        }
    }

    var body: some View {
        GlassSheet(title: "Video Settings") {
             ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    if let additionalParams = model.additionalParams {
                        ForEach(Array(additionalParams.keys.sorted()), id: \.self) { key in
                            if let param = additionalParams[key] {
                                DynamicParamView(key: key, param: param, params: $params)
                            }
                        }
                    } else {
                        Text("No configurable settings for this model.")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            initializeDefaults()
        }
    }
}

// Helper view for dynamic params
struct DynamicParamView: View {
    let key: String
    let param: ModelParamDefinition
    @Binding var params: [String: AnyCodable]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // Label and Description
            VStack(alignment: .leading, spacing: 2) {
                Text(param.label ?? key)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                if let description = param.description {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
            
            // Input Control based on type
            switch param.type ?? "text" {
            case "boolean", "switch":
                Toggle(isOn: Binding(
                    get: { params[key]?.boolValue ?? false },
                    set: { params[key] = AnyCodable($0) }
                )) {
                    EmptyView()
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
                
            case "select":
                if let options = param.options {
                    Menu {
                        ForEach(options, id: \.value) { option in
                            Button(action: {
                                params[key] = option.value
                            }) {
                                HStack {
                                    Text(option.label ?? "\(option.value)")
                                    if params[key] == option.value {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(getDisplayLabel(key: key, options: options))
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .padding()
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(Theme.Radius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.md)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                    }
                }
                
            case "number":
                if let min = param.min, let max = param.max {
                    HStack {
                        Text("\(params[key]?.intValue ?? Int(params[key]?.doubleValue ?? 0))")
                             .font(Theme.Typography.caption)
                             .foregroundColor(Theme.Colors.textPrimary)
                    }
                    Slider(
                         value: Binding(
                            get: { 
                                if let d = params[key]?.doubleValue { return d }
                                if let i = params[key]?.intValue { return Double(i) }
                                return 0.0
                            },
                            set: { val in
                                if param.step == 1.0 || param.step == nil {
                                    params[key] = AnyCodable(Int(val))
                                } else {
                                    params[key] = AnyCodable(val)
                                }
                             }
                        ),
                        in: min...max,
                        step: param.step ?? 1.0
                    )
                     .tint(Theme.Colors.primary)
                } else {
                     TextField("", value: Binding(
                        get: { params[key]?.doubleValue ?? Double(params[key]?.intValue ?? 0) },
                        set: { params[key] = AnyCodable($0) }
                     ), format: .number)
                     .textFieldStyle(RoundedBorderTextFieldStyle())
                     .keyboardType(.decimalPad)
                }
                
            default:
                 // Text input fallback
                 TextField("", text: Binding(
                    get: { params[key]?.stringValue ?? "" },
                    set: { params[key] = AnyCodable($0) }
                 ))
                 .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    private func getDisplayLabel(key: String, options: [ModelParamOption]) -> String {
        guard let current = params[key] else { return "Select..." }
        
        for option in options {
             if current == option.value { return option.label ?? "\(current.value)" }
        }
        return "\(current.value)"
    }
}
