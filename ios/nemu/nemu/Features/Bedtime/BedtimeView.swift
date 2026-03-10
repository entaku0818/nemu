//
//  BedtimeView.swift
//  nemu
//

import SwiftUI
import SwiftData

struct BedtimeView: View {
    @State private var viewModel = BedtimeViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isDimmed = false
    @State private var showMemo = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {

                // ヘッダー
                HStack {
                    Spacer()
                    Text("就寝モード")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Button {
                        showMemo.toggle()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                Spacer()

                // 月アイコン
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.indigo.opacity(0.6))

                Text("おやすみなさい")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                // 自然音セレクター
                VStack(spacing: 12) {
                    Text("自然音")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(2)

                    HStack(spacing: 12) {
                        ForEach(BedtimeViewModel.SoundType.allCases) { sound in
                            Button {
                                viewModel.selectSound(sound)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: sound.systemImage)
                                        .font(.title3)
                                    Text(sound.rawValue)
                                        .font(.caption2)
                                }
                                .frame(width: 64, height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.selectedSound == sound
                                              ? Color.indigo
                                              : Color.white.opacity(0.08))
                                )
                                .foregroundStyle(.white)
                            }
                        }
                    }
                }

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        viewModel.finish()
                        dismiss()
                    } label: {
                        Label("起きた！", systemImage: "sun.max.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.indigo.gradient)
                            )
                    }

                    Button {
                        isDimmed.toggle()
                        if isDimmed {
                            viewModel.dimScreen()
                        } else {
                            viewModel.restoreScreen()
                        }
                    } label: {
                        Label(isDimmed ? "画面を戻す" : "画面を暗くする",
                              systemImage: isDimmed ? "sun.max.fill" : "moon.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showMemo) {
            MemoView(memo: $viewModel.memo)
        }
        .interactiveDismissDisabled(true)
        .onAppear {
            viewModel.startSession(modelContext: modelContext)
        }
        .onDisappear {
            viewModel.finish()
        }
    }
}

// MARK: - メモシート

struct MemoView: View {
    @Binding var memo: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.12).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("今日のメモ")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button("完了") { dismiss() }
                        .foregroundStyle(.indigo)
                }
                .padding()

                Text("ストレス・感謝・気になること、なんでも")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal)

                TextEditor(text: $memo)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                    .frame(maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    BedtimeView()
}
