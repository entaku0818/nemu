//
//  BreathingGuideView.swift
//  nemu
//
// 4-7-8呼吸法ガイド。吸う4秒 → 止める7秒 → 吐く8秒のサイクルをアニメーションで誘導。
//

import SwiftUI
import Combine

struct BreathingGuideView: View {
    @State private var phase: BreathPhase = .inhale
    @State private var countdown: Int = 4
    @State private var scale: CGFloat = 0.6
    @State private var isRunning = false
    @State private var cycleCount = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum BreathPhase {
        case inhale, hold, exhale

        var label: String {
            switch self {
            case .inhale: return "吸って"
            case .hold:   return "止めて"
            case .exhale: return "吐いて"
            }
        }

        var duration: Int {
            switch self {
            case .inhale: return 4
            case .hold:   return 7
            case .exhale: return 8
            }
        }

        var color: Color {
            switch self {
            case .inhale: return .indigo
            case .hold:   return .purple
            case .exhale: return .teal
            }
        }

        var targetScale: CGFloat {
            switch self {
            case .inhale: return 1.0
            case .hold:   return 1.0
            case .exhale: return 0.6
            }
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("4-7-8 呼吸法")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .tracking(2)

            ZStack {
                // 外側の輪（エフェクト）
                Circle()
                    .fill(phase.color.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .scaleEffect(scale * 1.2)
                    .animation(.easeInOut(duration: Double(phase.duration)), value: scale)

                // メインの円
                Circle()
                    .fill(phase.color.opacity(0.2))
                    .overlay(Circle().strokeBorder(phase.color.opacity(0.5), lineWidth: 2))
                    .frame(width: 160, height: 160)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: Double(phase.duration)), value: scale)

                VStack(spacing: 6) {
                    Text(phase.label)
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text("\(countdown)")
                        .font(.system(size: 36, weight: .light, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }

            if cycleCount > 0 {
                Text("\(cycleCount)サイクル完了")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
            }

            Button {
                isRunning.toggle()
                if isRunning {
                    startCycle()
                }
            } label: {
                Text(isRunning ? "停止" : (cycleCount == 0 ? "開始" : "再開"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        Capsule().fill(isRunning ? Color.white.opacity(0.12) : Color.indigo)
                    )
            }
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            tick()
        }
    }

    private func startCycle() {
        phase = .inhale
        countdown = phase.duration
        withAnimation { scale = phase.targetScale }
    }

    private func tick() {
        countdown -= 1
        if countdown <= 0 {
            advancePhase()
        }
    }

    private func advancePhase() {
        switch phase {
        case .inhale:
            phase = .hold
        case .hold:
            phase = .exhale
        case .exhale:
            phase = .inhale
            cycleCount += 1
        }
        countdown = phase.duration
        withAnimation(.easeInOut(duration: Double(phase.duration))) {
            scale = phase.targetScale
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BreathingGuideView()
    }
}
