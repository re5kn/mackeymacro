import MacroCore
import SwiftUI

struct MacroDetailView: View {
    @EnvironmentObject private var app: AppState
    @Binding var macro: Macro

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                TextField("名前", text: $macro.name)

                LabeledContent("ショートカット") {
                    VStack(alignment: .trailing, spacing: 4) {
                        HotKeyField(hotKey: $macro.hotKey)
                        if app.failedHotKeyMacroIDs.contains(macro.id) {
                            Text("このショートカットは他のアプリで使われているため登録できません")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                LabeledContent("再生速度") {
                    HStack {
                        Slider(value: $macro.speed, in: 0.25...4, step: 0.25)
                            .frame(maxWidth: 220)
                        Text(String(format: "%.2f×", macro.speed))
                            .monospacedDigit()
                            .frame(width: 52, alignment: .trailing)
                    }
                }

                Stepper(value: $macro.repeatCount, in: 1...999) {
                    LabeledContent("繰り返し回数", value: "\(macro.repeatCount) 回")
                }

                LabeledContent("再生時間") {
                    Text(String(format: "約 %.1f 秒 × %d 回", macro.duration, macro.repeatCount))
                }

                HStack {
                    Button {
                        app.play(macro.id)
                    } label: {
                        Label("再生", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(app.player.isPlaying || app.recorder.isRecording || macro.events.isEmpty)

                    Text("再生前に対象のアプリを前面にしてください(ショートカット推奨)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("削除", role: .destructive) {
                        app.delete(macro.id)
                    }
                }
            }
            .formStyle(.grouped)
            .frame(maxHeight: 330)

            Text("記録したイベント")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 4)

            List {
                ForEach(macro.events) { event in
                    HStack {
                        Text(KeyNames.describe(event))
                            .font(.body.monospaced())
                        Spacer()
                        Text(String(format: "+%.3f 秒", event.delay))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .contextMenu {
                        Button("このイベントを削除", role: .destructive) {
                            macro.events.removeAll { $0.id == event.id }
                        }
                    }
                }
                .onDelete { macro.events.remove(atOffsets: $0) }
            }
        }
    }
}
