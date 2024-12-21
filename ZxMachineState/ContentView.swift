import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        VStack {
            Text("Mac状态监控")
                .font(.headline)
                .padding()

            // 下拉列表（Picker）选择串口设备
            Picker("设备", selection: $viewModel.selectedPort) {
                ForEach(viewModel.availablePorts, id: \.path) { port in
                    Text(port.name).tag(port as ContentViewModel.SerialPort?)
                }
            }
            .pickerStyle(MenuPickerStyle())  // 使用下拉菜单样式
            .frame(width: 150)
            .frame(height: 15)
            
            Button(action: {
                viewModel.InitTtyList()
            }) {
                Text("刷新设备")
                    .padding()
                    .frame(width: 135)
                    .frame(height: 15)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
            
            Button(action: {
                viewModel.setupSerialPort()
            }) {
                Text(viewModel.btnState)
                    .padding()
                    .frame(width: 135)
                    .frame(height: 15)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
            
            // 圆环进度条 CPU
            ProgressCircle_CPU(progress: $viewModel.progress_cpu)
                .frame(width: 100, height: 100)  // 控制圆环的大小
                .padding()
            // 圆环进度条 内存
            ProgressCircle_MEM(progress: $viewModel.progress_mem)
                .frame(width: 100, height: 100)  // 控制圆环的大小
                .padding()
            // 圆环进度条 硬盘
            ProgressCircle_DISK(progress: $viewModel.progress_disk)
                .frame(width: 100, height: 100)  // 控制圆环的大小
                .padding()

            // 退出按钮
            Button(action: {
                NSApplication.shared.terminate(self)  // 退出应用
            }) {
                Text("退出")
                    .padding()
                    .frame(width: 135)
                    .frame(height: 15)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }

            
            Spacer()
        }
        .frame(width: 200, height: 550)  // 设定 popover 的大小
        .padding()
        .onAppear {
            viewModel.InitTtyList()
            viewModel.startTimer()
        }
    }
}

struct ProgressCircle_CPU: View {
    @Binding var progress: CGFloat  // 绑定父视图的进度

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 10)
                .foregroundColor(Color.gray.opacity(0.2))

            Circle()
                .trim(from: 0.0, to: progress/100)
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: -90))  // 从顶部开始绘制

            Text(String(format: "CPU %.0f%%", progress))
                .font(.headline)
                .foregroundColor(.blue)
        }
    }
}

struct ProgressCircle_MEM: View {
    @Binding var progress: CGFloat  // 绑定父视图的进度

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 10)
                .foregroundColor(Color.gray.opacity(0.2))

            Circle()
                .trim(from: 0.0, to: progress/100)
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: -90))  // 从顶部开始绘制

            Text(String(format: "内存 %.0f%%", progress))
                .font(.headline)
                .foregroundColor(.blue)
        }
    }
}

struct ProgressCircle_DISK: View {
    @Binding var progress: CGFloat  // 绑定父视图的进度

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 10)
                .foregroundColor(Color.gray.opacity(0.2))

            Circle()
                .trim(from: 0.0, to: progress/100)
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: -90))  // 从顶部开始绘制

            Text(String(format: "硬盘 %.0f%%", progress))
                .font(.headline)
                .foregroundColor(.blue)
        }
    }
}
