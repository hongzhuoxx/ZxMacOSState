import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        VStack {
            Text("Serial Communication")
                .font(.headline)
                .padding()

            Text("Received Data:")
                .font(.subheadline)
                .padding(.top)

            ScrollView {
                Text(viewModel.receivedData)
                    .font(.body)
                    .padding()
            }

            Spacer()
            
            

            // 输入框和发送按钮
            TextField("Enter data to send", text: $viewModel.sendData)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                //viewModel.updateAndSendSystemInfo()
                viewModel.startTimer()
            }) {
                Text("Send Data")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .frame(width: 300, height: 400)  // 设定 popover 的大小
        .padding()
        .onAppear {
            viewModel.setupSerialPort()
        }
    }
}
