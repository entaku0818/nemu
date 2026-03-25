//
//  HomeView.swift
//  nemu
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()

    private let dayLabels = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // 月アイコン + アプリ名
                VStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.indigo.gradient)

                    Text("ねむ")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                // 起床時刻設定
                VStack(spacing: 16) {
                    Text("起床時刻")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(2)

                    DatePicker("", selection: $viewModel.wakeTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .onChange(of: viewModel.wakeTime) {
                            viewModel.saveAlarmSetting()
                        }

                    // 繰り返し曜日
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { day in
                            Button {
                                viewModel.toggleRepeatDay(day)
                            } label: {
                                Text(dayLabels[day])
                                    .font(.caption.bold())
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(viewModel.repeatDays.contains(day)
                                                  ? Color.indigo
                                                  : Color.white.opacity(0.1))
                                    )
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.07))
                )
                .padding(.horizontal)

                // アラームON/OFF
                VStack(spacing: 8) {
                    Toggle(isOn: $viewModel.isAlarmEnabled) {
                        Text("アラーム")
                            .foregroundStyle(.white)
                    }
                    .tint(.indigo)
                    .padding(.horizontal, 24)
                    .onChange(of: viewModel.isAlarmEnabled) {
                        viewModel.saveAlarmSetting()
                    }

                    Text(viewModel.nextAlarmDescription)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                // 就寝ボタン
                Button {
                    viewModel.startBedtime()
                } label: {
                    Label("就寝する", systemImage: "bed.double.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.indigo.gradient)
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            viewModel.setup(modelContext: modelContext)
        }
        .fullScreenCover(isPresented: $viewModel.isBedtimeMode) {
            BedtimeView(alarmTime: viewModel.wakeTime)
        }
        .alert("保存エラー", isPresented: Binding(
            get: { viewModel.dbError != nil },
            set: { if !$0 { viewModel.dbError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.dbError ?? "")
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: AlarmSetting.self, inMemory: true)
}
